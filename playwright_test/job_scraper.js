const { chromium } = require('playwright-extra');
const stealth = require('puppeteer-extra-plugin-stealth')();
const fs = require('fs');
const path = require('path');

chromium.use(stealth);

const AUTH_FILE = path.join(__dirname, 'auth.json');

async function scrapeJob(url) {
  const browser = await chromium.launch({ headless: true }); // Set to false to see the browser for login
  
  let context;
  if (fs.existsSync(AUTH_FILE)) {
    console.log('Loading existing session from auth.json...');
    const storageState = JSON.parse(fs.readFileSync(AUTH_FILE, 'utf8'));
    context = await browser.newContext({ storageState });
  } else {
    console.log('No auth.json found. Creating new context.');
    context = await browser.newContext();
  }

  const page = await context.newPage();

  try {
    // 1. Always go to login URL first as per user rules
    const loginUrl = url.includes('indeed.com') 
      ? 'https://kr.indeed.com/account/login' 
      : 'https://www.linkedin.com/login';
    
    console.log(`Navigating to login URL: ${loginUrl}`);
    try {
      await page.goto(loginUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    } catch (e) {
      console.log('Login page navigation timed out or failed. Attempting to proceed to job URL anyway.');
    }

    // 2. Check if logged in
    const isLoggedIn = await page.evaluate(() => {
      // Very simple check: if we see 'Sign in' or 'Login' buttons/text, we're likely not logged in
      const text = document.body.innerText.toLowerCase();
      if (location.href.includes('indeed.com')) {
        return !text.includes('sign in') && !text.includes('로그인');
      } else if (location.href.includes('linkedin.com')) {
        return !text.includes('sign in') && !text.includes('로그인');
      }
      return true;
    });

    if (!isLoggedIn) {
      console.log('Not logged in. (In a real scenario, you would perform login here or wait for manual login)');
      // If we had credentials, we'd use them here. 
      // For now, we'll try to save the session if the user was somehow auto-logged in or if we're debugging.
    } else {
      console.log('Already logged in or login successful.');
      // 3. Save session
      const storage = await context.storageState();
      fs.writeFileSync(AUTH_FILE, JSON.stringify(storage, null, 2));
      console.log('Session saved to auth.json');
    }

    // 4. Navigate to the actual job URL
    console.log(`Navigating to job URL: ${url}`);
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    // Wait for the specific job title selector to ensure the page is loaded
    try {
      await page.waitForSelector('.jobsearch-JobInfoHeader-title, [data-testid="jobsearch-JobInfoHeader-title"]', { timeout: 10000 });
    } catch (e) {
      console.log('Job title selector not found. Might be blocked or different layout.');
    }

    // 5. Check if blocked
    const isBlocked = await page.evaluate(() => {
      const text = document.body.innerText.toLowerCase();
      return text.includes('just a moment') || text.includes('verify you are human') || text.includes('cloudflare');
    });

    if (isBlocked) {
      console.log('Still blocked even with Stealth! Deleting auth.json and retrying might help.');
      if (fs.existsSync(AUTH_FILE)) fs.unlinkSync(AUTH_FILE);
      throw new Error('Blocked by Cloudflare');
    }

    // 6. Extract data (Indeed Example)
    const jobData = await page.evaluate(() => {
      const title = document.querySelector('.jobsearch-JobInfoHeader-title')?.innerText || document.title;
      const company = document.querySelector('[data-testid="inlineHeader-companyName"]')?.innerText || 
                      document.querySelector('.jobsearch-InlineCompanyRating')?.innerText || '';
      const salary = document.querySelector('#salaryInfoAndJobType')?.innerText || '';
      
      return { title, company, salary };
    });

    console.log('Scraped Data:', JSON.stringify(jobData, null, 2));
    return jobData;

  } catch (error) {
    console.error('Error during scraping:', error.message);
    if (error.message.includes('Blocked')) {
      // If blocked, delete auth.json for next retry
      if (fs.existsSync(AUTH_FILE)) fs.unlinkSync(AUTH_FILE);
    }
    throw error;
  } finally {
    await browser.close();
  }
}

// Example usage
const targetUrl = process.argv[2] || 'https://kr.indeed.com/viewjob?jk=9881c05ba0d0d75e';
scrapeJob(targetUrl);
