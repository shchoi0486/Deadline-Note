import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'마감노트'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @tabCalendar.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get tabCalendar;

  /// No description provided for @tabList.
  ///
  /// In ko, this message translates to:
  /// **'현황'**
  String get tabList;

  /// No description provided for @tabAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get tabAdd;

  /// No description provided for @tabNotes.
  ///
  /// In ko, this message translates to:
  /// **'노트'**
  String get tabNotes;

  /// No description provided for @tabSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get tabSettings;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @selectDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get selectDate;

  /// No description provided for @add.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get add;

  /// No description provided for @passed.
  ///
  /// In ko, this message translates to:
  /// **'합격'**
  String get passed;

  /// No description provided for @failed.
  ///
  /// In ko, this message translates to:
  /// **'불합격'**
  String get failed;

  /// No description provided for @confirmDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteContent.
  ///
  /// In ko, this message translates to:
  /// **'정말 삭제하시겠습니까?'**
  String get confirmDeleteContent;

  /// No description provided for @settingsDeadlineAlarm.
  ///
  /// In ko, this message translates to:
  /// **'마감 알림'**
  String get settingsDeadlineAlarm;

  /// No description provided for @settingsD3Alarm.
  ///
  /// In ko, this message translates to:
  /// **'D-3 알림'**
  String get settingsD3Alarm;

  /// No description provided for @settingsD1Alarm.
  ///
  /// In ko, this message translates to:
  /// **'D-1 알림'**
  String get settingsD1Alarm;

  /// No description provided for @settings3hAlarm.
  ///
  /// In ko, this message translates to:
  /// **'마감 3시간 전 알림'**
  String get settings3hAlarm;

  /// No description provided for @settingsHoliday.
  ///
  /// In ko, this message translates to:
  /// **'다국어 및 공휴일 설정'**
  String get settingsHoliday;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get settingsLanguage;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageChinese.
  ///
  /// In ko, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageHindi.
  ///
  /// In ko, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @settingsHolidayCountry.
  ///
  /// In ko, this message translates to:
  /// **'공휴일 기준 국가'**
  String get settingsHolidayCountry;

  /// No description provided for @settingsHolidayDesc.
  ///
  /// In ko, this message translates to:
  /// **'선택한 국가의 공공 데이터를 바탕으로 캘린더에 공휴일이 표시됩니다.'**
  String get settingsHolidayDesc;

  /// No description provided for @settingsShareAdd.
  ///
  /// In ko, this message translates to:
  /// **'공유로 추가'**
  String get settingsShareAdd;

  /// No description provided for @settingsShareAddDesc.
  ///
  /// In ko, this message translates to:
  /// **'채용 사이트 등에서 “공유” 버튼 → 마감노트 선택'**
  String get settingsShareAddDesc;

  /// No description provided for @holidayAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동 (시스템)'**
  String get holidayAuto;

  /// No description provided for @adRemove.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거하기'**
  String get adRemove;

  /// No description provided for @companyRequired.
  ///
  /// In ko, this message translates to:
  /// **'회사명 (필수)'**
  String get companyRequired;

  /// No description provided for @jobTitleOptional.
  ///
  /// In ko, this message translates to:
  /// **'직무/공고 제목 (선택)'**
  String get jobTitleOptional;

  /// No description provided for @fixedDeadline.
  ///
  /// In ko, this message translates to:
  /// **'고정 마감일'**
  String get fixedDeadline;

  /// No description provided for @rollingDeadline.
  ///
  /// In ko, this message translates to:
  /// **'상시채용'**
  String get rollingDeadline;

  /// No description provided for @estimatedDeadline.
  ///
  /// In ko, this message translates to:
  /// **'예상 마감일'**
  String get estimatedDeadline;

  /// No description provided for @deadlineRequired.
  ///
  /// In ko, this message translates to:
  /// **'마감일 (필수)'**
  String get deadlineRequired;

  /// No description provided for @deadlineAt.
  ///
  /// In ko, this message translates to:
  /// **'마감일'**
  String get deadlineAt;

  /// No description provided for @estimated.
  ///
  /// In ko, this message translates to:
  /// **'예상'**
  String get estimated;

  /// No description provided for @temporary.
  ///
  /// In ko, this message translates to:
  /// **'임시설정'**
  String get temporary;

  /// No description provided for @linkOptional.
  ///
  /// In ko, this message translates to:
  /// **'공고 링크 (선택)'**
  String get linkOptional;

  /// No description provided for @salaryOptional.
  ///
  /// In ko, this message translates to:
  /// **'급여 (선택)'**
  String get salaryOptional;

  /// No description provided for @memoOptional.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get memoOptional;

  /// No description provided for @notificationEnable.
  ///
  /// In ko, this message translates to:
  /// **'마감 임박 알림 받기'**
  String get notificationEnable;

  /// No description provided for @status.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get status;

  /// No description provided for @nextStep.
  ///
  /// In ko, this message translates to:
  /// **'다음 일정 추가'**
  String get nextStep;

  /// No description provided for @nextStepDesc.
  ///
  /// In ko, this message translates to:
  /// **'전형'**
  String get nextStepDesc;

  /// No description provided for @date.
  ///
  /// In ko, this message translates to:
  /// **'일정일'**
  String get date;

  /// No description provided for @companyNameRequiredMsg.
  ///
  /// In ko, this message translates to:
  /// **'회사명은 필수예요.'**
  String get companyNameRequiredMsg;

  /// No description provided for @noNextStepMsg.
  ///
  /// In ko, this message translates to:
  /// **'다음 전형이 없어요.'**
  String get noNextStepMsg;

  /// No description provided for @saveComplete.
  ///
  /// In ko, this message translates to:
  /// **'저장 완료'**
  String get saveComplete;

  /// No description provided for @filterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterAll;

  /// No description provided for @filterDocument.
  ///
  /// In ko, this message translates to:
  /// **'서류'**
  String get filterDocument;

  /// No description provided for @filterAptitude.
  ///
  /// In ko, this message translates to:
  /// **'인적성'**
  String get filterAptitude;

  /// No description provided for @filterInterview.
  ///
  /// In ko, this message translates to:
  /// **'면접'**
  String get filterInterview;

  /// No description provided for @filterFailed.
  ///
  /// In ko, this message translates to:
  /// **'불합격'**
  String get filterFailed;

  /// No description provided for @noSchedules.
  ///
  /// In ko, this message translates to:
  /// **'등록된 일정이 없습니다.'**
  String get noSchedules;

  /// No description provided for @noCompanyName.
  ///
  /// In ko, this message translates to:
  /// **'회사명 없음'**
  String get noCompanyName;

  /// No description provided for @noTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get noTitle;

  /// No description provided for @defaultScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get defaultScheduleTitle;

  /// No description provided for @noFilteredSchedules.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 일정이 없어요.'**
  String get noFilteredSchedules;

  /// No description provided for @statusInProgress.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 일정'**
  String get statusInProgress;

  /// No description provided for @statusClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감됨'**
  String get statusClosed;

  /// No description provided for @statusPassed.
  ///
  /// In ko, this message translates to:
  /// **'전형 통과'**
  String get statusPassed;

  /// No description provided for @openOriginalLink.
  ///
  /// In ko, this message translates to:
  /// **'원본 공고 열기'**
  String get openOriginalLink;

  /// No description provided for @editGuide.
  ///
  /// In ko, this message translates to:
  /// **'아래에서 수정 후 저장하세요.'**
  String get editGuide;

  /// No description provided for @copyComplete.
  ///
  /// In ko, this message translates to:
  /// **'복사 완료'**
  String get copyComplete;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get share;

  /// No description provided for @statusNotApplied.
  ///
  /// In ko, this message translates to:
  /// **'지원 전'**
  String get statusNotApplied;

  /// No description provided for @statusApplied.
  ///
  /// In ko, this message translates to:
  /// **'지원 완료'**
  String get statusApplied;

  /// No description provided for @statusDocument.
  ///
  /// In ko, this message translates to:
  /// **'서류'**
  String get statusDocument;

  /// No description provided for @statusVideoInterview.
  ///
  /// In ko, this message translates to:
  /// **'인적성검사'**
  String get statusVideoInterview;

  /// No description provided for @statusInterview1.
  ///
  /// In ko, this message translates to:
  /// **'1차면접'**
  String get statusInterview1;

  /// No description provided for @statusInterview2.
  ///
  /// In ko, this message translates to:
  /// **'2차면접'**
  String get statusInterview2;

  /// No description provided for @statusFinalInterview.
  ///
  /// In ko, this message translates to:
  /// **'최종면접'**
  String get statusFinalInterview;

  /// No description provided for @statusOffer.
  ///
  /// In ko, this message translates to:
  /// **'오퍼'**
  String get statusOffer;

  /// No description provided for @statusHired.
  ///
  /// In ko, this message translates to:
  /// **'합격'**
  String get statusHired;

  /// No description provided for @statusRejected.
  ///
  /// In ko, this message translates to:
  /// **'불합격'**
  String get statusRejected;

  /// No description provided for @badgeDocument.
  ///
  /// In ko, this message translates to:
  /// **'서류'**
  String get badgeDocument;

  /// No description provided for @badgeVideoInterview.
  ///
  /// In ko, this message translates to:
  /// **'인적성'**
  String get badgeVideoInterview;

  /// No description provided for @badgeInterview1.
  ///
  /// In ko, this message translates to:
  /// **'1차'**
  String get badgeInterview1;

  /// No description provided for @badgeInterview2.
  ///
  /// In ko, this message translates to:
  /// **'2차'**
  String get badgeInterview2;

  /// No description provided for @badgeFinalInterview.
  ///
  /// In ko, this message translates to:
  /// **'최종'**
  String get badgeFinalInterview;

  /// No description provided for @badgeClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get badgeClosed;

  /// No description provided for @dDayToday.
  ///
  /// In ko, this message translates to:
  /// **'D-DAY'**
  String get dDayToday;

  /// No description provided for @dDayClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get dDayClosed;

  /// No description provided for @outcomePassed.
  ///
  /// In ko, this message translates to:
  /// **'합격'**
  String get outcomePassed;

  /// No description provided for @outcomeFailed.
  ///
  /// In ko, this message translates to:
  /// **'불합격'**
  String get outcomeFailed;

  /// No description provided for @addMethodLink.
  ///
  /// In ko, this message translates to:
  /// **'URL링크로 추가'**
  String get addMethodLink;

  /// No description provided for @addMethodLinkDesc.
  ///
  /// In ko, this message translates to:
  /// **'채용 사이트 등에서 링크 공유'**
  String get addMethodLinkDesc;

  /// No description provided for @addMethodManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 추가'**
  String get addMethodManual;

  /// No description provided for @addMethodManualDesc.
  ///
  /// In ko, this message translates to:
  /// **'공유할 수 없는 공고일 때 빠르게 입력'**
  String get addMethodManualDesc;

  /// No description provided for @noteAppliedRole.
  ///
  /// In ko, this message translates to:
  /// **'지원 직무'**
  String get noteAppliedRole;

  /// No description provided for @noteNoTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get noteNoTitle;

  /// No description provided for @noteQuestionBank.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문'**
  String get noteQuestionBank;

  /// No description provided for @noteNoQuestions.
  ///
  /// In ko, this message translates to:
  /// **'등록된 질문이 없습니다.'**
  String get noteNoQuestions;

  /// No description provided for @noteRecentInterviews.
  ///
  /// In ko, this message translates to:
  /// **'최근 면접 기록'**
  String get noteRecentInterviews;

  /// No description provided for @saveError.
  ///
  /// In ko, this message translates to:
  /// **'저장 중 오류가 발생했어요: {error}'**
  String saveError(String error);

  /// No description provided for @countryKorea.
  ///
  /// In ko, this message translates to:
  /// **'대한민국'**
  String get countryKorea;

  /// No description provided for @countryUS.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get countryUS;

  /// No description provided for @countryJapan.
  ///
  /// In ko, this message translates to:
  /// **'일본'**
  String get countryJapan;

  /// No description provided for @countryChina.
  ///
  /// In ko, this message translates to:
  /// **'중국'**
  String get countryChina;

  /// No description provided for @countryUK.
  ///
  /// In ko, this message translates to:
  /// **'영국'**
  String get countryUK;

  /// No description provided for @countryGermany.
  ///
  /// In ko, this message translates to:
  /// **'독일'**
  String get countryGermany;

  /// No description provided for @countryFrance.
  ///
  /// In ko, this message translates to:
  /// **'프랑스'**
  String get countryFrance;

  /// No description provided for @countryCanada.
  ///
  /// In ko, this message translates to:
  /// **'캐나다'**
  String get countryCanada;

  /// No description provided for @countryAustralia.
  ///
  /// In ko, this message translates to:
  /// **'호주'**
  String get countryAustralia;

  /// No description provided for @noteTitle.
  ///
  /// In ko, this message translates to:
  /// **'노트'**
  String get noteTitle;

  /// No description provided for @noteTabCompany.
  ///
  /// In ko, this message translates to:
  /// **'기업 노트'**
  String get noteTabCompany;

  /// No description provided for @noteTabInterview.
  ///
  /// In ko, this message translates to:
  /// **'면접 회고'**
  String get noteTabInterview;

  /// No description provided for @noteEmptyCompany.
  ///
  /// In ko, this message translates to:
  /// **'아직 기업 노트가 없어요.\n오른쪽 아래 + 로 첫 기업 노트를 만들어보세요.'**
  String get noteEmptyCompany;

  /// No description provided for @noteEmptyInterview.
  ///
  /// In ko, this message translates to:
  /// **'아직 면접 회고가 없어요.\n오른쪽 아래 + 로 면접 회고를 남겨보세요.'**
  String get noteEmptyInterview;

  /// No description provided for @noteDeleteCompanyTitle.
  ///
  /// In ko, this message translates to:
  /// **'기업 노트 삭제'**
  String get noteDeleteCompanyTitle;

  /// No description provided for @noteDeleteInterviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'면접 회고 삭제'**
  String get noteDeleteInterviewTitle;

  /// No description provided for @noteDeleteEpisodeTitle.
  ///
  /// In ko, this message translates to:
  /// **'에피소드 삭제'**
  String get noteDeleteEpisodeTitle;

  /// No description provided for @noteDeleteQuestionTitle.
  ///
  /// In ko, this message translates to:
  /// **'질문 삭제'**
  String get noteDeleteQuestionTitle;

  /// No description provided for @noteDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name} ({type})\'을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'**
  String noteDeleteConfirm(Object name, Object type);

  /// No description provided for @noteDeleteSessionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name} ({round})\' 회고를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'**
  String noteDeleteSessionConfirm(Object name, Object round);

  /// No description provided for @noteTypeNote.
  ///
  /// In ko, this message translates to:
  /// **'노트'**
  String get noteTypeNote;

  /// No description provided for @noteTypeReview.
  ///
  /// In ko, this message translates to:
  /// **'회고'**
  String get noteTypeReview;

  /// No description provided for @noteNoCompanyName.
  ///
  /// In ko, this message translates to:
  /// **'회사명 없음'**
  String get noteNoCompanyName;

  /// No description provided for @noteRole.
  ///
  /// In ko, this message translates to:
  /// **'직무'**
  String get noteRole;

  /// No description provided for @noteRoleLabel.
  ///
  /// In ko, this message translates to:
  /// **'직무'**
  String get noteRoleLabel;

  /// No description provided for @noteRoleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 백엔드 개발자'**
  String get noteRoleHint;

  /// No description provided for @noteKeywords.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get noteKeywords;

  /// No description provided for @noteKeywordsLabel.
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get noteKeywordsLabel;

  /// No description provided for @noteKeywordsHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 소통능력, 문제해결력, 성실함 (쉼표로 구분)'**
  String get noteKeywordsHint;

  /// No description provided for @notePitchLabel.
  ///
  /// In ko, this message translates to:
  /// **'핵심 어필 포인트'**
  String get notePitchLabel;

  /// No description provided for @notePitchHint.
  ///
  /// In ko, this message translates to:
  /// **'나를 한 문장으로 표현한다면?'**
  String get notePitchHint;

  /// No description provided for @noteRisksLabel.
  ///
  /// In ko, this message translates to:
  /// **'리스크 / 우려사항'**
  String get noteRisksLabel;

  /// No description provided for @noteRisksHint.
  ///
  /// In ko, this message translates to:
  /// **'나의 약점이나 면접에서 공격받을 수 있는 부분'**
  String get noteRisksHint;

  /// No description provided for @noteInterviewDate.
  ///
  /// In ko, this message translates to:
  /// **'면접 날짜'**
  String get noteInterviewDate;

  /// No description provided for @noteReviewState.
  ///
  /// In ko, this message translates to:
  /// **'복습 상태'**
  String get noteReviewState;

  /// No description provided for @noteQuestionsCount.
  ///
  /// In ko, this message translates to:
  /// **'질문 {count}개'**
  String noteQuestionsCount(Object count);

  /// No description provided for @noteQuestionCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 질문'**
  String noteQuestionCount(Object count);

  /// No description provided for @roundUnknown.
  ///
  /// In ko, this message translates to:
  /// **'미정'**
  String get roundUnknown;

  /// No description provided for @roundScreening.
  ///
  /// In ko, this message translates to:
  /// **'서류/전화'**
  String get roundScreening;

  /// No description provided for @roundFirst.
  ///
  /// In ko, this message translates to:
  /// **'1차'**
  String get roundFirst;

  /// No description provided for @roundSecond.
  ///
  /// In ko, this message translates to:
  /// **'2차'**
  String get roundSecond;

  /// No description provided for @roundFinal.
  ///
  /// In ko, this message translates to:
  /// **'최종'**
  String get roundFinal;

  /// No description provided for @reviewNeedsReview.
  ///
  /// In ko, this message translates to:
  /// **'복습 필요'**
  String get reviewNeedsReview;

  /// No description provided for @reviewMastered.
  ///
  /// In ko, this message translates to:
  /// **'복습 완료'**
  String get reviewMastered;

  /// No description provided for @deadlineFixed.
  ///
  /// In ko, this message translates to:
  /// **'마감일'**
  String get deadlineFixed;

  /// No description provided for @deadlineRolling.
  ///
  /// In ko, this message translates to:
  /// **'상시채용'**
  String get deadlineRolling;

  /// No description provided for @deadlineExpired.
  ///
  /// In ko, this message translates to:
  /// **'마감됨'**
  String get deadlineExpired;

  /// No description provided for @deadlineUnknown.
  ///
  /// In ko, this message translates to:
  /// **'미정'**
  String get deadlineUnknown;

  /// No description provided for @pitfallMissingConcept.
  ///
  /// In ko, this message translates to:
  /// **'개념 누락'**
  String get pitfallMissingConcept;

  /// No description provided for @pitfallVagueLogic.
  ///
  /// In ko, this message translates to:
  /// **'논리 흐림'**
  String get pitfallVagueLogic;

  /// No description provided for @pitfallLackOfExamples.
  ///
  /// In ko, this message translates to:
  /// **'사례 부족'**
  String get pitfallLackOfExamples;

  /// No description provided for @pitfallNoMetrics.
  ///
  /// In ko, this message translates to:
  /// **'수치 없음'**
  String get pitfallNoMetrics;

  /// No description provided for @pitfallTooWordy.
  ///
  /// In ko, this message translates to:
  /// **'너무 장황'**
  String get pitfallTooWordy;

  /// No description provided for @pitfallUnclearPoint.
  ///
  /// In ko, this message translates to:
  /// **'요점 불명확'**
  String get pitfallUnclearPoint;

  /// No description provided for @noteAddCompany.
  ///
  /// In ko, this message translates to:
  /// **'기업 노트 추가'**
  String get noteAddCompany;

  /// No description provided for @noteEditCompany.
  ///
  /// In ko, this message translates to:
  /// **'기업 노트 편집'**
  String get noteEditCompany;

  /// No description provided for @noteCompanyName.
  ///
  /// In ko, this message translates to:
  /// **'회사명'**
  String get noteCompanyName;

  /// No description provided for @noteCompanyNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 구글 코리아'**
  String get noteCompanyNameHint;

  /// No description provided for @noteAddInterview.
  ///
  /// In ko, this message translates to:
  /// **'면접 회고 추가'**
  String get noteAddInterview;

  /// No description provided for @noteEditInterview.
  ///
  /// In ko, this message translates to:
  /// **'면접 회고 편집'**
  String get noteEditInterview;

  /// No description provided for @noteRoundLabel.
  ///
  /// In ko, this message translates to:
  /// **'면접 단계'**
  String get noteRoundLabel;

  /// No description provided for @noteDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'면접 날짜'**
  String get noteDateLabel;

  /// No description provided for @noteHeldAt.
  ///
  /// In ko, this message translates to:
  /// **'면접 일자'**
  String get noteHeldAt;

  /// No description provided for @noteAddQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 추가'**
  String get noteAddQuestion;

  /// No description provided for @noteEditQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 편집'**
  String get noteEditQuestion;

  /// No description provided for @noteAddQuestionHint.
  ///
  /// In ko, this message translates to:
  /// **'질문을 입력하세요'**
  String get noteAddQuestionHint;

  /// No description provided for @noteQuestionHint.
  ///
  /// In ko, this message translates to:
  /// **'질문을 입력하세요'**
  String get noteQuestionHint;

  /// No description provided for @noteQuestionLabel.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get noteQuestionLabel;

  /// No description provided for @noteAddEpisode.
  ///
  /// In ko, this message translates to:
  /// **'에피소드 추가'**
  String get noteAddEpisode;

  /// No description provided for @noteEditEpisode.
  ///
  /// In ko, this message translates to:
  /// **'에피소드 편집'**
  String get noteEditEpisode;

  /// No description provided for @noteEpisode.
  ///
  /// In ko, this message translates to:
  /// **'에피소드'**
  String get noteEpisode;

  /// No description provided for @noteEpisodeTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get noteEpisodeTitle;

  /// No description provided for @noteEpisodeTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 인턴 당시 데이터 분석으로 효율 20% 개선'**
  String get noteEpisodeTitleHint;

  /// No description provided for @noteEpisodeMetrics.
  ///
  /// In ko, this message translates to:
  /// **'핵심 수치/근거 (선택)'**
  String get noteEpisodeMetrics;

  /// No description provided for @noteEpisodeMetricsHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 매출 15% 증가, 처리 시간 30분 단축'**
  String get noteEpisodeMetricsHint;

  /// No description provided for @noteEpisodeSituation.
  ///
  /// In ko, this message translates to:
  /// **'상황/문제 (S)'**
  String get noteEpisodeSituation;

  /// No description provided for @noteEpisodeSituationHint.
  ///
  /// In ko, this message translates to:
  /// **'어떤 상황이었고 어떤 문제가 있었나요?'**
  String get noteEpisodeSituationHint;

  /// No description provided for @noteEpisodeAction.
  ///
  /// In ko, this message translates to:
  /// **'행동/해결 (A)'**
  String get noteEpisodeAction;

  /// No description provided for @noteEpisodeActionHint.
  ///
  /// In ko, this message translates to:
  /// **'문제를 해결하기 위해 구체적으로 어떤 행동을 했나요?'**
  String get noteEpisodeActionHint;

  /// No description provided for @noteEpisodeResult.
  ///
  /// In ko, this message translates to:
  /// **'결과 (R)'**
  String get noteEpisodeResult;

  /// No description provided for @noteEpisodeResultHint.
  ///
  /// In ko, this message translates to:
  /// **'그 행동의 결과는 어땠고 무엇을 배웠나요?'**
  String get noteEpisodeResultHint;

  /// No description provided for @noteEpisodeEvidence.
  ///
  /// In ko, this message translates to:
  /// **'증거 링크 (선택)'**
  String get noteEpisodeEvidence;

  /// No description provided for @noteEpisodeEvidenceHint.
  ///
  /// In ko, this message translates to:
  /// **'포트폴리오, 깃허브 등 관련 링크'**
  String get noteEpisodeEvidenceHint;

  /// No description provided for @noteInfoSearch.
  ///
  /// In ko, this message translates to:
  /// **'기업 분석 요약'**
  String get noteInfoSearch;

  /// No description provided for @noteSummaryLabel.
  ///
  /// In ko, this message translates to:
  /// **'기업 분석 요약'**
  String get noteSummaryLabel;

  /// No description provided for @noteSummaryHint.
  ///
  /// In ko, this message translates to:
  /// **'회사의 주요 사업, 최근 이슈 등을 요약해 보세요.'**
  String get noteSummaryHint;

  /// No description provided for @noteFitLabel.
  ///
  /// In ko, this message translates to:
  /// **'지원 동기 및 적합성'**
  String get noteFitLabel;

  /// No description provided for @noteFitHint.
  ///
  /// In ko, this message translates to:
  /// **'왜 이 회사여야 하는지, 내 경험과 어떻게 연결되는지 적어보세요.'**
  String get noteFitHint;

  /// No description provided for @noteAiMatching.
  ///
  /// In ko, this message translates to:
  /// **'AI 매칭'**
  String get noteAiMatching;

  /// No description provided for @noteAiMatchingRunning.
  ///
  /// In ko, this message translates to:
  /// **'AI가 기업 정보를 분석 중입니다...'**
  String get noteAiMatchingRunning;

  /// No description provided for @noteAiMatchingSuccess.
  ///
  /// In ko, this message translates to:
  /// **'기업 정보를 성공적으로 가져왔습니다.'**
  String get noteAiMatchingSuccess;

  /// No description provided for @noteAiMatchingFail.
  ///
  /// In ko, this message translates to:
  /// **'기업 정보를 가져오는데 실패했습니다.'**
  String get noteAiMatchingFail;

  /// No description provided for @searchNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버'**
  String get searchNaver;

  /// No description provided for @searchGoogle.
  ///
  /// In ko, this message translates to:
  /// **'구글'**
  String get searchGoogle;

  /// No description provided for @searchBlind.
  ///
  /// In ko, this message translates to:
  /// **'블라인드'**
  String get searchBlind;

  /// No description provided for @searchCatch.
  ///
  /// In ko, this message translates to:
  /// **'캐치'**
  String get searchCatch;

  /// No description provided for @searchJobPlanet.
  ///
  /// In ko, this message translates to:
  /// **'잡플래닛'**
  String get searchJobPlanet;

  /// No description provided for @searchLinkedIn.
  ///
  /// In ko, this message translates to:
  /// **'링크드인'**
  String get searchLinkedIn;

  /// No description provided for @searchGlassdoor.
  ///
  /// In ko, this message translates to:
  /// **'글래스도어'**
  String get searchGlassdoor;

  /// No description provided for @searchIndeed.
  ///
  /// In ko, this message translates to:
  /// **'인디드'**
  String get searchIndeed;

  /// No description provided for @searchOpenWork.
  ///
  /// In ko, this message translates to:
  /// **'오픈워크'**
  String get searchOpenWork;

  /// No description provided for @searchEnLighthouse.
  ///
  /// In ko, this message translates to:
  /// **'엔 라이트하우스'**
  String get searchEnLighthouse;

  /// No description provided for @searchBaidu.
  ///
  /// In ko, this message translates to:
  /// **'바이두'**
  String get searchBaidu;

  /// No description provided for @searchKanzhun.
  ///
  /// In ko, this message translates to:
  /// **'칸준'**
  String get searchKanzhun;

  /// No description provided for @searchMaimai.
  ///
  /// In ko, this message translates to:
  /// **'마이마이'**
  String get searchMaimai;

  /// No description provided for @searchAmbitionBox.
  ///
  /// In ko, this message translates to:
  /// **'앰비션박스'**
  String get searchAmbitionBox;

  /// No description provided for @searchYahoo.
  ///
  /// In ko, this message translates to:
  /// **'야후'**
  String get searchYahoo;

  /// No description provided for @searchDART.
  ///
  /// In ko, this message translates to:
  /// **'DART'**
  String get searchDART;

  /// No description provided for @searchYouTube.
  ///
  /// In ko, this message translates to:
  /// **'유튜브'**
  String get searchYouTube;

  /// No description provided for @noteInfoSection.
  ///
  /// In ko, this message translates to:
  /// **'기업 분석 정보'**
  String get noteInfoSection;

  /// No description provided for @noteEpisodes.
  ///
  /// In ko, this message translates to:
  /// **'경험 에피소드'**
  String get noteEpisodes;

  /// No description provided for @noteNoEpisodes.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 에피소드가 없어요.\n오른쪽 위 + 로 에피소드를 추가해보세요.'**
  String get noteNoEpisodes;

  /// No description provided for @noteStorySection.
  ///
  /// In ko, this message translates to:
  /// **'경험 에피소드'**
  String get noteStorySection;

  /// No description provided for @noteEmptyStory.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 에피소드가 없어요.\n오른쪽 위 + 로 에피소드를 추가해보세요.'**
  String get noteEmptyStory;

  /// No description provided for @noteEmptyQuestions.
  ///
  /// In ko, this message translates to:
  /// **'아직 질문이 없어요.\n오른쪽 위에서 질문을 추가해보세요.'**
  String get noteEmptyQuestions;

  /// No description provided for @noteQuestionRecord.
  ///
  /// In ko, this message translates to:
  /// **'질문 기록'**
  String get noteQuestionRecord;

  /// No description provided for @noteNextAction.
  ///
  /// In ko, this message translates to:
  /// **'다음 액션: {action}'**
  String noteNextAction(Object action);

  /// No description provided for @noteQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get noteQuestion;

  /// No description provided for @noteIntent.
  ///
  /// In ko, this message translates to:
  /// **'의도 (선택)'**
  String get noteIntent;

  /// No description provided for @noteIntentHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 로열티 및 직무 이해도 확인'**
  String get noteIntentHint;

  /// No description provided for @noteAnswerAtTheTime.
  ///
  /// In ko, this message translates to:
  /// **'내 답변(당시)'**
  String get noteAnswerAtTheTime;

  /// No description provided for @noteAnswerAtTheTimeHint.
  ///
  /// In ko, this message translates to:
  /// **'면접 당시 내가 했던 답변을 최대한 그대로 기록'**
  String get noteAnswerAtTheTimeHint;

  /// No description provided for @noteImproved60.
  ///
  /// In ko, this message translates to:
  /// **'개선 답변 60초'**
  String get noteImproved60;

  /// No description provided for @noteImproved60Hint.
  ///
  /// In ko, this message translates to:
  /// **'핵심 위주로 간결하게 (약 300자)'**
  String get noteImproved60Hint;

  /// No description provided for @noteImproved120.
  ///
  /// In ko, this message translates to:
  /// **'개선 답변 120초'**
  String get noteImproved120;

  /// No description provided for @noteImproved120Hint.
  ///
  /// In ko, this message translates to:
  /// **'구체적인 사례와 수치를 포함하여 상세하게 (약 600자)'**
  String get noteImproved120Hint;

  /// No description provided for @noteNextActionLabel.
  ///
  /// In ko, this message translates to:
  /// **'다음 액션 (선택)'**
  String get noteNextActionLabel;

  /// No description provided for @noteNextActionHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 관련 프로젝트 경험 정리하기, 기업 인재상 다시 확인'**
  String get noteNextActionHint;

  /// No description provided for @notePitfalls.
  ///
  /// In ko, this message translates to:
  /// **'아쉬웠던 점 체크'**
  String get notePitfalls;

  /// No description provided for @noteReviewStatus.
  ///
  /// In ko, this message translates to:
  /// **'복습 상태'**
  String get noteReviewStatus;

  /// No description provided for @addNextStepError.
  ///
  /// In ko, this message translates to:
  /// **'다음 일정 추가 중 오류가 발생했어요: {error}'**
  String addNextStepError(String error);

  /// No description provided for @originalLinkIncluded.
  ///
  /// In ko, this message translates to:
  /// **'원본 링크 포함'**
  String get originalLinkIncluded;

  /// No description provided for @jobInfo.
  ///
  /// In ko, this message translates to:
  /// **'채용정보({site})'**
  String jobInfo(String site);

  /// No description provided for @checkRequired.
  ///
  /// In ko, this message translates to:
  /// **'확인이 필요해요'**
  String get checkRequired;

  /// No description provided for @siteJobKorea.
  ///
  /// In ko, this message translates to:
  /// **'잡코리아'**
  String get siteJobKorea;

  /// No description provided for @siteSaramin.
  ///
  /// In ko, this message translates to:
  /// **'사람인'**
  String get siteSaramin;

  /// No description provided for @siteIncruit.
  ///
  /// In ko, this message translates to:
  /// **'인쿠르트'**
  String get siteIncruit;

  /// No description provided for @siteAlbamon.
  ///
  /// In ko, this message translates to:
  /// **'알바몬'**
  String get siteAlbamon;

  /// No description provided for @siteLinkedIn.
  ///
  /// In ko, this message translates to:
  /// **'링크드인'**
  String get siteLinkedIn;

  /// No description provided for @siteUnknown.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get siteUnknown;

  /// No description provided for @vaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일함'**
  String get vaultTitle;

  /// No description provided for @vaultFileTab.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get vaultFileTab;

  /// No description provided for @vaultMemoTab.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get vaultMemoTab;

  /// No description provided for @vaultAddFile.
  ///
  /// In ko, this message translates to:
  /// **'파일 추가'**
  String get vaultAddFile;

  /// No description provided for @vaultAddMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 추가'**
  String get vaultAddMemo;

  /// No description provided for @vaultEditMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 편집'**
  String get vaultEditMemo;

  /// No description provided for @vaultStorageWarning.
  ///
  /// In ko, this message translates to:
  /// **'파일/메모는 서버로 전송되지 않고 내 휴대폰에만 저장돼요.\n앱을 삭제하면 데이터가 함께 삭제될 수 있어요.'**
  String get vaultStorageWarning;

  /// No description provided for @vaultNoFiles.
  ///
  /// In ko, this message translates to:
  /// **'저장된 파일이 없어요.\n오른쪽 위 + 버튼으로 추가해보세요.'**
  String get vaultNoFiles;

  /// No description provided for @vaultNoMemos.
  ///
  /// In ko, this message translates to:
  /// **'저장된 메모가 없어요.\n오른쪽 위 + 버튼으로 추가해보세요.'**
  String get vaultNoMemos;

  /// No description provided for @vaultOpenFile.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get vaultOpenFile;

  /// No description provided for @vaultDefaultFileName.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get vaultDefaultFileName;

  /// No description provided for @title.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get title;

  /// No description provided for @content.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get content;

  /// No description provided for @exitConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'종료하시겠습니까?'**
  String get exitConfirmTitle;

  /// No description provided for @exitConfirmAction.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get exitConfirmAction;

  /// No description provided for @jobPostUrl.
  ///
  /// In ko, this message translates to:
  /// **'공고 URL'**
  String get jobPostUrl;

  /// No description provided for @parsingInProgress.
  ///
  /// In ko, this message translates to:
  /// **'공고 정보를 정리하는 중…'**
  String get parsingInProgress;

  /// No description provided for @checkSharedPost.
  ///
  /// In ko, this message translates to:
  /// **'공유된 공고를 확인해 주세요'**
  String get checkSharedPost;

  /// No description provided for @parseErrorMsg.
  ///
  /// In ko, this message translates to:
  /// **'링크 분석에 실패했어요. 직접 입력으로 전환해 주세요.'**
  String get parseErrorMsg;

  /// No description provided for @parseWarningDeadline.
  ///
  /// In ko, this message translates to:
  /// **'마감일을 자동으로 찾지 못했어요. 직접 선택해 주세요.'**
  String get parseWarningDeadline;

  /// No description provided for @parseWarningCompany.
  ///
  /// In ko, this message translates to:
  /// **'회사명을 자동으로 찾지 못했어요.'**
  String get parseWarningCompany;

  /// No description provided for @parseWarningTitle.
  ///
  /// In ko, this message translates to:
  /// **'공고 제목을 자동으로 찾지 못했어요.'**
  String get parseWarningTitle;

  /// No description provided for @shareInstruction.
  ///
  /// In ko, this message translates to:
  /// **'채용 사이트에서 [일정 등록] 버튼만 누르면\n공고 내용이 자동으로 저장됩니다!'**
  String get shareInstruction;

  /// No description provided for @howToUse.
  ///
  /// In ko, this message translates to:
  /// **'사용방법 확인하기'**
  String get howToUse;

  /// No description provided for @recommendedJobSites.
  ///
  /// In ko, this message translates to:
  /// **'추천 채용 사이트'**
  String get recommendedJobSites;

  /// No description provided for @howToUseTitle.
  ///
  /// In ko, this message translates to:
  /// **'사용방법'**
  String get howToUseTitle;

  /// No description provided for @howToStep1Title.
  ///
  /// In ko, this message translates to:
  /// **'1. 추천 채용 사이트 선택'**
  String get howToStep1Title;

  /// No description provided for @howToStep1Desc.
  ///
  /// In ko, this message translates to:
  /// **'원하는 채용 사이트를 클릭하여 접속하세요.'**
  String get howToStep1Desc;

  /// No description provided for @howToStep2Title.
  ///
  /// In ko, this message translates to:
  /// **'2. 채용 공고 선택'**
  String get howToStep2Title;

  /// No description provided for @howToStep2Desc.
  ///
  /// In ko, this message translates to:
  /// **'지원하고자 하는 채용 공고를 선택해 주세요.'**
  String get howToStep2Desc;

  /// No description provided for @howToStep3Title.
  ///
  /// In ko, this message translates to:
  /// **'3. [일정 등록] 버튼 클릭'**
  String get howToStep3Title;

  /// No description provided for @howToStep3Desc.
  ///
  /// In ko, this message translates to:
  /// **'공고 페이지 우측 하단에 있는 파란색 [일정 등록] 버튼을 클릭하면 정보가 자동으로 저장됩니다!'**
  String get howToStep3Desc;

  /// No description provided for @encouragement1.
  ///
  /// In ko, this message translates to:
  /// **'아쉽지만 괜찮아요. 다음 기회가 있어요.'**
  String get encouragement1;

  /// No description provided for @encouragement2.
  ///
  /// In ko, this message translates to:
  /// **'수고했어요. 이번 경험이 다음 합격으로 이어질 거예요.'**
  String get encouragement2;

  /// No description provided for @encouragement3.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 여기까지. 잠깐 쉬고 다시 가보자.'**
  String get encouragement3;

  /// No description provided for @settingsPromoTitle.
  ///
  /// In ko, this message translates to:
  /// **'포춘 알람'**
  String get settingsPromoTitle;

  /// No description provided for @settingsPromoDesc.
  ///
  /// In ko, this message translates to:
  /// **'미션 기상부터 오늘의 운세까지!'**
  String get settingsPromoDesc;

  /// No description provided for @settingsPromoFooter.
  ///
  /// In ko, this message translates to:
  /// **'SERIESSNAP의 다른 앱도 만나보세요!'**
  String get settingsPromoFooter;

  /// No description provided for @noteAiAnalysisTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 기업 분석 (자동 생성)'**
  String get noteAiAnalysisTitle;

  /// No description provided for @noteNewsSummaryHeader.
  ///
  /// In ko, this message translates to:
  /// **'최근 기업 이슈 / 뉴스 요약'**
  String get noteNewsSummaryHeader;

  /// No description provided for @noteBusinessDirectionHeader.
  ///
  /// In ko, this message translates to:
  /// **'사업 방향 & 성장 키워드'**
  String get noteBusinessDirectionHeader;

  /// No description provided for @noteJobConnectionHeader.
  ///
  /// In ko, this message translates to:
  /// **'채용 포지션 연결 포인트'**
  String get noteJobConnectionHeader;

  /// No description provided for @noteRiskPointsHeader.
  ///
  /// In ko, this message translates to:
  /// **'리스크 / 체크 포인트'**
  String get noteRiskPointsHeader;

  /// No description provided for @noteUserInputSection.
  ///
  /// In ko, this message translates to:
  /// **'사용자 입력 섹션'**
  String get noteUserInputSection;

  /// No description provided for @noteAiAnalysisResultReady.
  ///
  /// In ko, this message translates to:
  /// **'최신 뉴스 분석 결과가 준비되었습니다.'**
  String get noteAiAnalysisResultReady;

  /// No description provided for @noteAiAnalysisAdNotice.
  ///
  /// In ko, this message translates to:
  /// **'광고 시청 후 전체 내용을 확인하실 수 있습니다.'**
  String get noteAiAnalysisAdNotice;

  /// No description provided for @noteLoadingAd.
  ///
  /// In ko, this message translates to:
  /// **'광고를 불러오는 중입니다...'**
  String get noteLoadingAd;

  /// No description provided for @noteLatestNews.
  ///
  /// In ko, this message translates to:
  /// **'최신 뉴스:'**
  String get noteLatestNews;

  /// No description provided for @noteAdNotCompleted.
  ///
  /// In ko, this message translates to:
  /// **'광고 시청이 완료되지 않아 결과를 확인할 수 없습니다.'**
  String get noteAdNotCompleted;

  /// No description provided for @noteWatchAdToView.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 무료 보기'**
  String get noteWatchAdToView;

  /// No description provided for @noteAiAutoFillHint.
  ///
  /// In ko, this message translates to:
  /// **'AI 매칭 시 자동으로 채워집니다. (수동 입력 가능)'**
  String get noteAiAutoFillHint;

  /// No description provided for @feelingBad.
  ///
  /// In ko, this message translates to:
  /// **'망함'**
  String get feelingBad;

  /// No description provided for @feelingDisappointed.
  ///
  /// In ko, this message translates to:
  /// **'아쉽'**
  String get feelingDisappointed;

  /// No description provided for @feelingNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get feelingNormal;

  /// No description provided for @feelingAmbiguous.
  ///
  /// In ko, this message translates to:
  /// **'애매'**
  String get feelingAmbiguous;

  /// No description provided for @feelingGood.
  ///
  /// In ko, this message translates to:
  /// **'잘함'**
  String get feelingGood;

  /// No description provided for @noteExpectedQuestionsHeader.
  ///
  /// In ko, this message translates to:
  /// **'예상 질문 & 답변 메모'**
  String get noteExpectedQuestionsHeader;

  /// No description provided for @noteCoreAppealHeader.
  ///
  /// In ko, this message translates to:
  /// **'핵심 어필 포인트'**
  String get noteCoreAppealHeader;

  /// No description provided for @noteCoreAppealPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'나의 어떤 강점이 이 기업과 잘 맞는지 입력하세요'**
  String get noteCoreAppealPlaceholder;

  /// No description provided for @noteExpectedQuestionsPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'면접에서 나올 법한 질문과 답변을 정리해보세요'**
  String get noteExpectedQuestionsPlaceholder;

  /// No description provided for @micPermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'마이크 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.'**
  String get micPermissionDenied;

  /// No description provided for @recognizingText.
  ///
  /// In ko, this message translates to:
  /// **'인식 중: {words}...'**
  String recognizingText(String words);

  /// No description provided for @companySearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'기업 관련 검색'**
  String get companySearchTitle;

  /// No description provided for @viewSimple.
  ///
  /// In ko, this message translates to:
  /// **'간단히 보기'**
  String get viewSimple;

  /// No description provided for @viewAdvanced.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석/심화 기록'**
  String get viewAdvanced;

  /// No description provided for @inputAnswerHint.
  ///
  /// In ko, this message translates to:
  /// **'답변 내용을 입력해주세요 (음성 입력 권장)'**
  String get inputAnswerHint;

  /// No description provided for @feelingScore.
  ///
  /// In ko, this message translates to:
  /// **'체감 점수'**
  String get feelingScore;

  /// No description provided for @advancedRecordTitle.
  ///
  /// In ko, this message translates to:
  /// **'심화 기록 및 분석'**
  String get advancedRecordTitle;

  /// No description provided for @sttError.
  ///
  /// In ko, this message translates to:
  /// **'음성 인식 오류가 발생했습니다.'**
  String get sttError;

  /// No description provided for @sttTimeout.
  ///
  /// In ko, this message translates to:
  /// **'음성 입력 시간이 초과되었습니다.'**
  String get sttTimeout;

  /// No description provided for @sttNoMatch.
  ///
  /// In ko, this message translates to:
  /// **'인식된 음성이 없습니다.'**
  String get sttNoMatch;

  /// No description provided for @sttNetworkError.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요.'**
  String get sttNetworkError;

  /// No description provided for @inputMyAnswerHint.
  ///
  /// In ko, this message translates to:
  /// **'내 답변을 입력하세요 (음성 입력 가능)'**
  String get inputMyAnswerHint;

  /// No description provided for @interviewFeelingTitle.
  ///
  /// In ko, this message translates to:
  /// **'면접 당시 느낌'**
  String get interviewFeelingTitle;

  /// No description provided for @detailRecordSettings.
  ///
  /// In ko, this message translates to:
  /// **'상세 기록 설정'**
  String get detailRecordSettings;

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @onboardingTitle1.
  ///
  /// In ko, this message translates to:
  /// **'공유버튼 하나로\n일정을 간편하게'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In ko, this message translates to:
  /// **'채용사이트에서 공유 버튼만 누르면\n마감일정이 자동으로 달력에 등록됩니다.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ko, this message translates to:
  /// **'공유버튼 한 번으로\n모든 정보를 자동으로'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In ko, this message translates to:
  /// **'공유 목록에서 마감노트를 선택하면\n회사명, 공고 제목, 마감일까지 자동 입력됩니다.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ko, this message translates to:
  /// **'모든 채용일정을\n한눈에 스마트하게'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In ko, this message translates to:
  /// **'서류 접수부터 면접까지, 복잡한 일정을\nDeadline Note 하나로 관리하세요'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In ko, this message translates to:
  /// **'서류, 인적성, 면접\n끊임없는 전형 단계 관리'**
  String get onboardingTitle4;

  /// No description provided for @onboardingSubtitle4.
  ///
  /// In ko, this message translates to:
  /// **'서류 합격 후 인적성, 면접 등 후속 일정도\n터치 몇 번으로 손쉽게 추가할 수 있습니다.'**
  String get onboardingSubtitle4;

  /// No description provided for @onboardingTitle5.
  ///
  /// In ko, this message translates to:
  /// **'나만의 합격 전략\n기록하고 관리하기'**
  String get onboardingTitle5;

  /// No description provided for @onboardingSubtitle5.
  ///
  /// In ko, this message translates to:
  /// **'기업별 분석 노트와 면접 회고를 기록하여\n나만의 장단점을 파악하고 합격률을 높이세요.'**
  String get onboardingSubtitle5;

  /// No description provided for @colorSetting.
  ///
  /// In ko, this message translates to:
  /// **'전형별 색상 설정'**
  String get colorSetting;

  /// No description provided for @year.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get year;

  /// No description provided for @month.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get month;

  /// No description provided for @getStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get getStarted;

  /// No description provided for @continueText.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get continueText;

  /// No description provided for @adRemovePending.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거 기능은 준비 중입니다.'**
  String get adRemovePending;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @adLoadError.
  ///
  /// In ko, this message translates to:
  /// **'광고를 불러올 수 없습니다.'**
  String get adLoadError;

  /// No description provided for @rollingEstimated.
  ///
  /// In ko, this message translates to:
  /// **'(상시/예상)'**
  String get rollingEstimated;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
