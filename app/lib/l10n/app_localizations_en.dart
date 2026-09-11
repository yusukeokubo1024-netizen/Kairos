// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appLocked => 'Kairos is locked';

  @override
  String get authenticate => 'Authenticate';

  @override
  String get biometricAuthReason => 'Authentication is required to open Kairos';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabGroups => 'Groups';

  @override
  String get tabSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get loginTagline => 'Sharing a precious moment';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginEmailRequired => 'Please enter your email address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginSignUpLink => 'Sign up';

  @override
  String get loginErrorWrongCredentials => 'Incorrect email or password';

  @override
  String get loginErrorInvalidEmail => 'Invalid email address format';

  @override
  String get loginErrorUserDisabled => 'This account has been disabled';

  @override
  String get loginErrorTooManyRequests =>
      'Too many login attempts. Please wait a while before trying again';

  @override
  String get loginErrorGeneric => 'Sign-in failed. Please try again later';

  @override
  String get signUpTitle => 'Sign up';

  @override
  String get signUpNameLabel => 'Display name';

  @override
  String get signUpNameRequired => 'Please enter a display name';

  @override
  String get signUpPasswordLabel => 'Password (6+ characters)';

  @override
  String get signUpPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get signUpButton => 'Create account';

  @override
  String get signUpErrorEmailInUse =>
      'This email address is already registered';

  @override
  String get signUpErrorGeneric => 'Sign-up failed. Please try again later';

  @override
  String get signUpBiometricOfferTitle => 'Trust this device?';

  @override
  String get signUpBiometricOfferBody =>
      'Next time, you\'ll be able to log in with just Face ID / fingerprint — no email or password needed.';

  @override
  String get signUpBiometricOfferSkip => 'Set up later';

  @override
  String get signUpBiometricOfferEnable => 'Enable';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordInstructions =>
      'Enter your registered email address. We\'ll send you a reset link.';

  @override
  String get resetPasswordSuccess => 'Password reset email sent';

  @override
  String get resetPasswordError =>
      'Failed to send. Please check your email address';

  @override
  String get resetPasswordButton => 'Send';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDisplayNameUnset => '(No display name set)';

  @override
  String get settingsEmailUnverified => 'Email address not verified';

  @override
  String get settingsResendVerification => 'Resend';

  @override
  String get settingsEmailVerificationSent => 'Verification email sent';

  @override
  String get settingsEditDisplayName => 'Edit display name';

  @override
  String settingsDisplayNameSaved(Object name) {
    return 'Display name changed to \"$name\"';
  }

  @override
  String settingsDisplayNameSaveFailed(Object error) {
    return 'Failed to save display name: $error';
  }

  @override
  String get settingsBirthday => 'Birthday';

  @override
  String get settingsBirthdayPick => 'Select your birthday';

  @override
  String settingsBirthdayValue(Object month, Object day) {
    return '$month/$day';
  }

  @override
  String get settingsBirthdayHint =>
      'Once set, your birthday will show every year on your calendar and on your friends\'/family\'s calendars too';

  @override
  String get settingsWeatherLocation => 'Your location (weather forecast)';

  @override
  String get settingsWeatherLocationTitle => 'Your location';

  @override
  String get settingsWeatherLocationCountryTitle => 'Select country/region';

  @override
  String get settingsWeatherLocationCountrySearchHint =>
      'Search by country name';

  @override
  String get settingsWeatherLocationCountryNotFound => 'No matches found';

  @override
  String get settingsWeatherLocationPrefectureTitle => 'Select region';

  @override
  String get settingsWeatherLocationPrefectureSearchHint =>
      'Search by region name';

  @override
  String get settingsWeatherLocationCitySearchHint => 'Search by place name';

  @override
  String get settingsWeatherLocationManualEntry => 'Other (enter manually)';

  @override
  String get settingsWeatherLocationHint =>
      'e.g. Shibuya, Yokohama, Sapporo, New York';

  @override
  String get settingsWeatherLocationHelper =>
      'Search by place name alone, without \"city\"/\"ward\" etc.';

  @override
  String get settingsWeatherLocationConfirmTitle => 'Is this the right place?';

  @override
  String settingsWeatherLocationSaved(Object place) {
    return '$place has been set';
  }

  @override
  String get settingsWeatherLocationNotFound => 'Location not found';

  @override
  String settingsWeatherLocationSearchFailed(Object error) {
    return 'Location search failed: $error';
  }

  @override
  String settingsWeatherLocationSaveFailed(Object error) {
    return 'Failed to save location: $error';
  }

  @override
  String get settingsAccountLinking => 'Account linking';

  @override
  String get settingsGoogleLink => 'Link Google account';

  @override
  String get settingsGoogleLinked => 'Linked';

  @override
  String get settingsGoogleNotLinked => 'Not linked';

  @override
  String get settingsGoogleLinkSuccess => 'Linked your Google account';

  @override
  String get settingsGoogleLinkInUse =>
      'This Google account is already linked to another Kairos account';

  @override
  String get settingsGoogleLinkFailed => 'Failed to link Google account';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Reminders for schedules, tasks, and anniversaries';

  @override
  String get settingsBiometricLock => 'Lock with Face ID / fingerprint';

  @override
  String get settingsBiometricLockSubtitle =>
      'Require authentication every time you open the app';

  @override
  String get settingsAnniversaries => 'Important anniversaries';

  @override
  String get settingsAnniversariesSubtitle =>
      'Register anniversaries you\'d like a yearly reminder for';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsTrash => 'Trash';

  @override
  String get settingsCouldNotOpenPage => 'Couldn\'t open the page';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'Your profile and all schedules, tasks, and groups you own will be deleted. This can\'t be undone. If you own any shared groups, please remove other members first.';

  @override
  String get settingsDeleteAccountConfirmButton => 'Delete';

  @override
  String get settingsDeleteAccountRequiresRecentLogin =>
      'For security, please log out, log back in, and try again';

  @override
  String get settingsDeleteAccountFailed => 'Failed to delete account';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportFaqTitle => 'FAQ';

  @override
  String get supportFaqPasswordQ => 'I forgot my password';

  @override
  String get supportFaqPasswordA =>
      'On the login screen, tap \"Forgot your password?\" and enter your registered email address — a reset link will be sent to you.';

  @override
  String get supportFaqBiometricQ =>
      'I don\'t want to type my password every time I open the app';

  @override
  String get supportFaqBiometricA =>
      'Turn on \"Lock with Face ID / fingerprint\" in Settings, and from then on you can open the app with just biometrics (if your device supports it).';

  @override
  String get supportFaqGroupQ => 'How do I join a group?';

  @override
  String get supportFaqGroupA =>
      'Enter the invite code shared by the group\'s owner, using the icon in the top right of the Groups screen.';

  @override
  String get supportFaqWeatherQ => 'I want to change my weather location';

  @override
  String get supportFaqWeatherA =>
      'In Settings, go to \"Your location\" and choose country → prefecture/state/province → city, in order. Tap the weather summary for more detail on an external site.';

  @override
  String get supportFaqNotificationQ => 'I\'m not getting notifications';

  @override
  String get supportFaqNotificationA =>
      'Check that notifications are turned on in Settings, and also check your device/browser\'s notification permissions.';

  @override
  String get supportFaqLanguageQ =>
      'I want to change the app\'s display language';

  @override
  String get supportFaqLanguageA =>
      'Go to \"Language\" in Settings and choose from 日本語, English, 한국어, or 中文. Switching applies across the whole app.';

  @override
  String get supportFaqDeleteQ => 'I want to delete my account or data';

  @override
  String get supportFaqDeleteA =>
      'You can delete it yourself from \"Delete account\" in Settings. Contact us below if you have any questions.';

  @override
  String get supportAiTitle => 'Ask AI';

  @override
  String get supportAiDescription =>
      'Anything not covered by the FAQ above can be typed into the box below for an automatic answer (available 24/7).';

  @override
  String get supportAiGreeting => 'Hi! Ask me anything about Kairos.';

  @override
  String get supportAiInputHint => 'Type your question';

  @override
  String get supportAiSend => 'Send';

  @override
  String get supportAiThinking => 'Thinking…';

  @override
  String supportAiRetrying(Object attempt, Object max) {
    return 'Busy right now — retrying… ($attempt/$max)';
  }

  @override
  String get supportAiError =>
      'Sorry, we couldn\'t get an answer due to high demand. Please try again shortly, or contact us at the email address below.';

  @override
  String get supportAiNotConfigured =>
      'The AI question feature isn\'t set up yet. Please contact us at the email address below.';

  @override
  String get supportContactTitle => 'Contact';

  @override
  String get supportContactBody =>
      'If the above doesn\'t resolve your question, or to report a bug or ask about privacy, reach us at the email address below.';

  @override
  String get trashTitle => 'Trash';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashRestore => 'Restore';

  @override
  String get trashDeleteForever => 'Delete forever';

  @override
  String get trashRestored => 'Restored';

  @override
  String trashDeletedOn(Object collection, Object date) {
    return '$collection · deleted $date';
  }

  @override
  String get trashCollectionSchedule => 'Schedule';

  @override
  String get trashCollectionTask => 'Task';

  @override
  String get trashCollectionAnniversary => 'Anniversary';

  @override
  String get trashCollectionGroup => 'Group';

  @override
  String get taskListTitle => 'Tasks';

  @override
  String get taskListPending => 'Pending';

  @override
  String get taskListDone => 'Done';

  @override
  String get taskListEmptyPending => 'No pending tasks';

  @override
  String get taskListEmptyDone => 'No completed tasks';

  @override
  String get taskListFromSchedule => 'Added from a schedule\'s prep list';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get taskFormTitleNew => 'New task';

  @override
  String get taskFormTitleEdit => 'Edit task';

  @override
  String get taskFormTitleLabel => 'Title';

  @override
  String get taskFormTitleRequired => 'Please enter a title';

  @override
  String get taskFormPriority => 'Priority';

  @override
  String get taskFormPriorityLow => 'Low';

  @override
  String get taskFormPriorityMedium => 'Medium';

  @override
  String get taskFormPriorityHigh => 'High';

  @override
  String get taskFormDueDate => 'Due date';

  @override
  String get taskFormDueDateNotSet => 'Not set';

  @override
  String get scheduleDetailTitle => 'Schedule details';

  @override
  String get scheduleDeleteConfirmTitle => 'Delete this schedule?';

  @override
  String get scheduleDeleteConfirmBody =>
      'You can undo this right after deleting.';

  @override
  String get scheduleDeleted => 'Schedule deleted';

  @override
  String get scheduleAllDaySuffix => '(all day)';

  @override
  String scheduleParticipants(Object count) {
    return '$count participant(s)';
  }

  @override
  String get scheduleReminderNone => 'No reminder';

  @override
  String scheduleReminderBefore(Object minutes) {
    return 'Reminder $minutes min before';
  }

  @override
  String get scheduleCouldNotOpenMap => 'Couldn\'t open the map';

  @override
  String get scheduleFormTitleNew => 'New schedule';

  @override
  String get scheduleFormTitleEdit => 'Edit schedule';

  @override
  String get scheduleFormTitleLabel => 'Title';

  @override
  String get scheduleFormTitleRequired => 'Please enter a title';

  @override
  String get scheduleFormAllDay => 'All day';

  @override
  String get scheduleFormStart => 'Start';

  @override
  String get scheduleFormEnd => 'End';

  @override
  String get scheduleFormEndBeforeStart =>
      'End time must be after the start time';

  @override
  String get scheduleFormLocation => 'Location';

  @override
  String get scheduleFormNotes => 'Notes';

  @override
  String get scheduleFormColor => 'Color';

  @override
  String get scheduleFormNotification => 'Notification';

  @override
  String get scheduleFormReminderNone => 'No reminder';

  @override
  String get scheduleFormReminder5 => '5 min before';

  @override
  String get scheduleFormReminder15 => '15 min before';

  @override
  String get scheduleFormReminder30 => '30 min before';

  @override
  String get scheduleFormReminder60 => '1 hour before';

  @override
  String get scheduleFormReminder1440 => '1 day before';

  @override
  String get scheduleFormCalendar => 'Calendar';

  @override
  String get scheduleFormCalendarHint =>
      'This category is used to show/hide it via the filter on the home screen';

  @override
  String get scheduleFormGroupSuffix => ' (group)';

  @override
  String get scheduleFormShareWith => 'Share with';

  @override
  String get scheduleFormShareWithHint =>
      'Choose who to share this schedule with, from your group members';

  @override
  String get scheduleFormNoCandidates =>
      'No one to share with yet. Add members to a group first.';

  @override
  String get scheduleFormLoadingName => 'Loading...';

  @override
  String get scheduleFormPrepDialogTitle => 'Anything to prepare?';

  @override
  String get scheduleFormPrepDialogSkip => 'Don\'t add';

  @override
  String get scheduleFormPrepDialogAdd => 'Add to tasks';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryPartner => 'Partner';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryFriend => 'Friends';

  @override
  String get categoryOther => 'Other';

  @override
  String get calendarTitle => 'Kairos';

  @override
  String get calendarTagline => 'Sharing a precious moment';

  @override
  String get calendarViewList => 'Show as list';

  @override
  String get calendarViewCalendar => 'Show as calendar';

  @override
  String get calendarFilterTooltip => 'Choose which calendars to show';

  @override
  String get calendarFilterTitle => 'Calendars to show';

  @override
  String get calendarFilterClose => 'Close';

  @override
  String get calendarMonthPickerTitle => 'Jump to month';

  @override
  String calendarMonthPickerYear(Object year) {
    return '$year';
  }

  @override
  String calendarMonthPickerMonth(Object month) {
    return '$month';
  }

  @override
  String get calendarMonthPickerGo => 'Go';

  @override
  String get calendarFormatMonth => 'Month';

  @override
  String get calendarFormatWeek => 'Week';

  @override
  String get calendarNoScheduleThisDay => 'No schedules on this day';

  @override
  String get calendarNoUpcoming => 'No upcoming schedules';

  @override
  String get calendarLoadError => 'Failed to load schedules';

  @override
  String calendarWeatherLine(Object max, Object min) {
    return 'High $max° / Low $min°';
  }

  @override
  String calendarWeatherPrecipitation(Object percent) {
    return ' / $percent% rain';
  }

  @override
  String get calendarAllDay => 'All day';

  @override
  String calendarBirthdaySuffix(Object name) {
    return '$name\'s birthday';
  }

  @override
  String get calendarChristmasEve => 'Christmas Eve';

  @override
  String get calendarChristmas => 'Christmas';

  @override
  String get calendarNewYearsEve => 'New Year\'s Eve';

  @override
  String get calendarMothersDay => 'Mother\'s Day';

  @override
  String get calendarFathersDay => 'Father\'s Day';

  @override
  String get calendarVernalEquinox => 'Vernal Equinox Day';

  @override
  String get calendarAutumnalEquinox => 'Autumnal Equinox Day';

  @override
  String get groupListTitle => 'Groups';

  @override
  String get groupListEmpty => 'No groups yet';

  @override
  String groupListMembers(Object count) {
    return '$count member(s)';
  }

  @override
  String get groupJoinTooltip => 'Join a group with a code';

  @override
  String get groupFormTitle => 'Create a group';

  @override
  String get groupFormNameLabel => 'Group name';

  @override
  String get groupFormNameRequired => 'Please enter a group name';

  @override
  String get groupFormCreateButton => 'Create';

  @override
  String get groupJoinTitle => 'Join a group';

  @override
  String get groupJoinInstructions =>
      'Enter the invite code shared by the group\'s owner.';

  @override
  String get groupJoinCodeLabel => 'Invite code';

  @override
  String get groupJoinConfirmButton => 'Check';

  @override
  String get groupJoinNotFound =>
      'Code not found. Please check what you entered';

  @override
  String get groupJoinConfirmTitle => 'Is this the right group?';

  @override
  String groupJoinMembers(Object count) {
    return '$count member(s)';
  }

  @override
  String get groupJoinAlreadyMember => 'You\'re already a member of this group';

  @override
  String get groupJoinButton => 'Join this group';

  @override
  String get groupJoinFailed => 'Failed to join. Please try again later';

  @override
  String get groupDetailInviteCode => 'Invite code';

  @override
  String get groupDetailInviteCodeCopied => 'Invite code copied';

  @override
  String get groupDetailMembers => 'Members';

  @override
  String get groupDetailChat => 'Chat';

  @override
  String get groupDeleteConfirmTitle => 'Delete this group?';

  @override
  String get groupDeleteConfirmBody =>
      'You can undo this right after deleting.';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String groupChatTitle(Object name) {
    return '$name chat';
  }

  @override
  String get groupChatEmpty => 'No messages yet';

  @override
  String get groupChatInputHint => 'Type a message';

  @override
  String get groupChatStampTooltip => 'Stamps';

  @override
  String get anniversaryListTitle => 'Important anniversaries';

  @override
  String get anniversaryListEmpty => 'No anniversaries registered yet';

  @override
  String anniversaryListYearly(Object month, Object day) {
    return 'Every $month/$day';
  }

  @override
  String get anniversaryFormTitleNew => 'Add an anniversary';

  @override
  String get anniversaryFormTitleEdit => 'Edit anniversary';

  @override
  String get anniversaryFormNameLabel => 'Name (e.g. anniversary, birthday)';

  @override
  String get anniversaryFormNameRequired => 'Please enter a name';

  @override
  String get anniversaryFormDate => 'Date (yearly)';

  @override
  String anniversaryFormDateValue(Object month, Object day) {
    return '$month/$day';
  }

  @override
  String get anniversaryFormDatePickerHelp =>
      'Pick the month and day (year is unused)';

  @override
  String get anniversaryFormNotifyHint =>
      'You\'ll get a notification at 9am on this day every year';

  @override
  String get anniversaryDeleted => 'Anniversary deleted';
}
