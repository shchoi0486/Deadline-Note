// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Deadline Note';

  @override
  String get today => 'Today';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabList => 'Status';

  @override
  String get tabAdd => 'Add';

  @override
  String get tabNotes => 'Notes';

  @override
  String get tabSettings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get selectDate => 'Select Date';

  @override
  String get add => 'Add';

  @override
  String get passed => 'Passed';

  @override
  String get failed => 'Failed';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteContent => 'Are you sure you want to delete?';

  @override
  String get settingsDeadlineAlarm => 'Deadline Alarm';

  @override
  String get settingsD3Alarm => 'D-3 Alarm';

  @override
  String get settingsD1Alarm => 'D-1 Alarm';

  @override
  String get settings3hAlarm => '3h before Deadline';

  @override
  String get settingsHoliday => 'Language & Holiday';

  @override
  String get settingsLanguage => 'Language Settings';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get settingsHolidayCountry => 'Holiday Country';

  @override
  String get settingsHolidayDesc =>
      'Holidays are displayed on the calendar based on the selected country\'s public data.';

  @override
  String get settingsShareAdd => 'Add via Share';

  @override
  String get settingsShareAddDesc =>
      'Share from job sites → Select Deadline Note';

  @override
  String get holidayAuto => 'Auto (System)';

  @override
  String get adRemove => 'Remove Ads';

  @override
  String get companyRequired => 'Company (Required)';

  @override
  String get jobTitleOptional => 'Job Title (Optional)';

  @override
  String get fixedDeadline => 'Fixed Deadline';

  @override
  String get rollingDeadline => 'Rolling';

  @override
  String get estimatedDeadline => 'Estimated Deadline';

  @override
  String get deadlineRequired => 'Deadline (Required)';

  @override
  String get deadlineAt => 'Deadline';

  @override
  String get estimated => 'Est.';

  @override
  String get temporary => 'Temp';

  @override
  String get linkOptional => 'Job Link (Optional)';

  @override
  String get salaryOptional => 'Salary (Optional)';

  @override
  String get memoOptional => 'Memo (Optional)';

  @override
  String get notificationEnable => 'Receive deadline notifications';

  @override
  String get status => 'Status';

  @override
  String get nextStep => 'Add Next Step';

  @override
  String get nextStepDesc => 'Step';

  @override
  String get date => 'Date';

  @override
  String get companyNameRequiredMsg => 'Company name is required.';

  @override
  String get noNextStepMsg => 'There are no more steps.';

  @override
  String get saveComplete => 'Saved successfully';

  @override
  String get filterAll => 'All';

  @override
  String get filterDocument => 'Doc';

  @override
  String get filterAptitude => 'Apt.';

  @override
  String get filterInterview => 'Intv';

  @override
  String get filterFailed => 'Failed';

  @override
  String get noSchedules => 'No registered schedules.';

  @override
  String get noCompanyName => 'No company name';

  @override
  String get noTitle => 'No title';

  @override
  String get defaultScheduleTitle => 'Schedule';

  @override
  String get noFilteredSchedules => 'No schedules match the criteria.';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusPassed => 'Step Passed';

  @override
  String get openOriginalLink => 'Open Original Link';

  @override
  String get editGuide => 'Edit below and save.';

  @override
  String get copyComplete => 'Copied to clipboard';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get statusNotApplied => 'Before application';

  @override
  String get statusApplied => 'Applied';

  @override
  String get statusDocument => 'Document';

  @override
  String get statusVideoInterview => 'Aptitude test';

  @override
  String get statusInterview1 => '1st Interview';

  @override
  String get statusInterview2 => '2nd Interview';

  @override
  String get statusFinalInterview => 'Final Interview';

  @override
  String get statusOffer => 'Offer';

  @override
  String get statusHired => 'Hired';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get badgeDocument => 'Doc';

  @override
  String get badgeVideoInterview => 'Aptitude';

  @override
  String get badgeInterview1 => '1st';

  @override
  String get badgeInterview2 => '2nd';

  @override
  String get badgeFinalInterview => 'Final';

  @override
  String get badgeClosed => 'Closed';

  @override
  String get dDayToday => 'D-DAY';

  @override
  String get dDayClosed => 'Closed';

  @override
  String get outcomePassed => 'Success';

  @override
  String get outcomeFailed => 'Failed';

  @override
  String get addMethodLink => 'Add via URL link';

  @override
  String get addMethodLinkDesc => 'Share links from job sites';

  @override
  String get addMethodManual => 'Add Manually';

  @override
  String get addMethodManualDesc => 'Quickly enter for non-sharable jobs';

  @override
  String get noteAppliedRole => 'Applied Role';

  @override
  String get noteNoTitle => 'No Title';

  @override
  String get noteQuestionBank => 'Question Bank';

  @override
  String get noteNoQuestions => 'No questions registered.';

  @override
  String get noteRecentInterviews => 'Recent Interview History';

  @override
  String saveError(String error) {
    return 'Error occurred while saving: $error';
  }

  @override
  String get countryKorea => 'South Korea';

  @override
  String get countryUS => 'United States';

  @override
  String get countryJapan => 'Japan';

  @override
  String get countryChina => 'China';

  @override
  String get countryUK => 'United Kingdom';

  @override
  String get countryGermany => 'Germany';

  @override
  String get countryFrance => 'France';

  @override
  String get countryCanada => 'Canada';

  @override
  String get countryAustralia => 'Australia';

  @override
  String get noteTitle => 'Notes';

  @override
  String get noteTabCompany => 'Company';

  @override
  String get noteTabInterview => 'Review';

  @override
  String get noteEmptyCompany =>
      'No company notes yet.\nCreate your first one with the + button.';

  @override
  String get noteEmptyInterview =>
      'No interview reviews yet.\nLeave your first review with the + button.';

  @override
  String get noteDeleteCompanyTitle => 'Delete Company Note';

  @override
  String get noteDeleteInterviewTitle => 'Delete Interview Review';

  @override
  String get noteDeleteEpisodeTitle => 'Delete Episode';

  @override
  String get noteDeleteQuestionTitle => 'Delete Question';

  @override
  String noteDeleteConfirm(Object name, Object type) {
    return 'Are you sure you want to delete \'$name ($type)\'?\nThis action cannot be undone.';
  }

  @override
  String noteDeleteSessionConfirm(Object name, Object round) {
    return 'Are you sure you want to delete the interview review for \'$name ($round)\'?\nThis action cannot be undone.';
  }

  @override
  String get noteTypeNote => 'Note';

  @override
  String get noteTypeReview => 'Review';

  @override
  String get noteNoCompanyName => 'No Company Name';

  @override
  String get noteRole => 'Role';

  @override
  String get noteRoleLabel => 'Role';

  @override
  String get noteRoleHint => 'e.g. Backend Developer';

  @override
  String get noteKeywords => 'Keywords';

  @override
  String get noteKeywordsLabel => 'Keywords';

  @override
  String get noteKeywordsHint =>
      'e.g. Java, Spring, High Traffic (separated by comma)';

  @override
  String get notePitchLabel => '1-min Intro / Core Pitch';

  @override
  String get notePitchHint => 'Key message to impress the company';

  @override
  String get noteRisksLabel => 'Risks / Concerns';

  @override
  String get noteRisksHint =>
      'Weaknesses or points that could be attacked in an interview';

  @override
  String get noteInterviewDate => 'Interview Date';

  @override
  String get noteReviewState => 'Review State';

  @override
  String noteQuestionsCount(Object count) {
    return '$count questions';
  }

  @override
  String noteQuestionCount(Object count) {
    return '$count questions';
  }

  @override
  String get roundUnknown => 'Unknown';

  @override
  String get roundScreening => 'Screening';

  @override
  String get roundFirst => '1st Round';

  @override
  String get roundSecond => '2nd Round';

  @override
  String get roundFinal => 'Final Round';

  @override
  String get reviewNeedsReview => 'Needs Review';

  @override
  String get reviewMastered => 'Review Complete';

  @override
  String get deadlineFixed => 'Deadline';

  @override
  String get deadlineRolling => 'Rolling';

  @override
  String get deadlineExpired => 'Expired';

  @override
  String get deadlineUnknown => 'Unknown';

  @override
  String get pitfallMissingConcept => 'Missing Concept';

  @override
  String get pitfallVagueLogic => 'Vague Logic';

  @override
  String get pitfallLackOfExamples => 'Lack of Examples';

  @override
  String get pitfallNoMetrics => 'No Metrics';

  @override
  String get pitfallTooWordy => 'Too Wordy';

  @override
  String get pitfallUnclearPoint => 'Unclear Point';

  @override
  String get noteAddCompany => 'Add Company Note';

  @override
  String get noteEditCompany => 'Edit Company Note';

  @override
  String get noteCompanyName => 'Company Name';

  @override
  String get noteCompanyNameHint => 'e.g. Google Korea';

  @override
  String get noteAddInterview => 'Add Interview Review';

  @override
  String get noteEditInterview => 'Edit Interview Review';

  @override
  String get noteRoundLabel => 'Interview Round';

  @override
  String get noteDateLabel => 'Interview Date';

  @override
  String get noteHeldAt => 'Interview Date';

  @override
  String get noteAddQuestion => 'Add Question';

  @override
  String get noteEditQuestion => 'Edit Question';

  @override
  String get noteAddQuestionHint => 'Enter the question';

  @override
  String get noteQuestionHint => 'Enter the question';

  @override
  String get noteQuestionLabel => 'Question';

  @override
  String get noteAddEpisode => 'Add Episode';

  @override
  String get noteEditEpisode => 'Edit Episode';

  @override
  String get noteEpisode => 'Episode';

  @override
  String get noteEpisodeTitle => 'Title';

  @override
  String get noteEpisodeTitleHint =>
      'e.g. Improved efficiency by 20% through data analysis during internship';

  @override
  String get noteEpisodeMetrics => 'Key Metrics/Evidence (Optional)';

  @override
  String get noteEpisodeMetricsHint =>
      'e.g. 15% increase in sales, 30 min reduction in processing time';

  @override
  String get noteEpisodeSituation => 'Situation/Problem (S)';

  @override
  String get noteEpisodeSituationHint =>
      'What was the situation and what problem occurred?';

  @override
  String get noteEpisodeAction => 'Action/Solution (A)';

  @override
  String get noteEpisodeActionHint =>
      'What specific actions did you take to solve the problem?';

  @override
  String get noteEpisodeResult => 'Result (R)';

  @override
  String get noteEpisodeResultHint =>
      'What was the result and what did you learn?';

  @override
  String get noteEpisodeEvidence => 'Evidence Link (Optional)';

  @override
  String get noteEpisodeEvidenceHint => 'Links to portfolio, GitHub, etc.';

  @override
  String get noteInfoSearch => 'Explore Company Info';

  @override
  String get noteSummaryLabel => 'Company Analysis Summary';

  @override
  String get noteSummaryHint =>
      'Summarize the company\'s main business, recent issues, etc.';

  @override
  String get noteFitLabel => 'Motivation and Fit';

  @override
  String get noteFitHint =>
      'Write about why this company and how it connects to your experience.';

  @override
  String get noteAiMatching => 'AI Matching';

  @override
  String get noteAiMatchingRunning => 'AI is analyzing company information...';

  @override
  String get noteAiMatchingSuccess =>
      'Successfully retrieved company information.';

  @override
  String get noteAiMatchingFail => 'Failed to retrieve company information.';

  @override
  String get searchNaver => 'Naver';

  @override
  String get searchGoogle => 'Google';

  @override
  String get searchBlind => 'Blind';

  @override
  String get searchCatch => 'Catch';

  @override
  String get searchJobPlanet => 'JobPlanet';

  @override
  String get searchLinkedIn => 'LinkedIn';

  @override
  String get searchGlassdoor => 'Glassdoor';

  @override
  String get searchIndeed => 'Indeed';

  @override
  String get searchOpenWork => 'OpenWork';

  @override
  String get searchEnLighthouse => 'En Lighthouse';

  @override
  String get searchBaidu => 'Baidu';

  @override
  String get searchKanzhun => 'Kanzhun';

  @override
  String get searchMaimai => 'Maimai';

  @override
  String get searchAmbitionBox => 'AmbitionBox';

  @override
  String get searchYahoo => 'Yahoo';

  @override
  String get searchDART => 'DART';

  @override
  String get searchYouTube => 'YouTube';

  @override
  String get noteInfoSection => 'Company Analysis Info';

  @override
  String get noteEpisodes => 'Experience Episodes';

  @override
  String get noteNoEpisodes =>
      'No episodes registered yet.\nAdd an episode using the + button at the top right.';

  @override
  String get noteStorySection => 'Experience Episodes';

  @override
  String get noteEmptyStory =>
      'No episodes registered yet.\nAdd an episode using the + button at the top right.';

  @override
  String get noteEmptyQuestions =>
      'No questions yet.\nTry adding a question using the button at the top right.';

  @override
  String get noteQuestionRecord => 'Question Record';

  @override
  String noteNextAction(Object action) {
    return 'Next Action: $action';
  }

  @override
  String get noteQuestion => 'Question';

  @override
  String get noteIntent => 'Intent (Optional)';

  @override
  String get noteIntentHint => 'e.g. Checking loyalty and job understanding';

  @override
  String get noteAnswerAtTheTime => 'My Answer (At the time)';

  @override
  String get noteAnswerAtTheTimeHint =>
      'Record your answer during the interview as accurately as possible';

  @override
  String get noteImproved60 => 'Improved Answer (60s)';

  @override
  String get noteImproved60Hint =>
      'Concise and focused on core points (approx. 300 chars)';

  @override
  String get noteImproved120 => 'Improved Answer (120s)';

  @override
  String get noteImproved120Hint =>
      'Detailed with specific examples and metrics (approx. 600 chars)';

  @override
  String get noteNextActionLabel => 'Next Action (Optional)';

  @override
  String get noteNextActionHint =>
      'e.g. Organizing related project experiences, re-checking company values';

  @override
  String get notePitfalls => 'Check Points to Improve';

  @override
  String get noteReviewStatus => 'Review Status';

  @override
  String addNextStepError(String error) {
    return 'Error occurred while adding next step: $error';
  }

  @override
  String get originalLinkIncluded => 'Original link included';

  @override
  String jobInfo(String site) {
    return 'Job Info($site)';
  }

  @override
  String get checkRequired => 'Check required';

  @override
  String get siteJobKorea => 'JobKorea';

  @override
  String get siteSaramin => 'Saramin';

  @override
  String get siteIncruit => 'Incruit';

  @override
  String get siteAlbamon => 'Albamon';

  @override
  String get siteLinkedIn => 'LinkedIn';

  @override
  String get siteUnknown => 'Other';

  @override
  String get vaultTitle => 'File Vault';

  @override
  String get vaultFileTab => 'Files';

  @override
  String get vaultMemoTab => 'Memos';

  @override
  String get vaultAddFile => 'Add File';

  @override
  String get vaultAddMemo => 'Add Memo';

  @override
  String get vaultEditMemo => 'Edit Memo';

  @override
  String get vaultStorageWarning =>
      'Files/Memos are not sent to the server and are only stored on your phone.\nDeleting the app may result in data loss.';

  @override
  String get vaultNoFiles =>
      'No files saved.\nTry adding one with the + button at the top right.';

  @override
  String get vaultNoMemos =>
      'No memos saved.\nTry adding one with the + button at the top right.';

  @override
  String get vaultOpenFile => 'Open';

  @override
  String get vaultDefaultFileName => 'File';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get exitConfirmTitle => 'Do you want to exit?';

  @override
  String get exitConfirmAction => 'Exit';

  @override
  String get jobPostUrl => 'Job Post URL';

  @override
  String get parsingInProgress => 'Organizing job post info...';

  @override
  String get checkSharedPost => 'Please check the shared post';

  @override
  String get parseErrorMsg =>
      'Failed to analyze link. Please switch to manual entry.';

  @override
  String get parseWarningDeadline =>
      'Could not find the deadline automatically. Please select it manually.';

  @override
  String get parseWarningCompany =>
      'Could not find the company name automatically.';

  @override
  String get parseWarningTitle => 'Could not find the job title automatically.';

  @override
  String get shareInstruction =>
      'Click the [Register Schedule] button\non the job site to automatically extract info!';

  @override
  String get howToUse => 'How to use';

  @override
  String get recommendedJobSites => 'Recommended Job Sites';

  @override
  String get howToUseTitle => 'How to use';

  @override
  String get howToStep1Title => '1. Select Job Site';

  @override
  String get howToStep1Desc => 'Select a job site you want to visit.';

  @override
  String get howToStep2Title => '2. Select Job Post';

  @override
  String get howToStep2Desc => 'Select a job post you want to apply for.';

  @override
  String get howToStep3Title => '3. Click Register Schedule';

  @override
  String get howToStep3Desc =>
      'Click the blue [Register Schedule] button at the bottom right of the job post.';

  @override
  String get encouragement1 => 'It\'s okay. There will be another opportunity.';

  @override
  String get encouragement2 =>
      'Good job. This experience will lead to your next success.';

  @override
  String get encouragement3 =>
      'That\'s it for today. Let\'s take a break and try again.';

  @override
  String get settingsPromoTitle => 'Fortune Alarm';

  @override
  String get settingsPromoDesc => 'From mission wake-up to today\'s fortune!';

  @override
  String get settingsPromoFooter => 'Check out other apps from SERIESSNAP!';

  @override
  String get noteAiAnalysisTitle => 'AI Company Analysis (Auto)';

  @override
  String get noteNewsSummaryHeader => 'Recent Company Issues / News';

  @override
  String get noteBusinessDirectionHeader => 'Business Direction & Keywords';

  @override
  String get noteJobConnectionHeader => 'Hiring Position Connection';

  @override
  String get noteRiskPointsHeader => 'Risks / Check Points';

  @override
  String get noteUserInputSection => 'User Input Section';

  @override
  String get noteAiAnalysisResultReady => 'Analysis results are ready.';

  @override
  String get noteAiAnalysisAdNotice => 'Watch an ad to see the full content.';

  @override
  String get noteLoadingAd => 'Loading ad...';

  @override
  String get noteLatestNews => 'Latest News:';

  @override
  String get noteAdNotCompleted =>
      'Ad not completed. Full content cannot be displayed.';

  @override
  String get noteWatchAdToView => 'Watch Ad for Free';

  @override
  String get noteAiAutoFillHint =>
      'Automatically filled with AI matching. (Manual entry possible)';

  @override
  String get feelingBad => 'Bad';

  @override
  String get feelingDisappointed => 'Disappointed';

  @override
  String get feelingNormal => 'Normal';

  @override
  String get feelingAmbiguous => 'Ambiguous';

  @override
  String get feelingGood => 'Good';

  @override
  String get noteExpectedQuestionsHeader => 'Expected Questions & Answers';

  @override
  String get noteCoreAppealHeader => 'Core Appeal Points';

  @override
  String get noteCoreAppealPlaceholder =>
      'Enter which of your strengths fit this company well';

  @override
  String get noteExpectedQuestionsPlaceholder =>
      'Organize questions and answers that might come up in the interview';

  @override
  String get micPermissionDenied =>
      'Microphone permission denied. Please allow in settings.';

  @override
  String recognizingText(String words) {
    return 'Recognizing: $words...';
  }

  @override
  String get companySearchTitle => 'Company Search';

  @override
  String get viewSimple => 'View Simple';

  @override
  String get viewAdvanced => 'AI Analysis/Advanced Record';

  @override
  String get inputAnswerHint =>
      'Please enter your answer (Voice input recommended)';

  @override
  String get feelingScore => 'Impression Score';

  @override
  String get advancedRecordTitle => 'Advanced Recording & Analysis';

  @override
  String get sttError => 'Voice recognition error occurred.';

  @override
  String get sttTimeout => 'Voice input timed out.';

  @override
  String get sttNoMatch => 'No recognized voice found.';

  @override
  String get sttNetworkError => 'Please check your network connection.';

  @override
  String get inputMyAnswerHint => 'Enter your answer (Voice input available)';

  @override
  String get interviewFeelingTitle => 'Feeling at the time of the interview';

  @override
  String get detailRecordSettings => 'Detailed record settings';

  @override
  String get done => 'Done';

  @override
  String get onboardingTitle1 => 'Easy Scheduling\nwith One Share Button';

  @override
  String get onboardingSubtitle1 =>
      'Just press the share button on a job site\nand the deadline will be automatically added to the calendar.';

  @override
  String get onboardingTitle2 =>
      'All Information Automatically\nwith One Share Button';

  @override
  String get onboardingSubtitle2 =>
      'Select Deadline Note from the share list\nto automatically fill in the company name, job title, and deadline.';

  @override
  String get onboardingTitle3 =>
      'Manage All Job Schedules\nSmartly at a Glance';

  @override
  String get onboardingSubtitle3 =>
      'From application to interview, manage complex schedules\nwith Deadline Note.';

  @override
  String get onboardingTitle4 =>
      'Continuous Step Management\nfor Application, Aptitude, and Interview';

  @override
  String get onboardingSubtitle4 =>
      'Easily add follow-up schedules like aptitude tests and interviews\nwith a few touches after passing the application phase.';

  @override
  String get onboardingTitle5 => 'Record and Manage\nYour Own Pass Strategy';

  @override
  String get onboardingSubtitle5 =>
      'Record company analysis notes and interview reviews\nto identify your strengths and weaknesses and increase your pass rate.';

  @override
  String get colorSetting => 'Color Setting by Step';

  @override
  String get year => '';

  @override
  String get month => '';

  @override
  String get getStarted => 'Get Started';

  @override
  String get continueText => 'Continue';

  @override
  String get adRemovePending => 'Ad removal is coming soon.';

  @override
  String get close => 'Close';

  @override
  String get adLoadError => 'Failed to load ad.';

  @override
  String get rollingEstimated => '(Rolling/Est.)';
}
