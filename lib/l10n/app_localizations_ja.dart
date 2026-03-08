// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '締め切りノート';

  @override
  String get today => '今日';

  @override
  String get tabCalendar => '日程';

  @override
  String get tabList => '状況';

  @override
  String get tabAdd => '追加';

  @override
  String get tabNotes => 'ノート';

  @override
  String get tabSettings => '設定';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get selectDate => '日付選択';

  @override
  String get add => '追加';

  @override
  String get passed => '合格';

  @override
  String get failed => '不合格';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String get confirmDeleteContent => '本当に削除しますか？';

  @override
  String get settingsDeadlineAlarm => '締め切りアラーム';

  @override
  String get settingsD3Alarm => 'D-3 アラーム';

  @override
  String get settingsD1Alarm => 'D-1 アラーム';

  @override
  String get settings3hAlarm => '締め切り3時間前';

  @override
  String get settingsHoliday => '言語と祝日の設定';

  @override
  String get settingsLanguage => '言語設定';

  @override
  String get languageKorean => '韓国語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get settingsHolidayCountry => '祝日の基準国';

  @override
  String get settingsHolidayDesc => '選択した国の公共データに基づいて、カレンダーに祝日が表示されます。';

  @override
  String get settingsShareAdd => '共有で追加';

  @override
  String get settingsShareAddDesc => '求人サイトなどで「共有」→ 締め切りノートを選択';

  @override
  String get holidayAuto => '自動 (システム)';

  @override
  String get adRemove => '広告を削除';

  @override
  String get companyRequired => '会社名 (必須)';

  @override
  String get jobTitleOptional => '職務/公募タイトル (任意)';

  @override
  String get fixedDeadline => '固定締め切り日';

  @override
  String get rollingDeadline => '常時採用';

  @override
  String get estimatedDeadline => '予想締め切り日';

  @override
  String get deadlineRequired => '締め切り日 (必須)';

  @override
  String get deadlineAt => '締め切り日';

  @override
  String get estimated => '予想';

  @override
  String get temporary => '臨時設定';

  @override
  String get linkOptional => '公募リンク (任意)';

  @override
  String get salaryOptional => '給与 (任意)';

  @override
  String get memoOptional => 'メモ (任意)';

  @override
  String get notificationEnable => '締め切り通知を受け取る';

  @override
  String get status => '状態';

  @override
  String get nextStep => '次の日程を追加';

  @override
  String get nextStepDesc => '選考';

  @override
  String get date => '日程日';

  @override
  String get companyNameRequiredMsg => '会社名は必須です。';

  @override
  String get noNextStepMsg => '次の選考がありません。';

  @override
  String get saveComplete => '保存完了';

  @override
  String get filterAll => '全部';

  @override
  String get filterDocument => '書類';

  @override
  String get filterAptitude => '適性';

  @override
  String get filterInterview => '面接';

  @override
  String get filterFailed => '不合格';

  @override
  String get noSchedules => '登録された予定がありません。';

  @override
  String get noCompanyName => '会社名なし';

  @override
  String get noTitle => 'タイトルなし';

  @override
  String get defaultScheduleTitle => '予定';

  @override
  String get noFilteredSchedules => '条件に合う予定がありません。';

  @override
  String get statusInProgress => '進行中の日程';

  @override
  String get statusClosed => '締切';

  @override
  String get statusPassed => '選考通過';

  @override
  String get openOriginalLink => '元の求人を開く';

  @override
  String get editGuide => '以下で修正して保存してください。';

  @override
  String get copyComplete => 'コピー完了';

  @override
  String get edit => '編集';

  @override
  String get copy => 'コピー';

  @override
  String get share => '共有';

  @override
  String get statusNotApplied => '応募前';

  @override
  String get statusApplied => '応募済み';

  @override
  String get statusDocument => '書類選考';

  @override
  String get statusVideoInterview => '適性検査';

  @override
  String get statusInterview1 => '1次面接';

  @override
  String get statusInterview2 => '2次面接';

  @override
  String get statusFinalInterview => '最終面接';

  @override
  String get statusOffer => '内定';

  @override
  String get statusHired => '合格';

  @override
  String get statusRejected => '不合格';

  @override
  String get badgeDocument => '書類';

  @override
  String get badgeVideoInterview => '適性';

  @override
  String get badgeInterview1 => '1次';

  @override
  String get badgeInterview2 => '2次';

  @override
  String get badgeFinalInterview => '最終';

  @override
  String get badgeClosed => '締切';

  @override
  String get dDayToday => 'D-DAY';

  @override
  String get dDayClosed => '締切';

  @override
  String get outcomePassed => '合格';

  @override
  String get outcomeFailed => '不合格';

  @override
  String get addMethodLink => 'URLリンクで追加';

  @override
  String get addMethodLinkDesc => '求人サイトからリンクを共有';

  @override
  String get addMethodManual => '直接追加';

  @override
  String get addMethodManualDesc => '共有できない求人を素早く入力';

  @override
  String get noteAppliedRole => '応募職務';

  @override
  String get noteNoTitle => 'タイトルなし';

  @override
  String get noteQuestionBank => '質問バンク';

  @override
  String get noteNoQuestions => '登録された質問がありません。';

  @override
  String get noteRecentInterviews => '最近の面接記録';

  @override
  String saveError(String error) {
    return '保存中にエラーが発生しました: $error';
  }

  @override
  String get countryKorea => '韓国';

  @override
  String get countryUS => 'アメリカ';

  @override
  String get countryJapan => '日本';

  @override
  String get countryChina => '中国';

  @override
  String get countryUK => 'イギリス';

  @override
  String get countryGermany => 'ドイツ';

  @override
  String get countryFrance => 'フランス';

  @override
  String get countryCanada => 'カナダ';

  @override
  String get countryAustralia => 'オーストラリア';

  @override
  String get noteTitle => 'ノート';

  @override
  String get noteTabCompany => '企業ノート';

  @override
  String get noteTabInterview => '面接の振り返り';

  @override
  String get noteEmptyCompany => 'まだ企業ノートがありません。\n右下の + で最初の企業ノートを作成しましょう。';

  @override
  String get noteEmptyInterview => 'まだ面接の振り返りがありません。\n右下の + で最初の振り返りを残しましょう。';

  @override
  String get noteDeleteCompanyTitle => '企業ノートを削除';

  @override
  String get noteDeleteInterviewTitle => '面접の振り返りを削除';

  @override
  String get noteDeleteEpisodeTitle => 'エピソードを削除';

  @override
  String get noteDeleteQuestionTitle => '質問を削除';

  @override
  String noteDeleteConfirm(Object name, Object type) {
    return '\'$name ($type)\'を削除しますか？\nこの操作は取り消せません。';
  }

  @override
  String noteDeleteSessionConfirm(Object name, Object round) {
    return '\'$name ($round)\' の振り返りを削除しますか？\nこの操作は取り消せません。';
  }

  @override
  String get noteTypeNote => 'ノート';

  @override
  String get noteTypeReview => '振り返り';

  @override
  String get noteNoCompanyName => '会社名なし';

  @override
  String get noteRole => '職務';

  @override
  String get noteRoleLabel => '職務';

  @override
  String get noteRoleHint => '例: バックエンドエンジニア';

  @override
  String get noteKeywords => 'キーワード';

  @override
  String get noteKeywordsLabel => 'キーワード';

  @override
  String get noteKeywordsHint => '例: Java, Spring, 大規模処理 (カンマ区切り)';

  @override
  String get notePitchLabel => '1分自己紹介 / コアピッチ';

  @override
  String get notePitchHint => '企業に自分を印象付けるコアメッセージ';

  @override
  String get noteRisksLabel => 'リスク / 懸念事項';

  @override
  String get noteRisksHint => '自分の弱点や面接で攻撃される可能性のある部分';

  @override
  String get noteInterviewDate => '面接日';

  @override
  String get noteReviewState => '復習ステータス';

  @override
  String noteQuestionsCount(Object count) {
    return '質問 $count個';
  }

  @override
  String noteQuestionCount(Object count) {
    return '$count個の質問';
  }

  @override
  String get roundUnknown => '未定';

  @override
  String get roundScreening => '書類/電話';

  @override
  String get roundFirst => '1次';

  @override
  String get roundSecond => '2次';

  @override
  String get roundFinal => '最終';

  @override
  String get reviewNeedsReview => '復習が必要';

  @override
  String get reviewMastered => '復習完了';

  @override
  String get deadlineFixed => '締め切り日';

  @override
  String get deadlineRolling => '常時採用';

  @override
  String get deadlineExpired => '締め切り';

  @override
  String get deadlineUnknown => '未定';

  @override
  String get pitfallMissingConcept => '概念の漏れ';

  @override
  String get pitfallVagueLogic => '論理が曖昧';

  @override
  String get pitfallLackOfExamples => '事例不足';

  @override
  String get pitfallNoMetrics => '数値なし';

  @override
  String get pitfallTooWordy => '冗長すぎる';

  @override
  String get pitfallUnclearPoint => '要点が不明確';

  @override
  String get noteAddCompany => '企業ノート追加';

  @override
  String get noteEditCompany => '企業ノート編集';

  @override
  String get noteCompanyName => '会社名';

  @override
  String get noteCompanyNameHint => '例: グーグル・ジャパン';

  @override
  String get noteAddInterview => '面接の振り返りを追加';

  @override
  String get noteEditInterview => '面接の振り返りを編集';

  @override
  String get noteRoundLabel => '面接段階';

  @override
  String get noteDateLabel => '面接日';

  @override
  String get noteHeldAt => '面接日';

  @override
  String get noteAddQuestion => '質問追加';

  @override
  String get noteEditQuestion => '質問編集';

  @override
  String get noteAddQuestionHint => '質問を入力してください';

  @override
  String get noteQuestionHint => '質問を入力してください';

  @override
  String get noteQuestionLabel => '質問';

  @override
  String get noteAddEpisode => 'エピソード追加';

  @override
  String get noteEditEpisode => 'エピソード編集';

  @override
  String get noteEpisode => 'エピソード';

  @override
  String get noteEpisodeTitle => 'タイトル';

  @override
  String get noteEpisodeTitleHint => '例: インターン中にデータ分析で効率を20%改善';

  @override
  String get noteEpisodeMetrics => '核心的な数値/根拠 (任意)';

  @override
  String get noteEpisodeMetricsHint => '例: 売上15%増加、処理時間30分短縮';

  @override
  String get noteEpisodeSituation => '状況/問題 (S)';

  @override
  String get noteEpisodeSituationHint => 'どのような状況で、どのような問題がありましたか？';

  @override
  String get noteEpisodeAction => '行動/解決 (A)';

  @override
  String get noteEpisodeActionHint => '問題を解決するために、具体的にどのような行動をしましたか？';

  @override
  String get noteEpisodeResult => '結果 (R)';

  @override
  String get noteEpisodeResultHint => 'その行動の結果はどうなり、何を学びましたか？';

  @override
  String get noteEpisodeEvidence => 'エビデンスリンク (任意)';

  @override
  String get noteEpisodeEvidenceHint => 'ポートフォリオ、GitHubなどの関連リンク';

  @override
  String get noteInfoSearch => '企業分析の要約';

  @override
  String get noteSummaryLabel => '企業分析の要約';

  @override
  String get noteSummaryHint => '会社の主要事業、最近のイシューなどを要約してみてください。';

  @override
  String get noteFitLabel => '志望動機および適合性';

  @override
  String get noteFitHint => 'なぜこの会社なのか、自分の経験とどうつながるか書いてみてください。';

  @override
  String get noteAiMatching => 'AIマッチング';

  @override
  String get noteAiMatchingRunning => 'AIが企業情報を分析中です...';

  @override
  String get noteAiMatchingSuccess => '企業情報の取得に成功しました。';

  @override
  String get noteAiMatchingFail => '企業情報の取得に失敗しました。';

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
  String get noteInfoSection => '企業分析情報';

  @override
  String get noteEpisodes => '経験エピソード';

  @override
  String get noteNoEpisodes => 'まだ登録されたエピソードがありません。\n右上の + でエピソードを追加してみてください。';

  @override
  String get noteStorySection => '経験エピソード';

  @override
  String get noteEmptyStory => 'まだ登録されたエピソードがありません。\n右上の + でエピソードを追加してみてください。';

  @override
  String get noteEmptyQuestions => 'まだ質問がありません。\n右上から質問を追加してみてください。';

  @override
  String get noteQuestionRecord => '質問記録';

  @override
  String noteNextAction(Object action) {
    return '次のアクション: $action';
  }

  @override
  String get noteQuestion => '質問';

  @override
  String get noteIntent => '意図 (任意)';

  @override
  String get noteIntentHint => '例: ロイヤリティおよび職務理解度の確認';

  @override
  String get noteAnswerAtTheTime => '回答(当時)';

  @override
  String get noteAnswerAtTheTimeHint => '面接当時の回答をできるだけそのまま記録';

  @override
  String get noteImproved60 => '改善回答 60秒';

  @override
  String get noteImproved60Hint => '核心を中心に簡潔に (約300文字)';

  @override
  String get noteImproved120 => '改善回答 120秒';

  @override
  String get noteImproved120Hint => '具体的な事例と数値を含めて詳細に (約600文字)';

  @override
  String get noteNextActionLabel => '次のアクション (任意)';

  @override
  String get noteNextActionHint => '例: 関連プロジェクトの経験を整理する、企業の求める人物像を再確認';

  @override
  String get notePitfalls => '反省点チェック';

  @override
  String get noteReviewStatus => '復習ステータス';

  @override
  String addNextStepError(String error) {
    return '次のステップの追加中にエラーが発生しました: $error';
  }

  @override
  String get originalLinkIncluded => '元のリンクを含む';

  @override
  String jobInfo(String site) {
    return '採用情報($site)';
  }

  @override
  String get checkRequired => '確認が必要です';

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
  String get siteUnknown => 'その他';

  @override
  String get vaultTitle => 'ファイルボックス';

  @override
  String get vaultFileTab => 'ファイル';

  @override
  String get vaultMemoTab => 'メモ';

  @override
  String get vaultAddFile => 'ファイル追加';

  @override
  String get vaultAddMemo => 'メモ追加';

  @override
  String get vaultEditMemo => 'メモ編集';

  @override
  String get vaultStorageWarning =>
      'ファイル/メモはサーバーに送信されず、お使いの携帯電話にのみ保存されます。\nアプリを削除するとデータが一緒に削除される可能性があります。';

  @override
  String get vaultNoFiles => '保存されたファイルがありません。\n右上の+ボタンで追加してみてください。';

  @override
  String get vaultNoMemos => '保存されたメモがありません。\n右上の+ボタンで追加してみてください。';

  @override
  String get vaultOpenFile => '開く';

  @override
  String get vaultDefaultFileName => 'ファイル';

  @override
  String get title => 'タイトル';

  @override
  String get content => '内容';

  @override
  String get exitConfirmTitle => '終了しますか？';

  @override
  String get exitConfirmAction => '終了';

  @override
  String get jobPostUrl => '求人URL';

  @override
  String get parsingInProgress => '求人情報を整理しています…';

  @override
  String get checkSharedPost => '共有された求人を確認してください';

  @override
  String get parseErrorMsg => 'リンクの解析に失敗しました。直接入力に切り替えてください。';

  @override
  String get parseWarningDeadline => '締め切りを自動的に見つけることができませんでした。手動で選択してください。';

  @override
  String get parseWarningCompany => '会社名を自動的に見つけることができませんでした。';

  @override
  String get parseWarningTitle => '募集要項のタイトルを自動的に見つけることができませんでした。';

  @override
  String get shareInstruction => '求人サイトなどで「共有」からリンクを送ると、自動的に入力されます。';

  @override
  String get howToUse => '使い方の確認';

  @override
  String get recommendedJobSites => 'おすすめの求人サイト';

  @override
  String get howToUseTitle => '使い方';

  @override
  String get howToStep1Title => '1. ブラウザメニューを開く';

  @override
  String get howToStep1Desc => '求人アプリやブラウザで求人を確認中なら、右下の「メニューアイコン」をクリックしてください。';

  @override
  String get howToStep2Title => '2. 共有ボタンを選択';

  @override
  String get howToStep2Desc => 'メニューポップアップが表示されたら、右上の「共有アイコン」をクリックします。';

  @override
  String get howToStep3Title => '3. 締め切りノートアプリを選択';

  @override
  String get howToStep3Desc => '共有リストから「締め切りノート」アイコンを探してクリックしてください。';

  @override
  String get howToStep4Title => '4. 自動入力の確認と保存';

  @override
  String get howToStep4Desc => '会社名、求人タイトル、締め切り日が自動的に抽出されます。確認後「保存」ボタンを押せば完了！';

  @override
  String get encouragement1 => '残念ですが大丈夫です。次の機会があります。';

  @override
  String get encouragement2 => 'お疲れ様でした。今回の経験が次の合格につながるはずです。';

  @override
  String get encouragement3 => '今日はここまで。少し休んでまた頑張りましょう。';

  @override
  String get settingsPromoTitle => 'フォーチュンアラーム';

  @override
  String get settingsPromoDesc => 'ミッション起床から今日の運勢まで！';

  @override
  String get settingsPromoFooter => 'SERIESSNAPの他のアプリもチェック！';

  @override
  String get noteAiAnalysisTitle => 'AI企業分析 (自動生成)';

  @override
  String get noteNewsSummaryHeader => '最近の企業イシュー / ニュース要約';

  @override
  String get noteBusinessDirectionHeader => '事業方向性＆成長キーワード';

  @override
  String get noteJobConnectionHeader => '採用ポジション接続ポイント';

  @override
  String get noteRiskPointsHeader => 'リスク / チェックポイント';

  @override
  String get noteUserInputSection => 'ユーザー入力セクション';

  @override
  String get noteAiAnalysisResultReady => '最新のニュース分析結果が準備できました。';

  @override
  String get noteAiAnalysisAdNotice => '広告視聴後に全内容を確認できます。';

  @override
  String get noteLoadingAd => '広告を読み込んでいます...';

  @override
  String get noteLatestNews => '最新ニュース:';

  @override
  String get noteAdNotCompleted => '広告視聴が完了しなかったため、結果を確認できません。';

  @override
  String get noteWatchAdToView => '広告を見て無料視聴';

  @override
  String get noteAiAutoFillHint => 'AIマッチング時に自動で入力されます。(手動入力可能)';

  @override
  String get feelingBad => 'だめ';

  @override
  String get feelingDisappointed => '惜しい';

  @override
  String get feelingNormal => '普通';

  @override
  String get feelingAmbiguous => '微妙';

  @override
  String get feelingGood => '良い';

  @override
  String get noteExpectedQuestionsHeader => '予想質問＆回答メモ';

  @override
  String get noteCoreAppealHeader => '核心アピールポイント';

  @override
  String get noteCoreAppealPlaceholder => '自分のどのような強みがこの企業に合っているか入力してください';

  @override
  String get noteExpectedQuestionsPlaceholder => '面接で出そうな質問と回答を整理してみましょう';

  @override
  String get micPermissionDenied => 'マイクの権限が拒否されました。設定で許可してください。';

  @override
  String recognizingText(String words) {
    return '認識中: $words...';
  }

  @override
  String get companySearchTitle => '企業関連検索';

  @override
  String get viewSimple => 'シンプル表示';

  @override
  String get viewAdvanced => 'AI分析/詳細記録';

  @override
  String get inputAnswerHint => '回答内容を入力してください (音声入力推奨)';

  @override
  String get feelingScore => '体感スコア';

  @override
  String get advancedRecordTitle => '詳細記録と分析';

  @override
  String get sttError => '音声認識エラーが発生しました。';

  @override
  String get sttTimeout => '音声入力時間がタイムアウトしました。';

  @override
  String get sttNoMatch => '認識された音声がありません。';

  @override
  String get sttNetworkError => 'ネットワーク接続を確認してください。';

  @override
  String get inputMyAnswerHint => '自分の回答を入力してください (音声入力可能)';

  @override
  String get interviewFeelingTitle => '面接当時の感じ';

  @override
  String get detailRecordSettings => '詳細記録設定';

  @override
  String get done => '完了';

  @override
  String get onboardingTitle1 => '共有ボタン一つで\n日程を簡単に';

  @override
  String get onboardingSubtitle1 =>
      '求人サイトで共有ボタンを押すだけで\n締め切り日程が自動的にカレンダーに登録されます。';

  @override
  String get onboardingTitle2 => '共有ボタン一度で\nすべての情報を自動で';

  @override
  String get onboardingSubtitle2 =>
      '共有リストから締め切りノートを選択すると\n会社名、求人タイトル、締め切り日まで自動入力されます。';

  @override
  String get onboardingTitle3 => 'すべての採用日程を\nひと目でスマートに';

  @override
  String get onboardingSubtitle3 =>
      '書類選考から面接まで、複雑な日程を\nDeadline Note一つで管理しましょう。';

  @override
  String get onboardingTitle4 => '書類、適性、面接\n絶え間ない選考段階の管理';

  @override
  String get onboardingSubtitle4 => '書類合格後の適性検査、面接など後続の日程も\n数回のタッチで簡単に追加できます。';

  @override
  String get onboardingTitle5 => '自分だけの合格戦略\n記録して管理する';

  @override
  String get onboardingSubtitle5 =>
      '企業別の分析ノートと面接の振り返りを記録して\n自分の強みと弱みを把握し、合格率を高めましょう。';

  @override
  String get colorSetting => '選考別カラー設定';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get getStarted => 'はじめる';

  @override
  String get continueText => '次へ';

  @override
  String get adRemovePending => '広告削除機能は準備中です。';

  @override
  String get close => '閉じる';

  @override
  String get adLoadError => '広告を読み込めませんでした。';

  @override
  String get rollingEstimated => '(常時/予想)';
}
