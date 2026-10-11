"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pushLocale = pushLocale;
exports.pushText = pushText;
/** Push notification text in the recipient's app language
 * (users/{uid}.locale, written by the app's LocaleService). Japanese when
 * it isn't set yet — older app versions never wrote it. */
const texts = {
    newChatMessage: {
        ja: "新しいメッセージが届きました",
        en: "You have a new message",
        ko: "새 메시지가 도착했습니다",
        zh: "收到新消息",
    },
    reminderSoon: {
        ja: "まもなく予定の時間です",
        en: "Your event is starting soon",
        ko: "곧 일정 시간입니다",
        zh: "日程即将开始",
    },
};
function pushLocale(value) {
    return value === "en" || value === "ko" || value === "zh" ? value : "ja";
}
function pushText(key, locale) {
    return texts[key][locale];
}
//# sourceMappingURL=pushText.js.map