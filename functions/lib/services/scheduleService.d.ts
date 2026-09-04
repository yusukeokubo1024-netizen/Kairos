import * as admin from "firebase-admin";
import { Schedule } from "../types";
export declare class ScheduleService {
    /**
     * スケジュール作成
     */
    static createSchedule(userId: string, data: {
        title: string;
        description?: string;
        startTime: admin.firestore.Timestamp;
        endTime: admin.firestore.Timestamp;
        location?: string;
        color?: string;
        participants?: string[];
    }): Promise<Schedule>;
    /**
     * スケジュール取得
     */
    static getSchedule(userId: string, scheduleId: string): Promise<Schedule>;
    /**
     * スケジュール更新
     */
    static updateSchedule(userId: string, scheduleId: string, data: Partial<Schedule>): Promise<Schedule>;
    /**
     * スケジュール削除
     */
    static deleteSchedule(userId: string, scheduleId: string): Promise<void>;
    /**
     * スケジュール一覧取得
     */
    static listSchedules(userId: string, options?: {
        startDate?: admin.firestore.Timestamp;
        endDate?: admin.firestore.Timestamp;
        limit?: number;
    }): Promise<Schedule[]>;
    /**
     * 参加者のステータス更新
     */
    static updateParticipantStatus(userId: string, scheduleId: string, status: "accepted" | "declined" | "tentative"): Promise<void>;
}
//# sourceMappingURL=scheduleService.d.ts.map