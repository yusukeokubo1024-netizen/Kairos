// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appLocked => 'Kairosはロックされています';

  @override
  String get authenticate => '認証する';

  @override
  String get biometricAuthReason => 'Kairosを開くには認証が必要です';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabTasks => 'タスク';

  @override
  String get tabNotifications => '通知';

  @override
  String get notificationsEmpty => '新着はありません';

  @override
  String get notificationsScheduleGone => 'この予定はすでに削除されています';

  @override
  String get scheduleActivityCreated => '予定を作成しました';

  @override
  String get scheduleActivityUpdatedTime => '日時を更新しました';

  @override
  String get scheduleActivityUpdatedTitle => '予定名を更新しました';

  @override
  String get scheduleActivityUpdatedOther => '予定を更新しました';

  @override
  String get tabGroups => 'グループ';

  @override
  String get tabSettings => '設定';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonUnnamedUser => '名前未設定';

  @override
  String get commonDone => '完了';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '削除';

  @override
  String get commonUndo => '元に戻す';

  @override
  String get commonEdit => '編集';

  @override
  String get commonAdd => '追加';

  @override
  String get commonNotSet => '未設定';

  @override
  String get loginTagline => '大切な瞬間の共有';

  @override
  String get loginEmailLabel => 'メールアドレス';

  @override
  String get loginEmailRequired => 'メールアドレスを入力してください';

  @override
  String get loginPasswordLabel => 'パスワード';

  @override
  String get loginPasswordRequired => 'パスワードを入力してください';

  @override
  String get loginButton => 'ログイン';

  @override
  String get loginForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get loginSignUpLink => '新規登録はこちら';

  @override
  String get loginErrorWrongCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get loginErrorInvalidEmail => 'メールアドレスの形式が正しくありません';

  @override
  String get loginErrorUserDisabled => 'このアカウントは無効化されています';

  @override
  String get loginErrorTooManyRequests =>
      'ログインの試行回数が多すぎます。しばらく時間をおいてから再度お試しください';

  @override
  String get loginErrorGeneric => 'ログインに失敗しました。しばらくしてから再度お試しください';

  @override
  String get signUpTitle => '新規登録';

  @override
  String get signUpNameLabel => '表示名';

  @override
  String get signUpNameRequired => '表示名を入力してください';

  @override
  String get signUpPasswordLabel => 'パスワード（6文字以上）';

  @override
  String get signUpPasswordTooShort => 'パスワードは8文字以上で設定してください';

  @override
  String get signUpButton => '登録する';

  @override
  String get signUpErrorEmailInUse => 'このメールアドレスは既に登録されています';

  @override
  String get signUpErrorGeneric => '登録に失敗しました。しばらくしてから再度お試しください';

  @override
  String get signUpBiometricOfferTitle => 'この端末を信頼しますか？';

  @override
  String get signUpBiometricOfferBody =>
      '次回からメールアドレスとパスワードの入力なしで、Face ID / 指紋だけでログインできるようになります。';

  @override
  String get signUpBiometricOfferSkip => '後で設定する';

  @override
  String get signUpBiometricOfferEnable => '有効にする';

  @override
  String get resetPasswordTitle => 'パスワード再設定';

  @override
  String get resetPasswordInstructions =>
      '登録済みのメールアドレスを入力してください。再設定用のリンクを送信します。';

  @override
  String get resetPasswordSuccess => 'パスワード再設定用のメールを送信しました';

  @override
  String get resetPasswordError => '送信に失敗しました。メールアドレスをご確認ください';

  @override
  String get resetPasswordButton => '送信する';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsDisplayNameUnset => '(表示名未設定)';

  @override
  String get settingsEmailUnverified => 'メールアドレスが未確認です';

  @override
  String get settingsResendVerification => '再送信';

  @override
  String get settingsEmailVerificationSent => '確認メールを再送信しました';

  @override
  String get settingsEditDisplayName => '表示名を編集';

  @override
  String settingsDisplayNameSaved(Object name) {
    return '表示名を「$name」に変更しました';
  }

  @override
  String settingsDisplayNameSaveFailed(Object error) {
    return '表示名の保存に失敗しました: $error';
  }

  @override
  String get settingsBirthday => '生年月日';

  @override
  String get settingsBirthdayPick => '生年月日を選択';

  @override
  String settingsBirthdayValue(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get settingsBirthdayHint =>
      '生年月日を登録すると、毎年あなたのカレンダーに誕生日として表示されます。グループのメンバーには共有されません';

  @override
  String get settingsBirthdaySaveFailed => '生年月日の保存に失敗しました。時間をおいて再度お試しください';

  @override
  String get settingsWeatherLocation => 'お住まいの地域（天気予報）';

  @override
  String get settingsWeatherLocationTitle => 'お住まいの地域';

  @override
  String get settingsWeatherLocationCountryTitle => '国・地域を選択';

  @override
  String get settingsWeatherLocationCountrySearchHint => '国名で検索';

  @override
  String get settingsWeatherLocationCountryNotFound => '見つかりませんでした';

  @override
  String get settingsWeatherLocationPrefectureTitle => '地域を選択';

  @override
  String get settingsWeatherLocationPrefectureSearchHint => '地域名で検索';

  @override
  String get settingsWeatherLocationCitySearchHint => '地名で検索';

  @override
  String get settingsWeatherLocationManualEntry => 'その他（直接入力）';

  @override
  String get settingsWeatherLocationHint => '例: 渋谷、横浜、札幌、New York';

  @override
  String get settingsWeatherLocationHelper => '「〜区」「〜都」などを付けずに地名だけで検索してください';

  @override
  String get settingsWeatherLocationConfirmTitle => 'この地域でよろしいですか？';

  @override
  String settingsWeatherLocationSaved(Object place) {
    return '$place を登録しました';
  }

  @override
  String get settingsWeatherLocationNotFound => '地域が見つかりませんでした';

  @override
  String settingsWeatherLocationSearchFailed(Object error) {
    return '地域の検索に失敗しました: $error';
  }

  @override
  String settingsWeatherLocationSaveFailed(Object error) {
    return '地域の保存に失敗しました: $error';
  }

  @override
  String get settingsAccountLinking => 'アカウント連携';

  @override
  String get settingsGoogleLink => 'Googleと連携';

  @override
  String get settingsGoogleLinked => '連携済み';

  @override
  String get settingsGoogleNotLinked => '未連携';

  @override
  String get settingsGoogleLinkSuccess => 'Googleアカウントと連携しました';

  @override
  String get settingsGoogleLinkInUse => 'このGoogleアカウントは既に別のKairosアカウントで使われています';

  @override
  String get settingsGoogleLinkFailed => 'Google連携に失敗しました';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsNotificationsSubtitle => '予定・タスク・記念日のリマインダー通知';

  @override
  String get settingsBiometricLock => 'Face ID / 指紋認証でロック';

  @override
  String get settingsBiometricLockSubtitle => 'アプリを開くたびに認証を求めます';

  @override
  String get settingsAnniversaries => '大切な記念日';

  @override
  String get settingsAnniversariesSubtitle => '毎年通知したい記念日を登録';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTermsOfService => '利用規約';

  @override
  String get settingsSupport => 'サポート';

  @override
  String get settingsTrash => 'ゴミ箱';

  @override
  String get settingsCalendarShare => '共有カレンダー';

  @override
  String get settingsColorLabels => '予定の色分け';

  @override
  String get settingsCouldNotOpenPage => 'ページを開けませんでした';

  @override
  String get colorLabelsTitle => '予定の色分け';

  @override
  String get colorLabelsExplanation =>
      '自分や家族の名前ごとに色を決めておくと、予定を作成するときにその人を選ぶだけで色がつきます。';

  @override
  String get colorLabelsEmpty => 'まだ登録されていません';

  @override
  String get colorLabelsAddButton => '追加する';

  @override
  String get colorLabelsNameLabel => '名前（例：自分、妻、息子）';

  @override
  String get colorLabelsNameRequired => '名前を入力してください';

  @override
  String get colorLabelsDeleteConfirmTitle => '削除しますか？';

  @override
  String get colorLabelsDeleteConfirmBody => 'この色分けを削除します。すでに作成した予定の色は変わりません。';

  @override
  String get colorLabelsSaveFailed => '保存に失敗しました。時間をおいて再度お試しください';

  @override
  String get settingsPackingTemplates => '持ち物リストのテンプレート';

  @override
  String get packingTemplatesTitle => '持ち物リストのテンプレート';

  @override
  String get packingTemplatesExplanation =>
      '「プール」「旅行」のようなテンプレートを作っておくと、予定を作るときに持ち物リストとしてまとめて追加できます。';

  @override
  String get packingTemplatesEmpty => 'まだ登録されていません';

  @override
  String get packingTemplatesAddButton => '追加する';

  @override
  String get packingTemplatesNameLabel => 'テンプレート名（例：プール、旅行）';

  @override
  String get packingTemplatesNameRequired => '名前を入力してください';

  @override
  String get packingTemplatesItemsLabel => '持ち物（1行に1つ）';

  @override
  String get packingTemplatesItemsHelper => '改行して複数入力できます';

  @override
  String get packingTemplatesItemsRequired => '持ち物を1つ以上入力してください';

  @override
  String get packingTemplatesDeleteConfirmTitle => '削除しますか？';

  @override
  String get packingTemplatesDeleteConfirmBody =>
      'このテンプレートを削除します。すでに予定に追加した持ち物リストは変わりません。';

  @override
  String get packingTemplatesSaveFailed => '保存に失敗しました。時間をおいて再度お試しください';

  @override
  String get scheduleFormPacking => '持ち物リスト';

  @override
  String get scheduleFormPackingFromTemplate => 'テンプレートから追加';

  @override
  String get scheduleFormPackingPickTemplate => 'テンプレートを選ぶ';

  @override
  String get scheduleFormPackingAddHint => '持ち物を入力して追加';

  @override
  String get scheduleDetailPacking => '持ち物リスト';

  @override
  String get scheduleFormColorPerson => '誰の予定？';

  @override
  String get scheduleFormColorOther => 'その他の色';

  @override
  String get scheduleFormManageColorLabels => '色分けを管理する';

  @override
  String get calendarShareTitle => '共有カレンダー';

  @override
  String get calendarShareExplanation =>
      'アプリを入れていない大切な人にも見せられる、閲覧専用のリンクを発行できます。予定のタイトルと日時だけが表示され、場所やメモ、参加メンバーの名前は含まれません。';

  @override
  String get calendarShareCreateButton => '共有リンクを発行する';

  @override
  String get calendarShareCreateFailed => '発行に失敗しました。時間をおいて再度お試しください';

  @override
  String get calendarShareLinkLabel => '共有リンク';

  @override
  String get calendarShareCopyButton => 'リンクをコピー';

  @override
  String get calendarShareCopied => 'リンクをコピーしました';

  @override
  String get calendarShareRevokeButton => '共有を解除する';

  @override
  String get calendarShareRevokeConfirmTitle => '共有を解除しますか？';

  @override
  String get calendarShareRevokeConfirmBody =>
      'このリンクは無効になり、相手はカレンダーを見られなくなります。';

  @override
  String get calendarShareRevoked => '共有を解除しました';

  @override
  String get calendarShareRevokeFailed => '解除に失敗しました。時間をおいて再度お試しください';

  @override
  String get settingsLogout => 'ログアウト';

  @override
  String get settingsDeleteAccount => 'アカウントを削除';

  @override
  String get settingsDeleteAccountConfirmTitle => 'アカウントを削除しますか？';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'プロフィール、所有する予定・タスク・グループを含むすべてのデータが削除されます。この操作は取り消せません。複数人で共有しているグループがある場合は、先にメンバーを整理してください。';

  @override
  String get settingsDeleteAccountConfirmButton => '削除する';

  @override
  String get settingsDeleteAccountRequiresRecentLogin =>
      'セキュリティのため、一度ログアウトしてから再度ログインし、もう一度お試しください';

  @override
  String get settingsDeleteAccountFailed => 'アカウントの削除に失敗しました';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeSystem => '端末の設定に合わせる';

  @override
  String get settingsAddHomeWidget => 'ホーム画面ウィジェットを追加';

  @override
  String get settingsNotificationSounds => '通知音の設定';

  @override
  String get settingsAddHomeWidgetHint => '今日の予定を一目で確認できます(Android)';

  @override
  String get settingsAddHomeWidgetManual => 'ホーム画面を長押し→ウィジェット→Kairosから追加してください';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get supportTitle => 'サポート';

  @override
  String get supportFaqTitle => 'よくある質問';

  @override
  String get supportFaqPasswordQ => 'パスワードを忘れてしまいました';

  @override
  String get supportFaqPasswordA =>
      'ログイン画面の「パスワードをお忘れですか？」からご登録のメールアドレスを入力すると、再設定用のメールが届きます。';

  @override
  String get supportFaqBiometricQ => 'アプリを開くたびにパスワードを入力したくありません';

  @override
  String get supportFaqBiometricA =>
      '設定画面の「Face ID / 指紋でロック」をオンにすると、次回以降は生体認証だけでアプリを開けるようになります（端末が対応している場合）。';

  @override
  String get supportFaqGroupQ => 'グループに参加するにはどうすればいいですか？';

  @override
  String get supportFaqGroupA =>
      'グループのオーナーから共有された招待コードを、グループ画面右上のアイコンから入力してください。';

  @override
  String get supportFaqWeatherQ => '天気予報の地域を変更したい';

  @override
  String get supportFaqWeatherA =>
      '設定画面の「お住まいの地域」から、国・都道府県（州・省）・市区町村の順に選択できます。天気の詳細はタップすると外部サイトで確認できます。';

  @override
  String get supportFaqNotificationQ => '通知が届きません';

  @override
  String get supportFaqNotificationA =>
      '設定画面で通知がオンになっているかご確認のうえ、お使いの端末・ブラウザ側の通知許可もあわせてご確認ください。';

  @override
  String get supportFaqLanguageQ => 'アプリの表示言語を変えたい';

  @override
  String get supportFaqLanguageA =>
      '設定画面の「言語」から、日本語・English・한국어・中文の中から選べます。切り替えるとアプリ全体に反映されます。';

  @override
  String get supportFaqDeleteQ => 'アカウントやデータを削除したい';

  @override
  String get supportFaqDeleteA =>
      '設定画面の「アカウント削除」から、ご自身で削除できます。ご不明な点があれば下記の連絡先までお問い合わせください。';

  @override
  String get supportAiTitle => 'AIに質問する';

  @override
  String get supportAiDescription =>
      '上記のよくある質問に載っていない内容も、下の欄に入力すると自動で回答します（24時間対応）。';

  @override
  String get supportAiGreeting => 'こんにちは！Kairosについて何でも聞いてください。';

  @override
  String get supportAiInputHint => '質問を入力してください';

  @override
  String get supportAiSend => '送信';

  @override
  String get supportAiThinking => '回答を作成しています…';

  @override
  String supportAiRetrying(Object attempt, Object max) {
    return '混み合っています。再試行しています…（$attempt/$max）';
  }

  @override
  String get supportAiError =>
      '申し訳ありません、混み合っているため回答を取得できませんでした。少し時間をおいて再度お試しいただくか、下記のメールアドレスまでお問い合わせください。';

  @override
  String get supportAiNotConfigured => 'AI質問機能は準備中です。下記のメールアドレスまでお問い合わせください。';

  @override
  String get supportContactTitle => 'お問い合わせ';

  @override
  String get supportContactBody =>
      '上記で解決しない場合や、不具合の報告・プライバシーに関するお問い合わせは、次のメールアドレスで受け付けます。';

  @override
  String get trashTitle => 'ゴミ箱';

  @override
  String get trashEmpty => 'ゴミ箱は空です';

  @override
  String get trashRestore => '復元';

  @override
  String get trashDeleteForever => '完全に削除';

  @override
  String get trashDeleteAll => 'すべて削除';

  @override
  String get trashDeleteAllConfirmTitle => 'すべて完全に削除しますか？';

  @override
  String trashDeleteAllConfirmBody(Object count) {
    return 'ゴミ箱の$count件をすべて完全に削除します。元に戻せません。';
  }

  @override
  String get trashRestored => '復元しました';

  @override
  String trashDeletedOn(Object collection, Object date) {
    return '$collection ・ $dateに削除';
  }

  @override
  String get trashCollectionSchedule => '予定';

  @override
  String get trashCollectionTask => 'タスク';

  @override
  String get trashCollectionAnniversary => '記念日';

  @override
  String get trashCollectionGroup => 'グループ';

  @override
  String get taskListTitle => 'タスク';

  @override
  String get taskListPending => '未完了';

  @override
  String get taskListDone => '完了済み';

  @override
  String get taskListEmptyPending => '未完了のタスクはありません';

  @override
  String get taskListEmptyDone => '完了したタスクはありません';

  @override
  String get taskListFromSchedule => '予定の準備リストから追加';

  @override
  String get taskDeleted => 'タスクを削除しました';

  @override
  String get taskFormTitleNew => 'タスクを作成';

  @override
  String get taskFormTitleEdit => 'タスクを編集';

  @override
  String get taskFormTitleLabel => 'タイトル';

  @override
  String get taskFormTitleRequired => 'タイトルを入力してください';

  @override
  String get taskFormPriority => '優先度';

  @override
  String get taskFormPriorityLow => '低';

  @override
  String get taskFormPriorityMedium => '中';

  @override
  String get taskFormPriorityHigh => '高';

  @override
  String get taskFormDueDate => '期限';

  @override
  String get taskFormDueDateNotSet => '設定なし';

  @override
  String get scheduleDetailTitle => '予定の詳細';

  @override
  String get scheduleDeleteConfirmTitle => '予定を削除しますか？';

  @override
  String get scheduleDeleteConfirmBody => '削除してもすぐ後なら元に戻せます。';

  @override
  String get scheduleDeleted => '予定を削除しました';

  @override
  String get scheduleAllDaySuffix => '(終日)';

  @override
  String scheduleParticipants(Object count) {
    return '参加者 $count人';
  }

  @override
  String get scheduleReminderNone => '通知しない';

  @override
  String scheduleReminderBefore(Object minutes) {
    return '$minutes分前に通知';
  }

  @override
  String get scheduleCouldNotOpenMap => '地図を開けませんでした';

  @override
  String get scheduleFormTitleNew => '予定を作成';

  @override
  String get scheduleFormTitleEdit => '予定を編集';

  @override
  String get scheduleFormTitleLabel => 'タイトル';

  @override
  String get scheduleFormTitleRequired => 'タイトルを入力してください';

  @override
  String get scheduleFormAllDay => '終日';

  @override
  String get scheduleFormStart => '開始';

  @override
  String get scheduleFormEnd => '終了';

  @override
  String get scheduleFormEndBeforeStart => '終了時刻は開始時刻より後にしてください';

  @override
  String get scheduleFormLocation => '場所';

  @override
  String get scheduleFormNotes => 'メモ';

  @override
  String get scheduleFormColor => '色';

  @override
  String get scheduleFormRecurrence => '繰り返し';

  @override
  String get scheduleFormRecurrenceNone => '繰り返しなし';

  @override
  String get scheduleFormRecurrenceDaily => '毎日';

  @override
  String get scheduleFormRecurrenceWeekly => '毎週';

  @override
  String get scheduleFormRecurrenceMonthly => '毎月';

  @override
  String get scheduleFormRecurrenceYearly => '毎年';

  @override
  String get scheduleFormRecurrenceEndDate => '終了日';

  @override
  String get scheduleFormRecurrenceNoEnd => '終了しない';

  @override
  String get scheduleFormNotification => '通知';

  @override
  String get scheduleFormReminderNone => '通知しない';

  @override
  String get scheduleFormReminder5 => '5分前';

  @override
  String get scheduleFormReminder15 => '15分前';

  @override
  String get scheduleFormReminder30 => '30分前';

  @override
  String get scheduleFormReminder60 => '1時間前';

  @override
  String get scheduleFormReminder1440 => '1日前';

  @override
  String get scheduleFormAlarmStyle => 'アラームのように鳴らす';

  @override
  String get scheduleFormAlarmStyleHintIos =>
      '止めるまで目覚ましのように鳴ります。マナーモード中やアプリを閉じているときでも鳴ります（iOS 26以降）';

  @override
  String get scheduleFormAlarmStyleHint =>
      '画面ロック中でも全画面表示（Android限定）。機種やAndroidのバージョンによっては、設定アプリ側で「アラームとリマインダー」の許可が別途必要な場合があります';

  @override
  String get scheduleFormCalendar => 'カレンダー';

  @override
  String get scheduleFormCalendarHint => 'ホーム画面のフィルターで表示/非表示を切り替えるための分類です';

  @override
  String get scheduleFormGroupSuffix => '（グループ）';

  @override
  String get scheduleFormShareWith => '共有する相手';

  @override
  String get scheduleFormShareWithHint => 'グループのメンバーの中から、この予定を共有する人だけを選べます';

  @override
  String get scheduleFormInviteByEmail => 'メールアドレスで招待（この予定だけ）';

  @override
  String get scheduleFormEmailEmpty => '追加したい相手のメールアドレスを入力してください';

  @override
  String get scheduleFormEmailNotFound => 'そのメールアドレスのユーザーが見つかりませんでした';

  @override
  String get scheduleFormEmailIsSelf => '自分自身は追加できません';

  @override
  String get scheduleFormNoCandidates => '共有できる相手がいません。まずグループでメンバーを増やしてください。';

  @override
  String get scheduleFormLoadingName => '読み込み中...';

  @override
  String get scheduleFormPrepDialogTitle => '準備するものはありますか？';

  @override
  String get scheduleFormPrepDialogSkip => '追加しない';

  @override
  String get scheduleFormPrepDialogAdd => 'タスクに追加';

  @override
  String get categoryPersonal => '個人の予定';

  @override
  String get categoryWork => '仕事用';

  @override
  String get categoryPartner => '彼女・彼氏用';

  @override
  String get categoryFamily => '家族';

  @override
  String get categoryFriend => '友人';

  @override
  String get categoryOther => 'その他';

  @override
  String get calendarTitle => 'Kairos';

  @override
  String get calendarTagline => '大切な瞬間の共有';

  @override
  String get calendarViewList => '一覧で表示';

  @override
  String get calendarViewCalendar => 'カレンダーで表示';

  @override
  String get calendarFilterTooltip => '表示するカレンダーを選ぶ';

  @override
  String get scheduleSearchTooltip => '予定を検索';

  @override
  String get scheduleSearchHint => 'タイトル・場所・メモで検索';

  @override
  String get scheduleSearchPrompt => 'キーワードを入力して予定を探せます';

  @override
  String get scheduleSearchNoResults => '見つかりませんでした';

  @override
  String get calendarFilterTitle => '表示するカレンダー';

  @override
  String get calendarFilterClose => '閉じる';

  @override
  String get calendarMonthPickerTitle => '年月を選択';

  @override
  String calendarMonthPickerYear(Object year) {
    return '$year年';
  }

  @override
  String calendarMonthPickerMonth(Object month) {
    return '$month月';
  }

  @override
  String get calendarMonthPickerGo => '移動';

  @override
  String get calendarFormatMonth => '月';

  @override
  String get calendarFormatWeek => '週';

  @override
  String get calendarNoScheduleThisDay => 'この日の予定はありません';

  @override
  String get calendarAddScheduleThisDay => 'この日に予定を追加';

  @override
  String get calendarTapDayHint => '日付をタップすると、その日の予定やタスクが見られます';

  @override
  String get calendarNoUpcoming => '今後の予定はありません';

  @override
  String get calendarLoadError => '予定の読み込みに失敗しました';

  @override
  String calendarWeatherLine(Object max, Object min) {
    return '最高$max° / 最低$min°';
  }

  @override
  String calendarWeatherPrecipitation(Object percent) {
    return ' / 降水確率$percent%';
  }

  @override
  String calendarWeatherMorning(Object emoji, Object temp) {
    return '午前 $emoji $temp°';
  }

  @override
  String calendarWeatherAfternoon(Object emoji, Object temp) {
    return '午後 $emoji $temp°';
  }

  @override
  String get calendarDayColorLabel => 'この日に色をつける：';

  @override
  String get calendarAllDay => '終日';

  @override
  String calendarBirthdaySuffix(Object name) {
    return '$nameの誕生日';
  }

  @override
  String get calendarChristmasEve => 'クリスマスイブ';

  @override
  String get calendarChristmas => 'クリスマス';

  @override
  String get calendarNewYearsEve => '大晦日';

  @override
  String get calendarMothersDay => '母の日';

  @override
  String get calendarFathersDay => '父の日';

  @override
  String get calendarVernalEquinox => '春分の日';

  @override
  String get calendarAutumnalEquinox => '秋分の日';

  @override
  String get groupListTitle => 'グループ';

  @override
  String get groupListEmpty => 'まだグループがありません';

  @override
  String groupListMembers(Object count) {
    return 'メンバー $count人';
  }

  @override
  String get groupJoinTooltip => 'コードでグループに参加';

  @override
  String get groupFormTitle => 'グループを作成';

  @override
  String get groupRenameTitle => 'グループ名を変更';

  @override
  String get groupRenameFailed => 'グループ名を変更できませんでした。もう一度お試しください。';

  @override
  String get groupFormNameLabel => 'グループ名';

  @override
  String get groupFormNameRequired => 'グループ名を入力してください';

  @override
  String get groupFormCreateButton => '作成する';

  @override
  String get groupFormCreateFailed => 'グループを作成できませんでした。もう一度お試しください。';

  @override
  String get groupJoinTitle => 'グループに参加';

  @override
  String get groupJoinInstructions => 'グループのオーナーから共有された招待コードを入力してください。';

  @override
  String get groupJoinCodeLabel => '招待コード';

  @override
  String get groupJoinConfirmButton => '確認';

  @override
  String get groupJoinNotFound => 'コードが見つかりませんでした。入力内容をご確認ください';

  @override
  String get groupJoinConfirmTitle => 'この地域でよろしいですか？';

  @override
  String groupJoinMembers(Object count) {
    return 'メンバー $count人';
  }

  @override
  String get groupJoinAlreadyMember => 'すでにこのグループのメンバーです';

  @override
  String get groupJoinButton => '参加をリクエストする';

  @override
  String get groupJoinFailed => '参加に失敗しました。時間をおいて再度お試しください';

  @override
  String get groupJoinRequestSent => '参加リクエストを送りました。オーナーの承認をお待ちください';

  @override
  String get groupJoinAlreadyRequested => 'すでに参加リクエストを送っています';

  @override
  String get groupDetailInviteCode => '招待コード';

  @override
  String get groupDetailMuteNotifications => 'このグループの通知をミュート';

  @override
  String get groupDetailInviteCodeCopied => '招待コードをコピーしました';

  @override
  String get groupDetailMembers => 'メンバー';

  @override
  String get groupDetailChat => 'トーク';

  @override
  String get groupActivityScheduleAdded => '新しい予定が追加されました';

  @override
  String get groupListNewActivity => '新着';

  @override
  String get groupDetailJoinRequests => '参加リクエスト';

  @override
  String get groupJoinRequestApprove => '承認';

  @override
  String get groupJoinRequestReject => '却下';

  @override
  String get groupJoinRequestApproved => '承認しました';

  @override
  String get groupJoinRequestRejected => '却下しました';

  @override
  String get groupJoinRequestApproveFailed => '承認に失敗しました';

  @override
  String get groupJoinRequestRejectFailed => '却下に失敗しました';

  @override
  String get groupDeleteConfirmTitle => 'グループを削除しますか？';

  @override
  String get groupDeleteConfirmBody => '削除してもすぐ後なら元に戻せます。';

  @override
  String get groupDeleted => 'グループを削除しました';

  @override
  String groupChatTitle(Object name) {
    return '$name のトーク';
  }

  @override
  String get groupChatEmpty => 'まだメッセージはありません';

  @override
  String get groupChatInputHint => 'メッセージを入力';

  @override
  String get groupChatStampTooltip => 'スタンプ';

  @override
  String groupChatReadCount(Object count) {
    return '既読 $count';
  }

  @override
  String get settingsReadReceipts => '既読をつける';

  @override
  String get settingsReadReceiptsSubtitle =>
      'オフにすると、あなたがメッセージを読んでも相手に既読が表示されません';

  @override
  String get groupChatReport => 'メッセージを報告';

  @override
  String get groupChatReportConfirmTitle => 'このメッセージを報告しますか？';

  @override
  String get groupChatReportConfirmBody => '運営に内容が送信されます。不適切なメッセージの報告にご利用ください。';

  @override
  String get groupChatReported => '報告しました';

  @override
  String get groupChatReportFailed => '報告に失敗しました';

  @override
  String get groupLeaveTooltip => 'グループから退出';

  @override
  String get groupLeaveConfirmTitle => 'このグループから退出しますか？';

  @override
  String get groupLeaveConfirmBody => '退出すると、このグループのトークや予定は見られなくなります。';

  @override
  String get groupLeft => 'グループから退出しました';

  @override
  String get groupLeaveFailed => '退出に失敗しました';

  @override
  String get groupRemoveMemberTooltip => 'メンバーを削除';

  @override
  String get groupRemoveMemberConfirmTitle => 'このメンバーを削除しますか？';

  @override
  String get groupRemoveMemberConfirmBody =>
      '削除すると、このメンバーはグループのトークや予定が見られなくなります。';

  @override
  String get groupMemberRemoved => 'メンバーを削除しました';

  @override
  String get groupRemoveMemberFailed => '削除に失敗しました';

  @override
  String get anniversaryListTitle => '大切な記念日';

  @override
  String get anniversaryListEmpty => 'まだ記念日が登録されていません';

  @override
  String anniversaryListYearly(Object month, Object day) {
    return '毎年 $month月$day日';
  }

  @override
  String anniversaryListMonthly(Object day) {
    return '毎月$day日';
  }

  @override
  String get anniversaryFormTitleNew => '記念日を追加';

  @override
  String get anniversaryFormTitleEdit => '記念日を編集';

  @override
  String get anniversaryFormNameLabel => '名前（例：結婚記念日、誕生日）';

  @override
  String get anniversaryFormNameRequired => '名前を入力してください';

  @override
  String get anniversaryFormDate => '日付（毎年）';

  @override
  String anniversaryFormDateValue(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get anniversaryFormDatePickerHelp => '月日を選択（年は使いません）';

  @override
  String get anniversaryFormNotifyHint => '毎年この日の朝9時に通知します';

  @override
  String get anniversaryFormRecurrence => '繰り返し';

  @override
  String get anniversaryFormRecurrenceYearly => '毎年';

  @override
  String get anniversaryFormRecurrenceMonthly => '毎月';

  @override
  String get anniversaryFormDayOfMonth => '日にち';

  @override
  String anniversaryFormDayOfMonthValue(Object day) {
    return '毎月$day日';
  }

  @override
  String get anniversaryFormBusinessDayAdjust => '土日祝なら翌営業日にずらす';

  @override
  String get anniversaryFormBusinessDayAdjustHint =>
      '支払日など、休日を避けたい日付用です。誕生日などの記念日にはおすすめしません';

  @override
  String get anniversaryFormNotifyHintMonthly => '毎月この日の朝9時に通知します';

  @override
  String get anniversaryFormColor => '色';

  @override
  String get anniversaryDeleted => '記念日を削除しました';

  @override
  String get tabClock => '時計';

  @override
  String get clockTabWorld => '世界時計';

  @override
  String get clockTabAlarm => 'アラーム';

  @override
  String get clockTabStopwatch => 'ストップウォッチ';

  @override
  String get clockTabTimer => 'タイマー';

  @override
  String get worldClockEmpty => 'まだ都市が追加されていません。+で追加してください';

  @override
  String get worldClockAddTooltip => '都市を追加';

  @override
  String get worldClockSearchHint => '都市名やタイムゾーンを検索';

  @override
  String get worldClockNoResults => '見つかりませんでした';

  @override
  String get worldClockToday => '今日';

  @override
  String get worldClockYesterday => '前日';

  @override
  String get worldClockTomorrow => '翌日';

  @override
  String get worldClockRemoved => '都市を削除しました';

  @override
  String get alarmEmpty => 'まだアラームがありません。+で追加してください';

  @override
  String get alarmAddTooltip => 'アラームを追加';

  @override
  String get alarmAddTitle => 'アラームを追加';

  @override
  String get alarmEditTitle => 'アラームを編集';

  @override
  String get alarmLabelField => 'ラベル';

  @override
  String get alarmLabelPlaceholder => 'アラーム';

  @override
  String get alarmRepeat => '繰り返し';

  @override
  String get alarmRepeatNever => 'しない';

  @override
  String get alarmDeleteConfirmTitle => 'このアラームを削除しますか？';

  @override
  String get alarmDeleted => 'アラームを削除しました';

  @override
  String get alarmDefaultLabel => 'アラーム';

  @override
  String get ringingStop => '停止';

  @override
  String get ringingSnooze => 'スヌーズ';

  @override
  String get ringingSnoozedSnackbar => '9分後に再度通知します';

  @override
  String get timerDurationHint => '時間を設定してください';

  @override
  String get timerStart => '開始';

  @override
  String get timerPauseAction => '一時停止';

  @override
  String get timerResumeAction => '再開';

  @override
  String get timerResetAction => 'リセット';

  @override
  String get timerRunningLabel => '残り時間';

  @override
  String get timerUpTitle => 'タイマー終了';

  @override
  String get timerHoursLabel => '時間';

  @override
  String get timerMinutesLabel => '分';

  @override
  String get timerSecondsLabel => '秒';

  @override
  String get stopwatchStart => '開始';

  @override
  String get stopwatchStop => '停止';

  @override
  String get stopwatchLap => 'ラップ';

  @override
  String get stopwatchReset => 'リセット';

  @override
  String stopwatchLapNumber(Object number) {
    return 'ラップ $number';
  }

  @override
  String get alarmSnooze => 'スヌーズ';

  @override
  String get alarmSnoozeOff => 'オフ';

  @override
  String alarmSnoozeMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String alarmSnoozeSummary(int minutes) {
    return 'スヌーズ$minutes分';
  }

  @override
  String get alarmSoundTitle => 'アラーム音';

  @override
  String get alarmSoundSystem => 'デフォルト';

  @override
  String get alarmSoundBell => '黒電話';

  @override
  String get alarmSoundAlarmClock => '目覚まし時計';

  @override
  String get alarmSoundBirds => 'さえずり';

  @override
  String get alarmSoundDigital => 'デジタル';

  @override
  String get alarmSoundMarimba => 'マリンバ';

  @override
  String get alarmSoundWave => 'ウェーブ';

  @override
  String get alarmSoundHint => 'タップすると試聴できます。アラームとタイマーで鳴ります。';
}
