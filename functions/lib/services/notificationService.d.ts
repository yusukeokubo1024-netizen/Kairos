export declare class NotificationService {
    static registerToken(userId: string, token: unknown): Promise<void>;
    static unregisterToken(userId: string, token: unknown): Promise<void>;
    static sendToUsers(userIds: string[], title: string, body: string, data?: Record<string, string>): Promise<number>;
    static sendScheduleInvitation(ownerId: string, participantIds: string[], scheduleId: string, title: string): Promise<number>;
    static assertScheduleOwner(userId: string, scheduleId: string): Promise<void>;
}
//# sourceMappingURL=notificationService.d.ts.map