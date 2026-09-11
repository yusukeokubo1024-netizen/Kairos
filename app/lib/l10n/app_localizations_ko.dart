// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appLocked => 'Kairos가 잠겨 있습니다';

  @override
  String get authenticate => '인증하기';

  @override
  String get biometricAuthReason => 'Kairos를 열려면 인증이 필요합니다';

  @override
  String get tabHome => '홈';

  @override
  String get tabTasks => '할 일';

  @override
  String get tabGroups => '그룹';

  @override
  String get tabSettings => '설정';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDone => '완료';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonUndo => '실행 취소';

  @override
  String get commonEdit => '편집';

  @override
  String get commonAdd => '추가';

  @override
  String get commonNotSet => '설정 안 됨';

  @override
  String get loginTagline => '소중한 순간의 공유';

  @override
  String get loginEmailLabel => '이메일 주소';

  @override
  String get loginEmailRequired => '이메일 주소를 입력해 주세요';

  @override
  String get loginPasswordLabel => '비밀번호';

  @override
  String get loginPasswordRequired => '비밀번호를 입력해 주세요';

  @override
  String get loginButton => '로그인';

  @override
  String get loginForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get loginSignUpLink => '회원가입';

  @override
  String get loginErrorWrongCredentials => '이메일 또는 비밀번호가 올바르지 않습니다';

  @override
  String get loginErrorInvalidEmail => '이메일 주소 형식이 올바르지 않습니다';

  @override
  String get loginErrorUserDisabled => '이 계정은 사용이 중지되었습니다';

  @override
  String get loginErrorTooManyRequests => '로그인 시도 횟수가 너무 많습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get loginErrorGeneric => '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get signUpTitle => '회원가입';

  @override
  String get signUpNameLabel => '표시 이름';

  @override
  String get signUpNameRequired => '표시 이름을 입력해 주세요';

  @override
  String get signUpPasswordLabel => '비밀번호（6자 이상）';

  @override
  String get signUpPasswordTooShort => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get signUpButton => '계정 만들기';

  @override
  String get signUpErrorEmailInUse => '이미 등록된 이메일 주소입니다';

  @override
  String get signUpErrorGeneric => '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get signUpBiometricOfferTitle => '이 기기를 신뢰하시겠습니까?';

  @override
  String get signUpBiometricOfferBody =>
      '다음부터는 이메일과 비밀번호 없이 Face ID / 지문만으로 로그인할 수 있습니다.';

  @override
  String get signUpBiometricOfferSkip => '나중에 설정';

  @override
  String get signUpBiometricOfferEnable => '사용';

  @override
  String get resetPasswordTitle => '비밀번호 재설정';

  @override
  String get resetPasswordInstructions =>
      '가입한 이메일 주소를 입력해 주세요. 재설정 링크를 보내드립니다.';

  @override
  String get resetPasswordSuccess => '비밀번호 재설정 이메일을 보냈습니다';

  @override
  String get resetPasswordError => '전송에 실패했습니다. 이메일 주소를 확인해 주세요';

  @override
  String get resetPasswordButton => '보내기';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsDisplayNameUnset => '（표시 이름 미설정）';

  @override
  String get settingsEmailUnverified => '이메일 주소가 확인되지 않았습니다';

  @override
  String get settingsResendVerification => '재전송';

  @override
  String get settingsEmailVerificationSent => '확인 이메일을 다시 보냈습니다';

  @override
  String get settingsEditDisplayName => '표시 이름 편집';

  @override
  String settingsDisplayNameSaved(Object name) {
    return '표시 이름을 \"$name\"(으)로 변경했습니다';
  }

  @override
  String settingsDisplayNameSaveFailed(Object error) {
    return '표시 이름 저장 실패: $error';
  }

  @override
  String get settingsBirthday => '생년월일';

  @override
  String get settingsBirthdayPick => '생년월일 선택';

  @override
  String settingsBirthdayValue(Object month, Object day) {
    return '$month월 $day일';
  }

  @override
  String get settingsBirthdayHint =>
      '생년월일을 등록하면 매년 캘린더와 그룹 친구·가족의 캘린더에도 생일로 표시됩니다';

  @override
  String get settingsWeatherLocation => '거주 지역（날씨 예보）';

  @override
  String get settingsWeatherLocationTitle => '거주 지역';

  @override
  String get settingsWeatherLocationCountryTitle => '국가・지역 선택';

  @override
  String get settingsWeatherLocationCountrySearchHint => '국가명으로 검색';

  @override
  String get settingsWeatherLocationCountryNotFound => '검색 결과가 없습니다';

  @override
  String get settingsWeatherLocationPrefectureTitle => '지역 선택';

  @override
  String get settingsWeatherLocationPrefectureSearchHint => '지역 이름으로 검색';

  @override
  String get settingsWeatherLocationCitySearchHint => '지명으로 검색';

  @override
  String get settingsWeatherLocationManualEntry => '기타（직접 입력）';

  @override
  String get settingsWeatherLocationHint =>
      '예: Shibuya, Yokohama, Sapporo, New York';

  @override
  String get settingsWeatherLocationHelper =>
      '\"구\"、\"시\" 등을 붙이지 말고 지명만 입력해 검색해 주세요';

  @override
  String get settingsWeatherLocationConfirmTitle => '이 지역이 맞습니까?';

  @override
  String settingsWeatherLocationSaved(Object place) {
    return '$place(으)로 설정했습니다';
  }

  @override
  String get settingsWeatherLocationNotFound => '지역을 찾을 수 없습니다';

  @override
  String settingsWeatherLocationSearchFailed(Object error) {
    return '지역 검색에 실패했습니다: $error';
  }

  @override
  String settingsWeatherLocationSaveFailed(Object error) {
    return '지역 저장에 실패했습니다: $error';
  }

  @override
  String get settingsAccountLinking => '계정 연동';

  @override
  String get settingsGoogleLink => 'Google 계정 연동';

  @override
  String get settingsGoogleLinked => '연동됨';

  @override
  String get settingsGoogleNotLinked => '연동 안 됨';

  @override
  String get settingsGoogleLinkSuccess => 'Google 계정을 연동했습니다';

  @override
  String get settingsGoogleLinkInUse =>
      '이 Google 계정은 이미 다른 Kairos 계정에 연동되어 있습니다';

  @override
  String get settingsGoogleLinkFailed => 'Google 계정 연동에 실패했습니다';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsNotificationsSubtitle => '일정, 할 일, 기념일 알림';

  @override
  String get settingsBiometricLock => 'Face ID / 지문으로 잠금';

  @override
  String get settingsBiometricLockSubtitle => '앱을 열 때마다 인증을 요구합니다';

  @override
  String get settingsAnniversaries => '소중한 기념일';

  @override
  String get settingsAnniversariesSubtitle => '매년 알림을 받고 싶은 기념일을 등록하세요';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsTermsOfService => '이용약관';

  @override
  String get settingsSupport => '고객지원';

  @override
  String get settingsTrash => '휴지통';

  @override
  String get settingsCouldNotOpenPage => '페이지를 열 수 없습니다';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsDeleteAccount => '계정 삭제';

  @override
  String get settingsDeleteAccountConfirmTitle => '계정을 삭제하시겠습니까?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      '프로필과 본인이 소유한 모든 일정, 할 일, 그룹이 삭제됩니다. 이 작업은 되돌릴 수 없습니다. 공유 그룹을 소유하고 있다면 먼저 다른 멤버를 제거해 주세요.';

  @override
  String get settingsDeleteAccountConfirmButton => '삭제';

  @override
  String get settingsDeleteAccountRequiresRecentLogin =>
      '보안을 위해 로그아웃 후 다시 로그인하여 시도해 주세요';

  @override
  String get settingsDeleteAccountFailed => '계정 삭제에 실패했습니다';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get supportTitle => '지원';

  @override
  String get supportFaqTitle => '자주 묻는 질문';

  @override
  String get supportFaqPasswordQ => '비밀번호를 잊어버렸습니다';

  @override
  String get supportFaqPasswordA =>
      '로그인 화면의 \"비밀번호를 잊으셨나요?\"에서 등록된 이메일 주소를 입력하면 재설정 메일이 발송됩니다.';

  @override
  String get supportFaqBiometricQ => '앱을 열 때마다 비밀번호를 입력하고 싶지 않습니다';

  @override
  String get supportFaqBiometricA =>
      '설정 화면의 \"Face ID / 지문으로 잠금\"을 켜면, 다음부터는 생체 인증만으로 앱을 열 수 있습니다（기기가 지원하는 경우）。';

  @override
  String get supportFaqGroupQ => '그룹에 참여하려면 어떻게 해야 하나요?';

  @override
  String get supportFaqGroupA =>
      '그룹 화면 오른쪽 상단 아이콘에서, 그룹 소유자로부터 받은 초대 코드를 입력해 주세요.';

  @override
  String get supportFaqWeatherQ => '날씨 예보 지역을 변경하고 싶습니다';

  @override
  String get supportFaqWeatherA =>
      '설정 화면의 \"거주 지역\"에서 국가 → 도/주/성 → 시를 순서대로 선택할 수 있습니다. 날씨 요약을 탭하면 외부 사이트에서 자세히 볼 수 있습니다.';

  @override
  String get supportFaqNotificationQ => '알림이 오지 않습니다';

  @override
  String get supportFaqNotificationA =>
      '설정 화면에서 알림이 켜져 있는지 확인하고, 기기·브라우저의 알림 권한도 함께 확인해 주세요.';

  @override
  String get supportFaqLanguageQ => '앱 표시 언어를 바꾸고 싶습니다';

  @override
  String get supportFaqLanguageA =>
      '설정 화면의 \"언어\"에서 日本語・English・한국어・中文 중에서 선택할 수 있습니다. 전환하면 앱 전체에 반영됩니다.';

  @override
  String get supportFaqDeleteQ => '계정이나 데이터를 삭제하고 싶습니다';

  @override
  String get supportFaqDeleteA =>
      '설정 화면의 \"계정 삭제\"에서 직접 삭제할 수 있습니다. 궁금한 점이 있으면 아래 연락처로 문의해 주세요.';

  @override
  String get supportAiTitle => 'AI에게 질문하기';

  @override
  String get supportAiDescription =>
      '위 자주 묻는 질문에 없는 내용도 아래 입력란에 입력하면 자동으로 답변합니다（24시간 대응）。';

  @override
  String get supportAiGreeting => '안녕하세요! Kairos에 대해 무엇이든 물어보세요.';

  @override
  String get supportAiInputHint => '질문을 입력해 주세요';

  @override
  String get supportAiSend => '전송';

  @override
  String get supportAiThinking => '답변을 작성하고 있습니다…';

  @override
  String supportAiRetrying(Object attempt, Object max) {
    return '혼잡합니다. 다시 시도하고 있습니다…（$attempt/$max）';
  }

  @override
  String get supportAiError =>
      '죄송합니다, 혼잡하여 답변을 가져오지 못했습니다. 잠시 후 다시 시도하시거나 아래 이메일 주소로 문의해 주세요.';

  @override
  String get supportAiNotConfigured =>
      'AI 질문 기능은 아직 준비 중입니다. 아래 이메일 주소로 문의해 주세요.';

  @override
  String get supportContactTitle => '문의하기';

  @override
  String get supportContactBody =>
      '위 내용으로 해결되지 않거나, 오류 신고·개인정보 관련 문의는 아래 이메일 주소로 접수합니다.';

  @override
  String get trashTitle => '휴지통';

  @override
  String get trashEmpty => '휴지통이 비어 있습니다';

  @override
  String get trashRestore => '복원';

  @override
  String get trashDeleteForever => '영구 삭제';

  @override
  String get trashRestored => '복원되었습니다';

  @override
  String trashDeletedOn(Object collection, Object date) {
    return '$collection · $date에 삭제됨';
  }

  @override
  String get trashCollectionSchedule => '일정';

  @override
  String get trashCollectionTask => '할 일';

  @override
  String get trashCollectionAnniversary => '기념일';

  @override
  String get trashCollectionGroup => '그룹';

  @override
  String get taskListTitle => '할 일';

  @override
  String get taskListPending => '미완료';

  @override
  String get taskListDone => '완료';

  @override
  String get taskListEmptyPending => '미완료 할 일이 없습니다';

  @override
  String get taskListEmptyDone => '완료된 할 일이 없습니다';

  @override
  String get taskListFromSchedule => '일정의 준비 목록에서 추가됨';

  @override
  String get taskDeleted => '할 일을 삭제했습니다';

  @override
  String get taskFormTitleNew => '할 일 만들기';

  @override
  String get taskFormTitleEdit => '할 일 편집';

  @override
  String get taskFormTitleLabel => '제목';

  @override
  String get taskFormTitleRequired => '제목을 입력해 주세요';

  @override
  String get taskFormPriority => '우선순위';

  @override
  String get taskFormPriorityLow => '낮음';

  @override
  String get taskFormPriorityMedium => '보통';

  @override
  String get taskFormPriorityHigh => '높음';

  @override
  String get taskFormDueDate => '마감일';

  @override
  String get taskFormDueDateNotSet => '설정 안 됨';

  @override
  String get scheduleDetailTitle => '일정 상세';

  @override
  String get scheduleDeleteConfirmTitle => '일정을 삭제하시겠습니까?';

  @override
  String get scheduleDeleteConfirmBody => '삭제 직후라면 되돌릴 수 있습니다.';

  @override
  String get scheduleDeleted => '일정을 삭제했습니다';

  @override
  String get scheduleAllDaySuffix => '（종일）';

  @override
  String scheduleParticipants(Object count) {
    return '참가자 $count명';
  }

  @override
  String get scheduleReminderNone => '알림 없음';

  @override
  String scheduleReminderBefore(Object minutes) {
    return '$minutes분 전 알림';
  }

  @override
  String get scheduleCouldNotOpenMap => '지도를 열 수 없습니다';

  @override
  String get scheduleFormTitleNew => '일정 만들기';

  @override
  String get scheduleFormTitleEdit => '일정 편집';

  @override
  String get scheduleFormTitleLabel => '제목';

  @override
  String get scheduleFormTitleRequired => '제목을 입력해 주세요';

  @override
  String get scheduleFormAllDay => '종일';

  @override
  String get scheduleFormStart => '시작';

  @override
  String get scheduleFormEnd => '종료';

  @override
  String get scheduleFormEndBeforeStart => '종료 시각은 시작 시각보다 뒤여야 합니다';

  @override
  String get scheduleFormLocation => '장소';

  @override
  String get scheduleFormNotes => '메모';

  @override
  String get scheduleFormColor => '색상';

  @override
  String get scheduleFormNotification => '알림';

  @override
  String get scheduleFormReminderNone => '알림 없음';

  @override
  String get scheduleFormReminder5 => '5분 전';

  @override
  String get scheduleFormReminder15 => '15분 전';

  @override
  String get scheduleFormReminder30 => '30분 전';

  @override
  String get scheduleFormReminder60 => '1시간 전';

  @override
  String get scheduleFormReminder1440 => '1일 전';

  @override
  String get scheduleFormCalendar => '캘린더';

  @override
  String get scheduleFormCalendarHint => '홈 화면의 필터에서 표시/숨김을 전환하기 위한 분류입니다';

  @override
  String get scheduleFormGroupSuffix => '（그룹）';

  @override
  String get scheduleFormShareWith => '공유할 대상';

  @override
  String get scheduleFormShareWithHint => '그룹 멤버 중 이 일정을 공유할 사람만 선택할 수 있습니다';

  @override
  String get scheduleFormNoCandidates =>
      '공유할 수 있는 상대가 없습니다. 먼저 그룹에 멤버를 추가해 주세요.';

  @override
  String get scheduleFormLoadingName => '불러오는 중...';

  @override
  String get scheduleFormPrepDialogTitle => '준비할 것이 있나요?';

  @override
  String get scheduleFormPrepDialogSkip => '추가하지 않음';

  @override
  String get scheduleFormPrepDialogAdd => '할 일에 추가';

  @override
  String get categoryPersonal => '개인 일정';

  @override
  String get categoryWork => '업무용';

  @override
  String get categoryPartner => '연인용';

  @override
  String get categoryFamily => '가족';

  @override
  String get categoryFriend => '친구';

  @override
  String get categoryOther => '기타';

  @override
  String get calendarTitle => 'Kairos';

  @override
  String get calendarTagline => '소중한 순간의 공유';

  @override
  String get calendarViewList => '목록으로 보기';

  @override
  String get calendarViewCalendar => '캘린더로 보기';

  @override
  String get calendarFilterTooltip => '표시할 캘린더 선택';

  @override
  String get calendarFilterTitle => '표시할 캘린더';

  @override
  String get calendarFilterClose => '닫기';

  @override
  String get calendarMonthPickerTitle => '연월 선택';

  @override
  String calendarMonthPickerYear(Object year) {
    return '$year년';
  }

  @override
  String calendarMonthPickerMonth(Object month) {
    return '$month월';
  }

  @override
  String get calendarMonthPickerGo => '이동';

  @override
  String get calendarFormatMonth => '월';

  @override
  String get calendarFormatWeek => '주';

  @override
  String get calendarNoScheduleThisDay => '이 날의 일정이 없습니다';

  @override
  String get calendarNoUpcoming => '예정된 일정이 없습니다';

  @override
  String get calendarLoadError => '일정을 불러오지 못했습니다';

  @override
  String calendarWeatherLine(Object max, Object min) {
    return '최고 $max° / 최저 $min°';
  }

  @override
  String calendarWeatherPrecipitation(Object percent) {
    return ' / 강수확률 $percent%';
  }

  @override
  String get calendarAllDay => '종일';

  @override
  String calendarBirthdaySuffix(Object name) {
    return '$name의 생일';
  }

  @override
  String get calendarChristmasEve => '크리스마스 이브';

  @override
  String get calendarChristmas => '크리스마스';

  @override
  String get calendarNewYearsEve => '제야';

  @override
  String get calendarMothersDay => '어버이날';

  @override
  String get calendarFathersDay => '아버지의 날';

  @override
  String get calendarVernalEquinox => '춘분의 날';

  @override
  String get calendarAutumnalEquinox => '추분의 날';

  @override
  String get groupListTitle => '그룹';

  @override
  String get groupListEmpty => '아직 그룹이 없습니다';

  @override
  String groupListMembers(Object count) {
    return '멤버 $count명';
  }

  @override
  String get groupJoinTooltip => '초대 코드로 그룹 참여';

  @override
  String get groupFormTitle => '그룹 만들기';

  @override
  String get groupFormNameLabel => '그룹 이름';

  @override
  String get groupFormNameRequired => '그룹 이름을 입력해 주세요';

  @override
  String get groupFormCreateButton => '만들기';

  @override
  String get groupJoinTitle => '그룹 참여';

  @override
  String get groupJoinInstructions => '그룹 소유자로부터 받은 초대 코드를 입력해 주세요.';

  @override
  String get groupJoinCodeLabel => '초대 코드';

  @override
  String get groupJoinConfirmButton => '확인';

  @override
  String get groupJoinNotFound => '코드를 찾을 수 없습니다. 입력 내용을 확인해 주세요';

  @override
  String get groupJoinConfirmTitle => '이 그룹이 맞습니까?';

  @override
  String groupJoinMembers(Object count) {
    return '멤버 $count명';
  }

  @override
  String get groupJoinAlreadyMember => '이미 이 그룹의 멤버입니다';

  @override
  String get groupJoinButton => '이 그룹에 참여하기';

  @override
  String get groupJoinFailed => '참여에 실패했습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get groupDetailInviteCode => '초대 코드';

  @override
  String get groupDetailInviteCodeCopied => '초대 코드를 복사했습니다';

  @override
  String get groupDetailMembers => '멤버';

  @override
  String get groupDetailChat => '대화';

  @override
  String get groupDeleteConfirmTitle => '그룹을 삭제하시겠습니까?';

  @override
  String get groupDeleteConfirmBody => '삭제 직후라면 되돌릴 수 있습니다.';

  @override
  String get groupDeleted => '그룹을 삭제했습니다';

  @override
  String groupChatTitle(Object name) {
    return '$name 대화';
  }

  @override
  String get groupChatEmpty => '아직 메시지가 없습니다';

  @override
  String get groupChatInputHint => '메시지를 입력하세요';

  @override
  String get groupChatStampTooltip => '스티커';

  @override
  String get anniversaryListTitle => '소중한 기념일';

  @override
  String get anniversaryListEmpty => '등록된 기념일이 없습니다';

  @override
  String anniversaryListYearly(Object month, Object day) {
    return '매년 $month월 $day일';
  }

  @override
  String get anniversaryFormTitleNew => '기념일 추가';

  @override
  String get anniversaryFormTitleEdit => '기념일 편집';

  @override
  String get anniversaryFormNameLabel => '이름（예: 결혼기념일, 생일）';

  @override
  String get anniversaryFormNameRequired => '이름을 입력해 주세요';

  @override
  String get anniversaryFormDate => '날짜（매년）';

  @override
  String anniversaryFormDateValue(Object month, Object day) {
    return '$month월 $day일';
  }

  @override
  String get anniversaryFormDatePickerHelp => '월과 일을 선택하세요（연도는 사용하지 않습니다）';

  @override
  String get anniversaryFormNotifyHint => '매년 이 날 오전 9시에 알림을 받습니다';

  @override
  String get anniversaryDeleted => '기념일을 삭제했습니다';
}
