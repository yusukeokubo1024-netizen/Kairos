import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appLocked.
  ///
  /// In ja, this message translates to:
  /// **'Kairosはロックされています'**
  String get appLocked;

  /// No description provided for @authenticate.
  ///
  /// In ja, this message translates to:
  /// **'認証する'**
  String get authenticate;

  /// No description provided for @biometricAuthReason.
  ///
  /// In ja, this message translates to:
  /// **'Kairosを開くには認証が必要です'**
  String get biometricAuthReason;

  /// No description provided for @tabHome.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get tabHome;

  /// No description provided for @tabTasks.
  ///
  /// In ja, this message translates to:
  /// **'タスク'**
  String get tabTasks;

  /// No description provided for @tabGroups.
  ///
  /// In ja, this message translates to:
  /// **'グループ'**
  String get tabGroups;

  /// No description provided for @tabSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get tabSettings;

  /// No description provided for @commonCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get commonDone;

  /// No description provided for @commonSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get commonDelete;

  /// No description provided for @commonUndo.
  ///
  /// In ja, this message translates to:
  /// **'元に戻す'**
  String get commonUndo;

  /// No description provided for @commonEdit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get commonAdd;

  /// No description provided for @commonNotSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get commonNotSet;

  /// No description provided for @loginTagline.
  ///
  /// In ja, this message translates to:
  /// **'大切な瞬間の共有'**
  String get loginTagline;

  /// No description provided for @loginEmailLabel.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailRequired.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してください'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください'**
  String get loginPasswordRequired;

  /// No description provided for @loginButton.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードをお忘れですか？'**
  String get loginForgotPassword;

  /// No description provided for @loginSignUpLink.
  ///
  /// In ja, this message translates to:
  /// **'新規登録はこちら'**
  String get loginSignUpLink;

  /// No description provided for @loginErrorWrongCredentials.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスまたはパスワードが正しくありません'**
  String get loginErrorWrongCredentials;

  /// No description provided for @loginErrorInvalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get loginErrorInvalidEmail;

  /// No description provided for @loginErrorUserDisabled.
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは無効化されています'**
  String get loginErrorUserDisabled;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました。しばらくしてから再度お試しください'**
  String get loginErrorGeneric;

  /// No description provided for @signUpTitle.
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get signUpTitle;

  /// No description provided for @signUpNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'表示名'**
  String get signUpNameLabel;

  /// No description provided for @signUpNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'表示名を入力してください'**
  String get signUpNameRequired;

  /// No description provided for @signUpPasswordLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード（6文字以上）'**
  String get signUpPasswordLabel;

  /// No description provided for @signUpPasswordTooShort.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で設定してください'**
  String get signUpPasswordTooShort;

  /// No description provided for @signUpButton.
  ///
  /// In ja, this message translates to:
  /// **'登録する'**
  String get signUpButton;

  /// No description provided for @signUpErrorEmailInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に登録されています'**
  String get signUpErrorEmailInUse;

  /// No description provided for @signUpErrorGeneric.
  ///
  /// In ja, this message translates to:
  /// **'登録に失敗しました。しばらくしてから再度お試しください'**
  String get signUpErrorGeneric;

  /// No description provided for @signUpBiometricOfferTitle.
  ///
  /// In ja, this message translates to:
  /// **'この端末を信頼しますか？'**
  String get signUpBiometricOfferTitle;

  /// No description provided for @signUpBiometricOfferBody.
  ///
  /// In ja, this message translates to:
  /// **'次回からメールアドレスとパスワードの入力なしで、Face ID / 指紋だけでログインできるようになります。'**
  String get signUpBiometricOfferBody;

  /// No description provided for @signUpBiometricOfferSkip.
  ///
  /// In ja, this message translates to:
  /// **'後で設定する'**
  String get signUpBiometricOfferSkip;

  /// No description provided for @signUpBiometricOfferEnable.
  ///
  /// In ja, this message translates to:
  /// **'有効にする'**
  String get signUpBiometricOfferEnable;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ja, this message translates to:
  /// **'パスワード再設定'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In ja, this message translates to:
  /// **'登録済みのメールアドレスを入力してください。再設定用のリンクを送信します。'**
  String get resetPasswordInstructions;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In ja, this message translates to:
  /// **'パスワード再設定用のメールを送信しました'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordError.
  ///
  /// In ja, this message translates to:
  /// **'送信に失敗しました。メールアドレスをご確認ください'**
  String get resetPasswordError;

  /// No description provided for @resetPasswordButton.
  ///
  /// In ja, this message translates to:
  /// **'送信する'**
  String get resetPasswordButton;

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @settingsDisplayNameUnset.
  ///
  /// In ja, this message translates to:
  /// **'(表示名未設定)'**
  String get settingsDisplayNameUnset;

  /// No description provided for @settingsEditDisplayName.
  ///
  /// In ja, this message translates to:
  /// **'表示名を編集'**
  String get settingsEditDisplayName;

  /// No description provided for @settingsDisplayNameSaved.
  ///
  /// In ja, this message translates to:
  /// **'表示名を「{name}」に変更しました'**
  String settingsDisplayNameSaved(Object name);

  /// No description provided for @settingsDisplayNameSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'表示名の保存に失敗しました: {error}'**
  String settingsDisplayNameSaveFailed(Object error);

  /// No description provided for @settingsBirthday.
  ///
  /// In ja, this message translates to:
  /// **'生年月日'**
  String get settingsBirthday;

  /// No description provided for @settingsBirthdayPick.
  ///
  /// In ja, this message translates to:
  /// **'生年月日を選択'**
  String get settingsBirthdayPick;

  /// No description provided for @settingsBirthdayValue.
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日'**
  String settingsBirthdayValue(Object month, Object day);

  /// No description provided for @settingsBirthdayHint.
  ///
  /// In ja, this message translates to:
  /// **'生年月日を登録すると、毎年カレンダーとグループの友人・家族にも誕生日として表示されます'**
  String get settingsBirthdayHint;

  /// No description provided for @settingsWeatherLocation.
  ///
  /// In ja, this message translates to:
  /// **'お住まいの地域（天気予報）'**
  String get settingsWeatherLocation;

  /// No description provided for @settingsWeatherLocationTitle.
  ///
  /// In ja, this message translates to:
  /// **'お住まいの地域'**
  String get settingsWeatherLocationTitle;

  /// No description provided for @settingsWeatherLocationCountryTitle.
  ///
  /// In ja, this message translates to:
  /// **'国・地域を選択'**
  String get settingsWeatherLocationCountryTitle;

  /// No description provided for @settingsWeatherLocationCountrySearchHint.
  ///
  /// In ja, this message translates to:
  /// **'国名で検索'**
  String get settingsWeatherLocationCountrySearchHint;

  /// No description provided for @settingsWeatherLocationCountryNotFound.
  ///
  /// In ja, this message translates to:
  /// **'見つかりませんでした'**
  String get settingsWeatherLocationCountryNotFound;

  /// No description provided for @settingsWeatherLocationPrefectureTitle.
  ///
  /// In ja, this message translates to:
  /// **'地域を選択'**
  String get settingsWeatherLocationPrefectureTitle;

  /// No description provided for @settingsWeatherLocationPrefectureSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'地域名で検索'**
  String get settingsWeatherLocationPrefectureSearchHint;

  /// No description provided for @settingsWeatherLocationCitySearchHint.
  ///
  /// In ja, this message translates to:
  /// **'地名で検索'**
  String get settingsWeatherLocationCitySearchHint;

  /// No description provided for @settingsWeatherLocationManualEntry.
  ///
  /// In ja, this message translates to:
  /// **'その他（直接入力）'**
  String get settingsWeatherLocationManualEntry;

  /// No description provided for @settingsWeatherLocationHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 渋谷、横浜、札幌、New York'**
  String get settingsWeatherLocationHint;

  /// No description provided for @settingsWeatherLocationHelper.
  ///
  /// In ja, this message translates to:
  /// **'「〜区」「〜都」などを付けずに地名だけで検索してください'**
  String get settingsWeatherLocationHelper;

  /// No description provided for @settingsWeatherLocationConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'この地域でよろしいですか？'**
  String get settingsWeatherLocationConfirmTitle;

  /// No description provided for @settingsWeatherLocationSaved.
  ///
  /// In ja, this message translates to:
  /// **'{place} を登録しました'**
  String settingsWeatherLocationSaved(Object place);

  /// No description provided for @settingsWeatherLocationNotFound.
  ///
  /// In ja, this message translates to:
  /// **'地域が見つかりませんでした'**
  String get settingsWeatherLocationNotFound;

  /// No description provided for @settingsWeatherLocationSearchFailed.
  ///
  /// In ja, this message translates to:
  /// **'地域の検索に失敗しました: {error}'**
  String settingsWeatherLocationSearchFailed(Object error);

  /// No description provided for @settingsWeatherLocationSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'地域の保存に失敗しました: {error}'**
  String settingsWeatherLocationSaveFailed(Object error);

  /// No description provided for @settingsAccountLinking.
  ///
  /// In ja, this message translates to:
  /// **'アカウント連携'**
  String get settingsAccountLinking;

  /// No description provided for @settingsGoogleLink.
  ///
  /// In ja, this message translates to:
  /// **'Googleと連携'**
  String get settingsGoogleLink;

  /// No description provided for @settingsGoogleLinked.
  ///
  /// In ja, this message translates to:
  /// **'連携済み'**
  String get settingsGoogleLinked;

  /// No description provided for @settingsGoogleNotLinked.
  ///
  /// In ja, this message translates to:
  /// **'未連携'**
  String get settingsGoogleNotLinked;

  /// No description provided for @settingsGoogleLinkSuccess.
  ///
  /// In ja, this message translates to:
  /// **'Googleアカウントと連携しました'**
  String get settingsGoogleLinkSuccess;

  /// No description provided for @settingsGoogleLinkInUse.
  ///
  /// In ja, this message translates to:
  /// **'このGoogleアカウントは既に別のKairosアカウントで使われています'**
  String get settingsGoogleLinkInUse;

  /// No description provided for @settingsGoogleLinkFailed.
  ///
  /// In ja, this message translates to:
  /// **'Google連携に失敗しました'**
  String get settingsGoogleLinkFailed;

  /// No description provided for @settingsNotifications.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'予定・タスク・記念日のリマインダー通知'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In ja, this message translates to:
  /// **'Face ID / 指紋認証でロック'**
  String get settingsBiometricLock;

  /// No description provided for @settingsBiometricLockSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'アプリを開くたびに認証を求めます'**
  String get settingsBiometricLockSubtitle;

  /// No description provided for @settingsAnniversaries.
  ///
  /// In ja, this message translates to:
  /// **'大切な記念日'**
  String get settingsAnniversaries;

  /// No description provided for @settingsAnniversariesSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'毎年通知したい記念日を登録'**
  String get settingsAnniversariesSubtitle;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get settingsTermsOfService;

  /// No description provided for @settingsSupport.
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get settingsSupport;

  /// No description provided for @settingsCouldNotOpenPage.
  ///
  /// In ja, this message translates to:
  /// **'ページを開けませんでした'**
  String get settingsCouldNotOpenPage;

  /// No description provided for @settingsLogout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get settingsLogout;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しますか？'**
  String get settingsDeleteAccountConfirmTitle;

  /// No description provided for @settingsDeleteAccountConfirmBody.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール、所有する予定・タスク・グループを含むすべてのデータが削除されます。この操作は取り消せません。複数人で共有しているグループがある場合は、先にメンバーを整理してください。'**
  String get settingsDeleteAccountConfirmBody;

  /// No description provided for @settingsDeleteAccountConfirmButton.
  ///
  /// In ja, this message translates to:
  /// **'削除する'**
  String get settingsDeleteAccountConfirmButton;

  /// No description provided for @settingsDeleteAccountRequiresRecentLogin.
  ///
  /// In ja, this message translates to:
  /// **'セキュリティのため、一度ログアウトしてから再度ログインし、もう一度お試しください'**
  String get settingsDeleteAccountRequiresRecentLogin;

  /// No description provided for @settingsDeleteAccountFailed.
  ///
  /// In ja, this message translates to:
  /// **'アカウントの削除に失敗しました'**
  String get settingsDeleteAccountFailed;

  /// No description provided for @settingsLanguage.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get settingsLanguageJapanese;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageKorean.
  ///
  /// In ja, this message translates to:
  /// **'한국어'**
  String get settingsLanguageKorean;

  /// No description provided for @settingsLanguageChinese.
  ///
  /// In ja, this message translates to:
  /// **'中文'**
  String get settingsLanguageChinese;

  /// No description provided for @supportTitle.
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get supportTitle;

  /// No description provided for @supportFaqTitle.
  ///
  /// In ja, this message translates to:
  /// **'よくある質問'**
  String get supportFaqTitle;

  /// No description provided for @supportFaqPasswordQ.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れてしまいました'**
  String get supportFaqPasswordQ;

  /// No description provided for @supportFaqPasswordA.
  ///
  /// In ja, this message translates to:
  /// **'ログイン画面の「パスワードをお忘れですか？」からご登録のメールアドレスを入力すると、再設定用のメールが届きます。'**
  String get supportFaqPasswordA;

  /// No description provided for @supportFaqBiometricQ.
  ///
  /// In ja, this message translates to:
  /// **'アプリを開くたびにパスワードを入力したくありません'**
  String get supportFaqBiometricQ;

  /// No description provided for @supportFaqBiometricA.
  ///
  /// In ja, this message translates to:
  /// **'設定画面の「Face ID / 指紋でロック」をオンにすると、次回以降は生体認証だけでアプリを開けるようになります（端末が対応している場合）。'**
  String get supportFaqBiometricA;

  /// No description provided for @supportFaqGroupQ.
  ///
  /// In ja, this message translates to:
  /// **'グループに参加するにはどうすればいいですか？'**
  String get supportFaqGroupQ;

  /// No description provided for @supportFaqGroupA.
  ///
  /// In ja, this message translates to:
  /// **'グループのオーナーから共有された招待コードを、グループ画面右上のアイコンから入力してください。'**
  String get supportFaqGroupA;

  /// No description provided for @supportFaqWeatherQ.
  ///
  /// In ja, this message translates to:
  /// **'天気予報の地域を変更したい'**
  String get supportFaqWeatherQ;

  /// No description provided for @supportFaqWeatherA.
  ///
  /// In ja, this message translates to:
  /// **'設定画面の「お住まいの地域」から、国・都道府県（州・省）・市区町村の順に選択できます。天気の詳細はタップすると外部サイトで確認できます。'**
  String get supportFaqWeatherA;

  /// No description provided for @supportFaqNotificationQ.
  ///
  /// In ja, this message translates to:
  /// **'通知が届きません'**
  String get supportFaqNotificationQ;

  /// No description provided for @supportFaqNotificationA.
  ///
  /// In ja, this message translates to:
  /// **'設定画面で通知がオンになっているかご確認のうえ、お使いの端末・ブラウザ側の通知許可もあわせてご確認ください。'**
  String get supportFaqNotificationA;

  /// No description provided for @supportFaqLanguageQ.
  ///
  /// In ja, this message translates to:
  /// **'アプリの表示言語を変えたい'**
  String get supportFaqLanguageQ;

  /// No description provided for @supportFaqLanguageA.
  ///
  /// In ja, this message translates to:
  /// **'設定画面の「言語」から、日本語・English・한국어・中文の中から選べます。切り替えるとアプリ全体に反映されます。'**
  String get supportFaqLanguageA;

  /// No description provided for @supportFaqDeleteQ.
  ///
  /// In ja, this message translates to:
  /// **'アカウントやデータを削除したい'**
  String get supportFaqDeleteQ;

  /// No description provided for @supportFaqDeleteA.
  ///
  /// In ja, this message translates to:
  /// **'設定画面の「アカウント削除」から、ご自身で削除できます。ご不明な点があれば下記の連絡先までお問い合わせください。'**
  String get supportFaqDeleteA;

  /// No description provided for @supportAiTitle.
  ///
  /// In ja, this message translates to:
  /// **'AIに質問する'**
  String get supportAiTitle;

  /// No description provided for @supportAiDescription.
  ///
  /// In ja, this message translates to:
  /// **'上記のよくある質問に載っていない内容も、下の欄に入力すると自動で回答します（24時間対応）。'**
  String get supportAiDescription;

  /// No description provided for @supportAiGreeting.
  ///
  /// In ja, this message translates to:
  /// **'こんにちは！Kairosについて何でも聞いてください。'**
  String get supportAiGreeting;

  /// No description provided for @supportAiInputHint.
  ///
  /// In ja, this message translates to:
  /// **'質問を入力してください'**
  String get supportAiInputHint;

  /// No description provided for @supportAiSend.
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get supportAiSend;

  /// No description provided for @supportAiThinking.
  ///
  /// In ja, this message translates to:
  /// **'回答を作成しています…'**
  String get supportAiThinking;

  /// No description provided for @supportAiRetrying.
  ///
  /// In ja, this message translates to:
  /// **'混み合っています。再試行しています…（{attempt}/{max}）'**
  String supportAiRetrying(Object attempt, Object max);

  /// No description provided for @supportAiError.
  ///
  /// In ja, this message translates to:
  /// **'申し訳ありません、混み合っているため回答を取得できませんでした。少し時間をおいて再度お試しいただくか、下記のメールアドレスまでお問い合わせください。'**
  String get supportAiError;

  /// No description provided for @supportAiNotConfigured.
  ///
  /// In ja, this message translates to:
  /// **'AI質問機能は準備中です。下記のメールアドレスまでお問い合わせください。'**
  String get supportAiNotConfigured;

  /// No description provided for @supportContactTitle.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get supportContactTitle;

  /// No description provided for @supportContactBody.
  ///
  /// In ja, this message translates to:
  /// **'上記で解決しない場合や、不具合の報告・プライバシーに関するお問い合わせは、次のメールアドレスで受け付けます。'**
  String get supportContactBody;

  /// No description provided for @taskListTitle.
  ///
  /// In ja, this message translates to:
  /// **'タスク'**
  String get taskListTitle;

  /// No description provided for @taskListPending.
  ///
  /// In ja, this message translates to:
  /// **'未完了'**
  String get taskListPending;

  /// No description provided for @taskListDone.
  ///
  /// In ja, this message translates to:
  /// **'完了済み'**
  String get taskListDone;

  /// No description provided for @taskListEmptyPending.
  ///
  /// In ja, this message translates to:
  /// **'未完了のタスクはありません'**
  String get taskListEmptyPending;

  /// No description provided for @taskListEmptyDone.
  ///
  /// In ja, this message translates to:
  /// **'完了したタスクはありません'**
  String get taskListEmptyDone;

  /// No description provided for @taskListFromSchedule.
  ///
  /// In ja, this message translates to:
  /// **'予定の準備リストから追加'**
  String get taskListFromSchedule;

  /// No description provided for @taskDeleted.
  ///
  /// In ja, this message translates to:
  /// **'タスクを削除しました'**
  String get taskDeleted;

  /// No description provided for @taskFormTitleNew.
  ///
  /// In ja, this message translates to:
  /// **'タスクを作成'**
  String get taskFormTitleNew;

  /// No description provided for @taskFormTitleEdit.
  ///
  /// In ja, this message translates to:
  /// **'タスクを編集'**
  String get taskFormTitleEdit;

  /// No description provided for @taskFormTitleLabel.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get taskFormTitleLabel;

  /// No description provided for @taskFormTitleRequired.
  ///
  /// In ja, this message translates to:
  /// **'タイトルを入力してください'**
  String get taskFormTitleRequired;

  /// No description provided for @taskFormPriority.
  ///
  /// In ja, this message translates to:
  /// **'優先度'**
  String get taskFormPriority;

  /// No description provided for @taskFormPriorityLow.
  ///
  /// In ja, this message translates to:
  /// **'低'**
  String get taskFormPriorityLow;

  /// No description provided for @taskFormPriorityMedium.
  ///
  /// In ja, this message translates to:
  /// **'中'**
  String get taskFormPriorityMedium;

  /// No description provided for @taskFormPriorityHigh.
  ///
  /// In ja, this message translates to:
  /// **'高'**
  String get taskFormPriorityHigh;

  /// No description provided for @taskFormDueDate.
  ///
  /// In ja, this message translates to:
  /// **'期限'**
  String get taskFormDueDate;

  /// No description provided for @taskFormDueDateNotSet.
  ///
  /// In ja, this message translates to:
  /// **'設定なし'**
  String get taskFormDueDateNotSet;

  /// No description provided for @scheduleDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'予定の詳細'**
  String get scheduleDetailTitle;

  /// No description provided for @scheduleDeleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'予定を削除しますか？'**
  String get scheduleDeleteConfirmTitle;

  /// No description provided for @scheduleDeleteConfirmBody.
  ///
  /// In ja, this message translates to:
  /// **'削除してもすぐ後なら元に戻せます。'**
  String get scheduleDeleteConfirmBody;

  /// No description provided for @scheduleDeleted.
  ///
  /// In ja, this message translates to:
  /// **'予定を削除しました'**
  String get scheduleDeleted;

  /// No description provided for @scheduleAllDaySuffix.
  ///
  /// In ja, this message translates to:
  /// **'(終日)'**
  String get scheduleAllDaySuffix;

  /// No description provided for @scheduleParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者 {count}人'**
  String scheduleParticipants(Object count);

  /// No description provided for @scheduleReminderNone.
  ///
  /// In ja, this message translates to:
  /// **'通知しない'**
  String get scheduleReminderNone;

  /// No description provided for @scheduleReminderBefore.
  ///
  /// In ja, this message translates to:
  /// **'{minutes}分前に通知'**
  String scheduleReminderBefore(Object minutes);

  /// No description provided for @scheduleCouldNotOpenMap.
  ///
  /// In ja, this message translates to:
  /// **'地図を開けませんでした'**
  String get scheduleCouldNotOpenMap;

  /// No description provided for @scheduleFormTitleNew.
  ///
  /// In ja, this message translates to:
  /// **'予定を作成'**
  String get scheduleFormTitleNew;

  /// No description provided for @scheduleFormTitleEdit.
  ///
  /// In ja, this message translates to:
  /// **'予定を編集'**
  String get scheduleFormTitleEdit;

  /// No description provided for @scheduleFormTitleLabel.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get scheduleFormTitleLabel;

  /// No description provided for @scheduleFormTitleRequired.
  ///
  /// In ja, this message translates to:
  /// **'タイトルを入力してください'**
  String get scheduleFormTitleRequired;

  /// No description provided for @scheduleFormAllDay.
  ///
  /// In ja, this message translates to:
  /// **'終日'**
  String get scheduleFormAllDay;

  /// No description provided for @scheduleFormStart.
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get scheduleFormStart;

  /// No description provided for @scheduleFormEnd.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get scheduleFormEnd;

  /// No description provided for @scheduleFormEndBeforeStart.
  ///
  /// In ja, this message translates to:
  /// **'終了時刻は開始時刻より後にしてください'**
  String get scheduleFormEndBeforeStart;

  /// No description provided for @scheduleFormLocation.
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get scheduleFormLocation;

  /// No description provided for @scheduleFormNotes.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get scheduleFormNotes;

  /// No description provided for @scheduleFormColor.
  ///
  /// In ja, this message translates to:
  /// **'色'**
  String get scheduleFormColor;

  /// No description provided for @scheduleFormNotification.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get scheduleFormNotification;

  /// No description provided for @scheduleFormReminderNone.
  ///
  /// In ja, this message translates to:
  /// **'通知しない'**
  String get scheduleFormReminderNone;

  /// No description provided for @scheduleFormReminder5.
  ///
  /// In ja, this message translates to:
  /// **'5分前'**
  String get scheduleFormReminder5;

  /// No description provided for @scheduleFormReminder15.
  ///
  /// In ja, this message translates to:
  /// **'15分前'**
  String get scheduleFormReminder15;

  /// No description provided for @scheduleFormReminder30.
  ///
  /// In ja, this message translates to:
  /// **'30分前'**
  String get scheduleFormReminder30;

  /// No description provided for @scheduleFormReminder60.
  ///
  /// In ja, this message translates to:
  /// **'1時間前'**
  String get scheduleFormReminder60;

  /// No description provided for @scheduleFormReminder1440.
  ///
  /// In ja, this message translates to:
  /// **'1日前'**
  String get scheduleFormReminder1440;

  /// No description provided for @scheduleFormCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー'**
  String get scheduleFormCalendar;

  /// No description provided for @scheduleFormCalendarHint.
  ///
  /// In ja, this message translates to:
  /// **'ホーム画面のフィルターで表示/非表示を切り替えるための分類です'**
  String get scheduleFormCalendarHint;

  /// No description provided for @scheduleFormGroupSuffix.
  ///
  /// In ja, this message translates to:
  /// **'（グループ）'**
  String get scheduleFormGroupSuffix;

  /// No description provided for @scheduleFormShareWith.
  ///
  /// In ja, this message translates to:
  /// **'共有する相手'**
  String get scheduleFormShareWith;

  /// No description provided for @scheduleFormShareWithHint.
  ///
  /// In ja, this message translates to:
  /// **'グループのメンバーの中から、この予定を共有する人だけを選べます'**
  String get scheduleFormShareWithHint;

  /// No description provided for @scheduleFormNoCandidates.
  ///
  /// In ja, this message translates to:
  /// **'共有できる相手がいません。まずグループでメンバーを増やしてください。'**
  String get scheduleFormNoCandidates;

  /// No description provided for @scheduleFormLoadingName.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get scheduleFormLoadingName;

  /// No description provided for @scheduleFormPrepDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'準備するものはありますか？'**
  String get scheduleFormPrepDialogTitle;

  /// No description provided for @scheduleFormPrepDialogSkip.
  ///
  /// In ja, this message translates to:
  /// **'追加しない'**
  String get scheduleFormPrepDialogSkip;

  /// No description provided for @scheduleFormPrepDialogAdd.
  ///
  /// In ja, this message translates to:
  /// **'タスクに追加'**
  String get scheduleFormPrepDialogAdd;

  /// No description provided for @categoryPersonal.
  ///
  /// In ja, this message translates to:
  /// **'個人の予定'**
  String get categoryPersonal;

  /// No description provided for @categoryWork.
  ///
  /// In ja, this message translates to:
  /// **'仕事用'**
  String get categoryWork;

  /// No description provided for @categoryPartner.
  ///
  /// In ja, this message translates to:
  /// **'彼女・彼氏用'**
  String get categoryPartner;

  /// No description provided for @categoryFamily.
  ///
  /// In ja, this message translates to:
  /// **'家族'**
  String get categoryFamily;

  /// No description provided for @categoryFriend.
  ///
  /// In ja, this message translates to:
  /// **'友人'**
  String get categoryFriend;

  /// No description provided for @categoryOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get categoryOther;

  /// No description provided for @calendarTitle.
  ///
  /// In ja, this message translates to:
  /// **'Kairos'**
  String get calendarTitle;

  /// No description provided for @calendarTagline.
  ///
  /// In ja, this message translates to:
  /// **'大切な瞬間の共有'**
  String get calendarTagline;

  /// No description provided for @calendarViewList.
  ///
  /// In ja, this message translates to:
  /// **'一覧で表示'**
  String get calendarViewList;

  /// No description provided for @calendarViewCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーで表示'**
  String get calendarViewCalendar;

  /// No description provided for @calendarFilterTooltip.
  ///
  /// In ja, this message translates to:
  /// **'表示するカレンダーを選ぶ'**
  String get calendarFilterTooltip;

  /// No description provided for @calendarFilterTitle.
  ///
  /// In ja, this message translates to:
  /// **'表示するカレンダー'**
  String get calendarFilterTitle;

  /// No description provided for @calendarFilterClose.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get calendarFilterClose;

  /// No description provided for @calendarMonthPickerTitle.
  ///
  /// In ja, this message translates to:
  /// **'年月を選択'**
  String get calendarMonthPickerTitle;

  /// No description provided for @calendarMonthPickerYear.
  ///
  /// In ja, this message translates to:
  /// **'{year}年'**
  String calendarMonthPickerYear(Object year);

  /// No description provided for @calendarMonthPickerMonth.
  ///
  /// In ja, this message translates to:
  /// **'{month}月'**
  String calendarMonthPickerMonth(Object month);

  /// No description provided for @calendarMonthPickerGo.
  ///
  /// In ja, this message translates to:
  /// **'移動'**
  String get calendarMonthPickerGo;

  /// No description provided for @calendarFormatMonth.
  ///
  /// In ja, this message translates to:
  /// **'月'**
  String get calendarFormatMonth;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In ja, this message translates to:
  /// **'週'**
  String get calendarFormatWeek;

  /// No description provided for @calendarNoScheduleThisDay.
  ///
  /// In ja, this message translates to:
  /// **'この日の予定はありません'**
  String get calendarNoScheduleThisDay;

  /// No description provided for @calendarNoUpcoming.
  ///
  /// In ja, this message translates to:
  /// **'今後の予定はありません'**
  String get calendarNoUpcoming;

  /// No description provided for @calendarLoadError.
  ///
  /// In ja, this message translates to:
  /// **'予定の読み込みに失敗しました'**
  String get calendarLoadError;

  /// No description provided for @calendarWeatherLine.
  ///
  /// In ja, this message translates to:
  /// **'最高{max}° / 最低{min}°'**
  String calendarWeatherLine(Object max, Object min);

  /// No description provided for @calendarWeatherPrecipitation.
  ///
  /// In ja, this message translates to:
  /// **' / 降水確率{percent}%'**
  String calendarWeatherPrecipitation(Object percent);

  /// No description provided for @calendarAllDay.
  ///
  /// In ja, this message translates to:
  /// **'終日'**
  String get calendarAllDay;

  /// No description provided for @calendarBirthdaySuffix.
  ///
  /// In ja, this message translates to:
  /// **'{name}の誕生日'**
  String calendarBirthdaySuffix(Object name);

  /// No description provided for @calendarChristmasEve.
  ///
  /// In ja, this message translates to:
  /// **'クリスマスイブ'**
  String get calendarChristmasEve;

  /// No description provided for @calendarChristmas.
  ///
  /// In ja, this message translates to:
  /// **'クリスマス'**
  String get calendarChristmas;

  /// No description provided for @calendarNewYearsEve.
  ///
  /// In ja, this message translates to:
  /// **'大晦日'**
  String get calendarNewYearsEve;

  /// No description provided for @calendarMothersDay.
  ///
  /// In ja, this message translates to:
  /// **'母の日'**
  String get calendarMothersDay;

  /// No description provided for @calendarFathersDay.
  ///
  /// In ja, this message translates to:
  /// **'父の日'**
  String get calendarFathersDay;

  /// No description provided for @calendarVernalEquinox.
  ///
  /// In ja, this message translates to:
  /// **'春分の日'**
  String get calendarVernalEquinox;

  /// No description provided for @calendarAutumnalEquinox.
  ///
  /// In ja, this message translates to:
  /// **'秋分の日'**
  String get calendarAutumnalEquinox;

  /// No description provided for @groupListTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループ'**
  String get groupListTitle;

  /// No description provided for @groupListEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだグループがありません'**
  String get groupListEmpty;

  /// No description provided for @groupListMembers.
  ///
  /// In ja, this message translates to:
  /// **'メンバー {count}人'**
  String groupListMembers(Object count);

  /// No description provided for @groupJoinTooltip.
  ///
  /// In ja, this message translates to:
  /// **'コードでグループに参加'**
  String get groupJoinTooltip;

  /// No description provided for @groupFormTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループを作成'**
  String get groupFormTitle;

  /// No description provided for @groupFormNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループ名'**
  String get groupFormNameLabel;

  /// No description provided for @groupFormNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'グループ名を入力してください'**
  String get groupFormNameRequired;

  /// No description provided for @groupFormCreateButton.
  ///
  /// In ja, this message translates to:
  /// **'作成する'**
  String get groupFormCreateButton;

  /// No description provided for @groupJoinTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループに参加'**
  String get groupJoinTitle;

  /// No description provided for @groupJoinInstructions.
  ///
  /// In ja, this message translates to:
  /// **'グループのオーナーから共有された招待コードを入力してください。'**
  String get groupJoinInstructions;

  /// No description provided for @groupJoinCodeLabel.
  ///
  /// In ja, this message translates to:
  /// **'招待コード'**
  String get groupJoinCodeLabel;

  /// No description provided for @groupJoinConfirmButton.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get groupJoinConfirmButton;

  /// No description provided for @groupJoinNotFound.
  ///
  /// In ja, this message translates to:
  /// **'コードが見つかりませんでした。入力内容をご確認ください'**
  String get groupJoinNotFound;

  /// No description provided for @groupJoinConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'この地域でよろしいですか？'**
  String get groupJoinConfirmTitle;

  /// No description provided for @groupJoinMembers.
  ///
  /// In ja, this message translates to:
  /// **'メンバー {count}人'**
  String groupJoinMembers(Object count);

  /// No description provided for @groupJoinAlreadyMember.
  ///
  /// In ja, this message translates to:
  /// **'すでにこのグループのメンバーです'**
  String get groupJoinAlreadyMember;

  /// No description provided for @groupJoinButton.
  ///
  /// In ja, this message translates to:
  /// **'このグループに参加する'**
  String get groupJoinButton;

  /// No description provided for @groupJoinFailed.
  ///
  /// In ja, this message translates to:
  /// **'参加に失敗しました。時間をおいて再度お試しください'**
  String get groupJoinFailed;

  /// No description provided for @groupDetailInviteCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コード'**
  String get groupDetailInviteCode;

  /// No description provided for @groupDetailInviteCodeCopied.
  ///
  /// In ja, this message translates to:
  /// **'招待コードをコピーしました'**
  String get groupDetailInviteCodeCopied;

  /// No description provided for @groupDetailMembers.
  ///
  /// In ja, this message translates to:
  /// **'メンバー'**
  String get groupDetailMembers;

  /// No description provided for @groupDetailChat.
  ///
  /// In ja, this message translates to:
  /// **'トーク'**
  String get groupDetailChat;

  /// No description provided for @groupDeleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループを削除しますか？'**
  String get groupDeleteConfirmTitle;

  /// No description provided for @groupDeleteConfirmBody.
  ///
  /// In ja, this message translates to:
  /// **'削除してもすぐ後なら元に戻せます。'**
  String get groupDeleteConfirmBody;

  /// No description provided for @groupDeleted.
  ///
  /// In ja, this message translates to:
  /// **'グループを削除しました'**
  String get groupDeleted;

  /// No description provided for @groupChatTitle.
  ///
  /// In ja, this message translates to:
  /// **'{name} のトーク'**
  String groupChatTitle(Object name);

  /// No description provided for @groupChatEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだメッセージはありません'**
  String get groupChatEmpty;

  /// No description provided for @groupChatInputHint.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを入力'**
  String get groupChatInputHint;

  /// No description provided for @groupChatStampTooltip.
  ///
  /// In ja, this message translates to:
  /// **'スタンプ'**
  String get groupChatStampTooltip;

  /// No description provided for @anniversaryListTitle.
  ///
  /// In ja, this message translates to:
  /// **'大切な記念日'**
  String get anniversaryListTitle;

  /// No description provided for @anniversaryListEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだ記念日が登録されていません'**
  String get anniversaryListEmpty;

  /// No description provided for @anniversaryListYearly.
  ///
  /// In ja, this message translates to:
  /// **'毎年 {month}月{day}日'**
  String anniversaryListYearly(Object month, Object day);

  /// No description provided for @anniversaryFormTitleNew.
  ///
  /// In ja, this message translates to:
  /// **'記念日を追加'**
  String get anniversaryFormTitleNew;

  /// No description provided for @anniversaryFormTitleEdit.
  ///
  /// In ja, this message translates to:
  /// **'記念日を編集'**
  String get anniversaryFormTitleEdit;

  /// No description provided for @anniversaryFormNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'名前（例：結婚記念日、誕生日）'**
  String get anniversaryFormNameLabel;

  /// No description provided for @anniversaryFormNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'名前を入力してください'**
  String get anniversaryFormNameRequired;

  /// No description provided for @anniversaryFormDate.
  ///
  /// In ja, this message translates to:
  /// **'日付（毎年）'**
  String get anniversaryFormDate;

  /// No description provided for @anniversaryFormDateValue.
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日'**
  String anniversaryFormDateValue(Object month, Object day);

  /// No description provided for @anniversaryFormDatePickerHelp.
  ///
  /// In ja, this message translates to:
  /// **'月日を選択（年は使いません）'**
  String get anniversaryFormDatePickerHelp;

  /// No description provided for @anniversaryFormNotifyHint.
  ///
  /// In ja, this message translates to:
  /// **'毎年この日の朝9時に通知します'**
  String get anniversaryFormNotifyHint;

  /// No description provided for @anniversaryDeleted.
  ///
  /// In ja, this message translates to:
  /// **'記念日を削除しました'**
  String get anniversaryDeleted;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
