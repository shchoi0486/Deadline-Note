import express from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import { chromium } from 'playwright-extra';
import stealth from 'puppeteer-extra-plugin-stealth';

chromium.use(stealth());

const app = express();
app.use(cors());

const PORT = 3400;
const DATA_DIR = path.resolve(process.cwd(), 'tools', 'scraper', 'data');
const AUTH_FILE = path.join(DATA_DIR, 'auth.json');
fs.mkdirSync(DATA_DIR, { recursive: true });

async function createContext() {
  const userDataDir = path.join(DATA_DIR, 'userData');
  const context = await chromium.launchPersistentContext(userDataDir, {
    headless: true,
    viewport: { width: 1280, height: 800 },
    bypassCSP: true,
  });
  const page = await context.newPage();
  try {
    if (fs.existsSync(AUTH_FILE)) {
      const cookies = JSON.parse(fs.readFileSync(AUTH_FILE, 'utf-8'));
      if (Array.isArray(cookies) && cookies.length > 0) {
        await context.addCookies(cookies);
      }
    }
  } catch (_) {}
  return { context, page };
}

async function saveSession(context) {
  try {
    const cookies = await context.cookies();
    fs.writeFileSync(AUTH_FILE, JSON.stringify(cookies, null, 2));
  } catch (_) {}
}

async function ensureLogin(page) {
  try {
    await page.goto('https://secure.indeed.com/account/login?hl=ko_KR&co=KR', { waitUntil: 'domcontentloaded', timeout: 60000 });
    const hasForm = await page.$('form[action*="/account/login"], input[type="password"]');
    const loggedIndicator = await page.$('a[href*="/account/logout"], [data-tn-component="profileIcon"]');
    if (loggedIndicator) return true;
    if (!hasForm) return true; // no login required
    // No credentials available: attempt continue to home
    const homeBtn = await page.$('a[href*="indeed.com"]');
    if (homeBtn) await homeBtn.click();
    return true;
  } catch (_) {
    // On failure, clear session and retry once
    try { fs.unlinkSync(AUTH_FILE); } catch (_) {}
    return false;
  }
}

async function extractJob(page, url) {
  const titleSelectors = [
    '[data-testid="jobsearch-JobInfoHeader-title"]',
    '.jobsearch-JobInfoHeader-title',
    'h1',
    '[role="heading"] h1'
  ];
  const companySelectors = [
    '[data-testid="jobsearch-JobInfoHeader-companyName"]',
    '.jobsearch-JobInfoHeader-companyName',
    '[data-testid="inlineHeader-companyName"]',
    '[data-testid="company-name"]',
    '.jobsearch-InlineCompanyRating',
    '.companyName'
  ];
  const getText = async (sel) => {
    const el = await page.$(sel);
    if (!el) return '';
    const text = (await el.textContent()) || '';
    return text.trim().replace(/\s+/g, ' ');
  };
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
      // Cloudflare gate wait
      await page.waitForTimeout(3000);
      const blocked = await page.evaluate(() => {
        const t = document.title.toLowerCase();
        const b = (document.body?.innerText || '').toLowerCase();
        return t.includes('just a moment') || t.includes('잠시만') || b.includes('additional verification') || b.includes('cloudflare');
      });
      if (blocked && attempt < 2) {
        // try spa=1
        const u = new URL(url);
        u.searchParams.set('spa', '1');
        url = u.toString();
        continue;
      }
      let jobTitle = '';
      for (const s of titleSelectors) { jobTitle = await getText(s); if (jobTitle) break; }
      let companyName = '';
      for (const s of companySelectors) { companyName = await getText(s); if (companyName) break; }
      if (!jobTitle || !companyName) {
        // Try JSON embedded in body if spa
        const pre = await page.$('pre');
        if (pre) {
          const txt = (await pre.textContent()) || '';
          try {
            const data = JSON.parse(txt);
            const job = data?.data?.jobData?.job || data?.job || data?.body?.hostQueryExecutionResult?.[0]?.data?.jobData?.job;
            jobTitle = jobTitle || (job?.title || '');
            companyName = companyName || (job?.sourceEmployerName || job?.company?.name || '');
          } catch (_) {}
        }
      }
      return { jobTitle, companyName };
    } catch (e) {
      await page.waitForTimeout(1000);
    }
  }
  return { jobTitle: '', companyName: '' };
}

app.get('/scrape', async (req, res) => {
  const url = req.query.url;
  if (!url || typeof url !== 'string') return res.status(400).json({ error: 'url required' });
  const { context, page } = await createContext();
  try {
    await ensureLogin(page);
    const result = await extractJob(page, url);
    await saveSession(context);
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  } finally {
    await context.close();
  }
});

app.listen(PORT, () => {
  console.log(`Scraper server listening on http://localhost:${PORT}`);
});
