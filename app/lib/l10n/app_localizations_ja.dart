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
  String get tabGroups => 'グループ';

  @override
  String get tabSettings => '設定';

  @override
  String get commonCancel => 'キャンセル';

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
  String get signUpPasswordTooShort => 'パスワードは6文字以上で設定してください';

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
      '生年月日を登録すると、毎年カレンダーとグループの友人・家族にも誕生日として表示されます';

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
  String get settingsCouldNotOpenPage => 'ページを開けませんでした';

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
  String get groupFormNameLabel => 'グループ名';

  @override
  String get groupFormNameRequired => 'グループ名を入力してください';

  @override
  String get groupFormCreateButton => '作成する';

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
  String get groupJoinButton => 'このグループに参加する';

  @override
  String get groupJoinFailed => '参加に失敗しました。時間をおいて再度お試しください';

  @override
  String get groupDetailInviteCode => '招待コード';

  @override
  String get groupDetailInviteCodeCopied => '招待コードをコピーしました';

  @override
  String get groupDetailMembers => 'メンバー';

  @override
  String get groupDetailChat => 'トーク';

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
  String get anniversaryListTitle => '大切な記念日';

  @override
  String get anniversaryListEmpty => 'まだ記念日が登録されていません';

  @override
  String anniversaryListYearly(Object month, Object day) {
    return '毎年 $month月$day日';
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
  String get anniversaryDeleted => '記念日を削除しました';
}
