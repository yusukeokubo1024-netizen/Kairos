/** Push notification text in the recipient's app language
 * (users/{uid}.locale, written by the app's LocaleService). Japanese when
 * it isn't set yet — older app versions never wrote it. */
declare const texts: {
    readonly newChatMessage: {
        readonly ja: "新しいメッセージが届きました";
        readonly en: "You have a new message";
        readonly ko: "새 메시지가 도착했습니다";
        readonly zh: "收到新消息";
    };
    readonly reminderSoon: {
        readonly ja: "まもなく予定の時間です";
        readonly en: "Your event is starting soon";
        readonly ko: "곧 일정 시간입니다";
        readonly zh: "日程即将开始";
    };
};
export type PushTextKey = keyof typeof texts;
export type PushLocale = "ja" | "en" | "ko" | "zh";
export declare function pushLocale(value: unknown): PushLocale;
export declare function pushText(key: PushTextKey, locale: PushLocale): string;
export {};
//# sourceMappingURL=pushText.d.ts.map