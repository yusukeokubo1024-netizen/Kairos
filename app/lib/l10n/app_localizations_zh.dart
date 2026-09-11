// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appLocked => 'Kairos 已锁定';

  @override
  String get authenticate => '进行认证';

  @override
  String get biometricAuthReason => '打开 Kairos 需要进行身份验证';

  @override
  String get tabHome => '首页';

  @override
  String get tabTasks => '任务';

  @override
  String get tabGroups => '群组';

  @override
  String get tabSettings => '设置';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDone => '完成';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonUndo => '撤销';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonAdd => '添加';

  @override
  String get commonNotSet => '未设置';

  @override
  String get loginTagline => '共享珍贵的瞬间';

  @override
  String get loginEmailLabel => '电子邮箱地址';

  @override
  String get loginEmailRequired => '请输入电子邮箱地址';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginPasswordRequired => '请输入密码';

  @override
  String get loginButton => '登录';

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginSignUpLink => '注册';

  @override
  String get loginErrorWrongCredentials => '电子邮箱地址或密码不正确';

  @override
  String get loginErrorInvalidEmail => '电子邮箱地址格式无效';

  @override
  String get loginErrorUserDisabled => '此账号已被禁用';

  @override
  String get loginErrorTooManyRequests => '登录尝试次数过多，请稍后再试';

  @override
  String get loginErrorGeneric => '登录失败，请稍后再试';

  @override
  String get signUpTitle => '注册';

  @override
  String get signUpNameLabel => '显示名称';

  @override
  String get signUpNameRequired => '请输入显示名称';

  @override
  String get signUpPasswordLabel => '密码（6位以上）';

  @override
  String get signUpPasswordTooShort => '密码必须至少为6位';

  @override
  String get signUpButton => '创建账号';

  @override
  String get signUpErrorEmailInUse => '该电子邮箱地址已被注册';

  @override
  String get signUpErrorGeneric => '注册失败，请稍后再试';

  @override
  String get signUpBiometricOfferTitle => '要信任此设备吗？';

  @override
  String get signUpBiometricOfferBody =>
      '下次开始，无需输入电子邮箱和密码，只需使用 Face ID / 指纹即可登录。';

  @override
  String get signUpBiometricOfferSkip => '稍后设置';

  @override
  String get signUpBiometricOfferEnable => '启用';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get resetPasswordInstructions => '请输入您注册时使用的电子邮箱地址，我们将向您发送重置链接。';

  @override
  String get resetPasswordSuccess => '重置密码的邮件已发送';

  @override
  String get resetPasswordError => '发送失败，请确认您的电子邮箱地址';

  @override
  String get resetPasswordButton => '发送';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDisplayNameUnset => '（未设置显示名称）';

  @override
  String get settingsEditDisplayName => '编辑显示名称';

  @override
  String settingsDisplayNameSaved(Object name) {
    return '显示名称已更改为「$name」';
  }

  @override
  String settingsDisplayNameSaveFailed(Object error) {
    return '显示名称保存失败：$error';
  }

  @override
  String get settingsBirthday => '生日';

  @override
  String get settingsBirthdayPick => '选择生日';

  @override
  String settingsBirthdayValue(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get settingsBirthdayHint => '设置生日后，每年都会显示在您的日历以及群组好友、家人的日历上';

  @override
  String get settingsWeatherLocation => '所在地区（天气预报）';

  @override
  String get settingsWeatherLocationTitle => '所在地区';

  @override
  String get settingsWeatherLocationCountryTitle => '选择国家/地区';

  @override
  String get settingsWeatherLocationCountrySearchHint => '按国家名称搜索';

  @override
  String get settingsWeatherLocationCountryNotFound => '未找到匹配结果';

  @override
  String get settingsWeatherLocationPrefectureTitle => '选择地区';

  @override
  String get settingsWeatherLocationPrefectureSearchHint => '按地区名称搜索';

  @override
  String get settingsWeatherLocationCitySearchHint => '按地名搜索';

  @override
  String get settingsWeatherLocationManualEntry => '其他（手动输入）';

  @override
  String get settingsWeatherLocationHint =>
      '例如：Shibuya、Yokohama、Sapporo、New York';

  @override
  String get settingsWeatherLocationHelper => '请仅输入地名进行搜索，不要加上「区」「市」等后缀';

  @override
  String get settingsWeatherLocationConfirmTitle => '是这个地区吗？';

  @override
  String settingsWeatherLocationSaved(Object place) {
    return '已设置为$place';
  }

  @override
  String get settingsWeatherLocationNotFound => '未找到该地区';

  @override
  String settingsWeatherLocationSearchFailed(Object error) {
    return '地区搜索失败：$error';
  }

  @override
  String settingsWeatherLocationSaveFailed(Object error) {
    return '地区保存失败：$error';
  }

  @override
  String get settingsAccountLinking => '账号关联';

  @override
  String get settingsGoogleLink => '关联 Google 账号';

  @override
  String get settingsGoogleLinked => '已关联';

  @override
  String get settingsGoogleNotLinked => '未关联';

  @override
  String get settingsGoogleLinkSuccess => '已关联您的 Google 账号';

  @override
  String get settingsGoogleLinkInUse => '该 Google 账号已关联到另一个 Kairos 账号';

  @override
  String get settingsGoogleLinkFailed => 'Google 账号关联失败';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsNotificationsSubtitle => '日程、任务和纪念日的提醒';

  @override
  String get settingsBiometricLock => '使用 Face ID / 指纹锁定';

  @override
  String get settingsBiometricLockSubtitle => '每次打开应用都需要验证身份';

  @override
  String get settingsAnniversaries => '重要纪念日';

  @override
  String get settingsAnniversariesSubtitle => '登记您希望每年都收到提醒的纪念日';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsSupport => '支持';

  @override
  String get settingsCouldNotOpenPage => '无法打开页面';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsDeleteAccount => '删除账号';

  @override
  String get settingsDeleteAccountConfirmTitle => '确定要删除账号吗？';

  @override
  String get settingsDeleteAccountConfirmBody =>
      '您的个人资料以及您拥有的所有日程、任务和群组都将被删除，且无法恢复。如果您拥有共享群组，请先移除其他成员。';

  @override
  String get settingsDeleteAccountConfirmButton => '删除';

  @override
  String get settingsDeleteAccountRequiresRecentLogin => '出于安全考虑，请退出登录后重新登录再试';

  @override
  String get settingsDeleteAccountFailed => '账号删除失败';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get supportTitle => '支持';

  @override
  String get supportFaqTitle => '常见问题';

  @override
  String get supportFaqPasswordQ => '我忘记密码了';

  @override
  String get supportFaqPasswordA => '在登录界面点击「忘记密码？」，输入您注册的电子邮箱地址，即可收到重置密码的邮件。';

  @override
  String get supportFaqBiometricQ => '不想每次打开应用都输入密码';

  @override
  String get supportFaqBiometricA =>
      '在设置中开启「使用 Face ID / 指纹锁定」后，之后只需生体认证即可打开应用（需设备支持）。';

  @override
  String get supportFaqGroupQ => '如何加入群组？';

  @override
  String get supportFaqGroupA => '请在群组页面右上角的图标处，输入群组所有者提供的邀请码。';

  @override
  String get supportFaqWeatherQ => '我想更改天气预报的地区';

  @override
  String get supportFaqWeatherA =>
      '在设置的「所在地区」中，可以依次选择国家→省/州→城市。点击天气摘要可在外部网站查看详情。';

  @override
  String get supportFaqNotificationQ => '收不到通知';

  @override
  String get supportFaqNotificationA => '请确认设置中的通知已开启，并同时检查设备/浏览器的通知权限设置。';

  @override
  String get supportFaqLanguageQ => '我想更改应用的显示语言';

  @override
  String get supportFaqLanguageA =>
      '在设置的「语言」中，可以从 日本語・English・한국어・中文 中选择。切换后会应用到整个应用。';

  @override
  String get supportFaqDeleteQ => '我想删除账号或数据';

  @override
  String get supportFaqDeleteA => '可以在设置的「删除账号」中自行删除。如有疑问，请通过下方联系方式与我们联系。';

  @override
  String get supportAiTitle => '向AI提问';

  @override
  String get supportAiDescription =>
      '以上常见问题未涵盖的内容，也可以在下方输入框中输入，系统会自动回答（24小时可用）。';

  @override
  String get supportAiGreeting => '您好！关于Kairos的任何问题都可以问我。';

  @override
  String get supportAiInputHint => '请输入您的问题';

  @override
  String get supportAiSend => '发送';

  @override
  String get supportAiThinking => '正在生成回答…';

  @override
  String supportAiRetrying(Object attempt, Object max) {
    return '当前较为繁忙，正在重试…（$attempt/$max）';
  }

  @override
  String get supportAiError => '抱歉，由于访问量较大暂时无法获取回答。请稍后重试，或通过下方邮箱与我们联系。';

  @override
  String get supportAiNotConfigured => 'AI问答功能尚在准备中，请通过下方邮箱与我们联系。';

  @override
  String get supportContactTitle => '联系我们';

  @override
  String get supportContactBody =>
      '如以上内容无法解决您的问题，或需要报告故障、咨询隐私相关事宜，请通过以下邮箱与我们联系。';

  @override
  String get taskListTitle => '任务';

  @override
  String get taskListPending => '未完成';

  @override
  String get taskListDone => '已完成';

  @override
  String get taskListEmptyPending => '没有未完成的任务';

  @override
  String get taskListEmptyDone => '没有已完成的任务';

  @override
  String get taskListFromSchedule => '从日程的准备清单中添加';

  @override
  String get taskDeleted => '任务已删除';

  @override
  String get taskFormTitleNew => '创建任务';

  @override
  String get taskFormTitleEdit => '编辑任务';

  @override
  String get taskFormTitleLabel => '标题';

  @override
  String get taskFormTitleRequired => '请输入标题';

  @override
  String get taskFormPriority => '优先级';

  @override
  String get taskFormPriorityLow => '低';

  @override
  String get taskFormPriorityMedium => '中';

  @override
  String get taskFormPriorityHigh => '高';

  @override
  String get taskFormDueDate => '截止日期';

  @override
  String get taskFormDueDateNotSet => '未设置';

  @override
  String get scheduleDetailTitle => '日程详情';

  @override
  String get scheduleDeleteConfirmTitle => '确定要删除该日程吗？';

  @override
  String get scheduleDeleteConfirmBody => '删除后可以立即撤销。';

  @override
  String get scheduleDeleted => '日程已删除';

  @override
  String get scheduleAllDaySuffix => '（全天）';

  @override
  String scheduleParticipants(Object count) {
    return '$count 位参加者';
  }

  @override
  String get scheduleReminderNone => '不提醒';

  @override
  String scheduleReminderBefore(Object minutes) {
    return '提前 $minutes 分钟提醒';
  }

  @override
  String get scheduleCouldNotOpenMap => '无法打开地图';

  @override
  String get scheduleFormTitleNew => '创建日程';

  @override
  String get scheduleFormTitleEdit => '编辑日程';

  @override
  String get scheduleFormTitleLabel => '标题';

  @override
  String get scheduleFormTitleRequired => '请输入标题';

  @override
  String get scheduleFormAllDay => '全天';

  @override
  String get scheduleFormStart => '开始';

  @override
  String get scheduleFormEnd => '结束';

  @override
  String get scheduleFormEndBeforeStart => '结束时间必须晚于开始时间';

  @override
  String get scheduleFormLocation => '地点';

  @override
  String get scheduleFormNotes => '备注';

  @override
  String get scheduleFormColor => '颜色';

  @override
  String get scheduleFormNotification => '通知';

  @override
  String get scheduleFormReminderNone => '不提醒';

  @override
  String get scheduleFormReminder5 => '提前5分钟';

  @override
  String get scheduleFormReminder15 => '提前15分钟';

  @override
  String get scheduleFormReminder30 => '提前30分钟';

  @override
  String get scheduleFormReminder60 => '提前1小时';

  @override
  String get scheduleFormReminder1440 => '提前1天';

  @override
  String get scheduleFormCalendar => '日历';

  @override
  String get scheduleFormCalendarHint => '该分类用于在主页的筛选器中切换显示/隐藏';

  @override
  String get scheduleFormGroupSuffix => '（群组）';

  @override
  String get scheduleFormShareWith => '共享对象';

  @override
  String get scheduleFormShareWithHint => '可以从群组成员中选择要与之共享此日程的人';

  @override
  String get scheduleFormNoCandidates => '暂时没有可共享的对象，请先在群组中添加成员。';

  @override
  String get scheduleFormLoadingName => '加载中...';

  @override
  String get scheduleFormPrepDialogTitle => '有需要准备的东西吗？';

  @override
  String get scheduleFormPrepDialogSkip => '不添加';

  @override
  String get scheduleFormPrepDialogAdd => '添加到任务';

  @override
  String get categoryPersonal => '个人日程';

  @override
  String get categoryWork => '工作';

  @override
  String get categoryPartner => '伴侣';

  @override
  String get categoryFamily => '家人';

  @override
  String get categoryFriend => '朋友';

  @override
  String get categoryOther => '其他';

  @override
  String get calendarTitle => 'Kairos';

  @override
  String get calendarTagline => '共享珍贵的瞬间';

  @override
  String get calendarViewList => '以列表显示';

  @override
  String get calendarViewCalendar => '以日历显示';

  @override
  String get calendarFilterTooltip => '选择要显示的日历';

  @override
  String get calendarFilterTitle => '要显示的日历';

  @override
  String get calendarFilterClose => '关闭';

  @override
  String get calendarMonthPickerTitle => '选择年月';

  @override
  String calendarMonthPickerYear(Object year) {
    return '$year年';
  }

  @override
  String calendarMonthPickerMonth(Object month) {
    return '$month月';
  }

  @override
  String get calendarMonthPickerGo => '跳转';

  @override
  String get calendarFormatMonth => '月';

  @override
  String get calendarFormatWeek => '周';

  @override
  String get calendarNoScheduleThisDay => '这一天没有日程';

  @override
  String get calendarNoUpcoming => '没有即将到来的日程';

  @override
  String get calendarLoadError => '日程加载失败';

  @override
  String calendarWeatherLine(Object max, Object min) {
    return '最高$max° / 最低$min°';
  }

  @override
  String calendarWeatherPrecipitation(Object percent) {
    return ' / 降水概率$percent%';
  }

  @override
  String get calendarAllDay => '全天';

  @override
  String calendarBirthdaySuffix(Object name) {
    return '$name的生日';
  }

  @override
  String get calendarChristmasEve => '平安夜';

  @override
  String get calendarChristmas => '圣诞节';

  @override
  String get calendarNewYearsEve => '除夕';

  @override
  String get calendarMothersDay => '母亲节';

  @override
  String get calendarFathersDay => '父亲节';

  @override
  String get calendarVernalEquinox => '春分节气';

  @override
  String get calendarAutumnalEquinox => '秋分节气';

  @override
  String get groupListTitle => '群组';

  @override
  String get groupListEmpty => '还没有群组';

  @override
  String groupListMembers(Object count) {
    return '$count 位成员';
  }

  @override
  String get groupJoinTooltip => '使用邀请码加入群组';

  @override
  String get groupFormTitle => '创建群组';

  @override
  String get groupFormNameLabel => '群组名称';

  @override
  String get groupFormNameRequired => '请输入群组名称';

  @override
  String get groupFormCreateButton => '创建';

  @override
  String get groupJoinTitle => '加入群组';

  @override
  String get groupJoinInstructions => '请输入群组所有者提供的邀请码。';

  @override
  String get groupJoinCodeLabel => '邀请码';

  @override
  String get groupJoinConfirmButton => '确认';

  @override
  String get groupJoinNotFound => '未找到该邀请码，请确认输入内容';

  @override
  String get groupJoinConfirmTitle => '是这个群组吗？';

  @override
  String groupJoinMembers(Object count) {
    return '$count 位成员';
  }

  @override
  String get groupJoinAlreadyMember => '您已经是该群组的成员';

  @override
  String get groupJoinButton => '加入该群组';

  @override
  String get groupJoinFailed => '加入失败，请稍后再试';

  @override
  String get groupDetailInviteCode => '邀请码';

  @override
  String get groupDetailInviteCodeCopied => '邀请码已复制';

  @override
  String get groupDetailMembers => '成员';

  @override
  String get groupDetailChat => '聊天';

  @override
  String get groupDeleteConfirmTitle => '确定要删除该群组吗？';

  @override
  String get groupDeleteConfirmBody => '删除后可以立即撤销。';

  @override
  String get groupDeleted => '群组已删除';

  @override
  String groupChatTitle(Object name) {
    return '$name的聊天';
  }

  @override
  String get groupChatEmpty => '还没有消息';

  @override
  String get groupChatInputHint => '输入消息';

  @override
  String get groupChatStampTooltip => '贴图';

  @override
  String get anniversaryListTitle => '重要纪念日';

  @override
  String get anniversaryListEmpty => '还没有登记纪念日';

  @override
  String anniversaryListYearly(Object month, Object day) {
    return '每年$month月$day日';
  }

  @override
  String get anniversaryFormTitleNew => '添加纪念日';

  @override
  String get anniversaryFormTitleEdit => '编辑纪念日';

  @override
  String get anniversaryFormNameLabel => '名称（例如：结婚纪念日、生日）';

  @override
  String get anniversaryFormNameRequired => '请输入名称';

  @override
  String get anniversaryFormDate => '日期（每年）';

  @override
  String anniversaryFormDateValue(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get anniversaryFormDatePickerHelp => '请选择月和日（不使用年份）';

  @override
  String get anniversaryFormNotifyHint => '每年这一天的上午9点会收到通知';

  @override
  String get anniversaryDeleted => '纪念日已删除';
}
