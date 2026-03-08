import '../../l10n/app_localizations.dart';

enum JobSite {
  jobkorea,
  saramin,
  incruit,
  albamon,
  albaheaven,
  wanted,
  linkedin,
  indeed,
  glassdoor,
  monster,
  careerbuilder,
  // 일본어 사이트
  indeedJp,
  rikunabi,
  mynavi,
  wantedly,
  doda,
  enJapan,
  // 중국어 사이트
  job51,
  zhaopin,
  bossZhipin,
  liepin,
  lagou,
  // 인도어 사이트
  naukri,
  indeedIndia,
  foundit,
  shine,
  freshersworld,
  unknown,
}

extension JobSiteLabels on JobSite {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case JobSite.jobkorea:
        return l10n.siteJobKorea;
      case JobSite.saramin:
        return l10n.siteSaramin;
      case JobSite.incruit:
        return l10n.siteIncruit;
      case JobSite.albamon:
        return l10n.siteAlbamon;
      case JobSite.albaheaven:
        return '알바천국'; // TODO: l10n 추가 필요시
      case JobSite.wanted:
        return '원티드'; // TODO: l10n 추가 필요시
      case JobSite.linkedin:
        return l10n.siteLinkedIn;
      case JobSite.indeed:
        return 'Indeed';
      case JobSite.glassdoor:
        return 'Glassdoor';
      case JobSite.monster:
        return 'Monster';
      case JobSite.careerbuilder:
        return 'CareerBuilder';
      // 일본어 사이트
      case JobSite.indeedJp:
        return 'Indeed Japan';
      case JobSite.rikunabi:
        return 'リクナビ';
      case JobSite.mynavi:
        return 'マイナビ';
      case JobSite.wantedly:
        return 'Wantedly';
      case JobSite.doda:
        return 'DODA';
      case JobSite.enJapan:
        return 'en Japan';
      // 중국어 사이트
      case JobSite.job51:
        return '前程无忧';
      case JobSite.zhaopin:
        return '智联招聘';
      case JobSite.bossZhipin:
        return 'BOSS直聘';
      case JobSite.liepin:
        return '猎聘';
      case JobSite.lagou:
        return '拉勾';
      // 인도어 사이트
      case JobSite.naukri:
        return 'Naukri';
      case JobSite.indeedIndia:
        return 'Indeed India';
      case JobSite.foundit:
        return 'Foundit';
      case JobSite.shine:
        return 'Shine';
      case JobSite.freshersworld:
        return 'FreshersWorld';
      case JobSite.unknown:
        return l10n.siteUnknown;
    }
  }

  String get label {
    switch (this) {
      case JobSite.jobkorea:
        return '잡코리아';
      case JobSite.saramin:
        return '사람인';
      case JobSite.incruit:
        return '인쿠르트';
      case JobSite.albamon:
        return '알바몬';
      case JobSite.albaheaven:
        return '알바천국';
      case JobSite.wanted:
        return '원티드';
      case JobSite.linkedin:
        return '링크드인';
      case JobSite.indeed:
        return 'Indeed';
      case JobSite.glassdoor:
        return 'Glassdoor';
      case JobSite.monster:
        return 'Monster';
      case JobSite.careerbuilder:
        return 'CareerBuilder';
      // 일본어 사이트
      case JobSite.indeedJp:
        return 'Indeed 일본';
      case JobSite.rikunabi:
        return '리쿠나비';
      case JobSite.mynavi:
        return '마이나비';
      case JobSite.wantedly:
        return '원티드리';
      case JobSite.doda:
        return '도다';
      case JobSite.enJapan:
        return 'en 재팬';
      // 중국어 사이트
      case JobSite.job51:
        return '51잡';
      case JobSite.zhaopin:
        return '즈하오핀';
      case JobSite.bossZhipin:
        return 'BOSS즈핀';
      case JobSite.liepin:
        return '라이핀';
      case JobSite.lagou:
        return '라구';
      // 인도어 사이트
      case JobSite.naukri:
        return '나우크리';
      case JobSite.indeedIndia:
        return 'Indeed 인도';
      case JobSite.foundit:
        return '파운딧';
      case JobSite.shine:
        return '샤인';
      case JobSite.freshersworld:
        return '프레셔스월드';
      case JobSite.unknown:
        return '기타';
    }
  }
}

