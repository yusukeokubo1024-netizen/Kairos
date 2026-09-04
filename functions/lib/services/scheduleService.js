"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScheduleService = void 0;
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("../utils/errors");
const validation_1 = require("../utils/validation");
class ScheduleService {
    /**
     * スケジュール作成
     */
    static async createSchedule(userId, data) {
        try {
            const db = admin.firestore();
            // バリデーション
            const title = (0, validation_1.validateString)(data.title, "title", 1, 255);
            const description = data.description
                ? (0, validation_1.validateString)(data.description, "description", 0, 1000)
                : undefined;
            const location = data.location
                ? (0, validation_1.validateString)(data.location, "location", 0, 255)
                : undefined;
            // スケジュール ID 生成
            const scheduleRef = db.collection("schedules").doc();
            const scheduleId = scheduleRef.id;
            // 参加者情報の構築
            const participants = [
                {
                    uid: userId,
                    status: "accepted",
                    addedAt: admin.firestore.Timestamp.now(),
                },
            ];
            // 他の参加者を追加
            if (data.participants && data.participants.length > 0) {
                const participantsList = (0, validation_1.validateArray)(data.participants, "participants");
                participantsList.forEach((participantId) => {
                    if (typeof participantId !== "string") {
                        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, "participants must contain user IDs");
                    }
                    if (participantId !== userId) {
                        participants.push({
                            uid: participantId,
                            status: "invited",
                            addedAt: admin.firestore.Timestamp.now(),
                        });
                    }
                });
            }
            // スケジュール データ作成
            const scheduleData = {
                id: scheduleId,
                ownerId: userId,
                title,
                startTime: data.startTime,
                endTime: data.endTime,
                color: data.color || "#2563EB",
                participants,
                participantIds: participants.map((participant) => participant.uid),
                createdAt: admin.firestore.Timestamp.now(),
                updatedAt: admin.firestore.Timestamp.now(),
                ...(description !== undefined ? { description } : {}),
                ...(location !== undefined ? { location } : {}),
            };
            await scheduleRef.set(scheduleData);
            return scheduleData;
        }
        catch (error) {
            if (error instanceof errors_1.AppError)
                throw error;
            throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Failed to create schedule");
        }
    }
    /**
     * スケジュール取得
     */
    static async getSchedule(userId, scheduleId) {
        try {
            const db = admin.firestore();
            const scheduleDoc = await db
                .collection("schedules")
                .doc(scheduleId)
                .get();
            if (!scheduleDoc.exists) {
                throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Schedule not found");
            }
            const schedule = scheduleDoc.data();
            // アクセス権限確認
            const hasAccess = schedule.ownerId === userId ||
                schedule.participants.some((p) => p.uid === userId);
            if (!hasAccess) {
                throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Access denied");
            }
            return schedule;
        }
        catch (error) {
            if (error instanceof errors_1.AppError)
                throw error;
            throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Failed to get schedule");
        }
    }
    /**
     * スケジュール更新
     */
    static async updateSchedule(userId, scheduleId, data) {
        try {
            const db = admin.firestore();
            const scheduleRef = db.collection("schedules").doc(scheduleId);
            const scheduleDoc = await scheduleRef.get();
            if (!scheduleDoc.exists) {
                throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Schedule not found");
            }
            const schedule = scheduleDoc.data();
            // オーナーのみ更新可能
            if (schedule.ownerId !== userId) {
                throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Only owner can update schedule");
            }
            // 更新データの準備
            const updateData = {
                updatedAt: admin.firestore.Timestamp.now(),
            };
            if (data.title) {
                updateData.title = (0, validation_1.validateString)(data.title, "title", 1, 255);
            }
            if (data.description !== undefined) {
                updateData.description = data.description
                    ? (0, validation_1.validateString)(data.description, "description", 0, 1000)
                    : undefined;
            }
            if (data.location !== undefined) {
                updateData.location = data.location
                    ? (0, validation_1.validateString)(data.location, "location", 0, 255)
                    : undefined;
            }
            if (data.color) {
                updateData.color = (0, validation_1.validateString)(data.color, "color", 0, 20);
            }
            if (data.startTime) {
                updateData.startTime = data.startTime;
            }
            if (data.endTime) {
                updateData.endTime = data.endTime;
            }
            await scheduleRef.update(updateData);
            // 更新後のデータを取得して返却
            const updatedDoc = await scheduleRef.get();
            return updatedDoc.data();
        }
        catch (error) {
            if (error instanceof errors_1.AppError)
                throw error;
            throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Failed to update schedule");
        }
    }
    /**
     * スケジュール削除
     */
    static async deleteSchedule(userId, scheduleId) {
        try {
            const db = admin.firestore();
            const scheduleRef = db.collection("schedules").doc(scheduleId);
            const scheduleDoc = await scheduleRef.get();
            if (!scheduleDoc.exists) {
                throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Schedule not found");
            }
            const schedule = scheduleDoc.data();
            // オーナーのみ削除可能
            if (schedule.ownerId !== userId) {
                throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Only owner can delete schedule");
            }
            // サブコレクション削除
            const commentsSnapshot = await scheduleRef
                .collection("comments")
                .get();
            const commentBatch = db.batch();
            commentsSnapshot.docs.forEach((doc) => {
                commentBatch.delete(doc.ref);
            });
            await commentBatch.commit();
            const imagesSnapshot = await scheduleRef
                .collection("images")
                .get();
            const imageBatch = db.batch();
            imagesSnapshot.docs.forEach((doc) => {
                imageBatch.delete(doc.ref);
            });
            await imageBatch.commit();
            // スケジュール削除
            await scheduleRef.delete();
        }
        catch (error) {
            if (error instanceof errors_1.AppError)
                throw error;
            throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Failed to delete schedule");
        }
    }
    /**
     * スケジュール一覧取得
     */
    static async listSchedules(userId, options) {
        try {
            const db = admin.firestore();
            const participatingSnapshots = await db
                .collection("schedules")
                .where("participantIds", "array-contains", userId)
                .get();
            const ownedSnapshots = await db
                .collection("schedules")
                .where("ownerId", "==", userId)
                .get();
            const schedules = [];
            const scheduleIds = new Set();
            // 所有スケジュール
            ownedSnapshots.docs.forEach((doc) => {
                const schedule = doc.data();
                if (!scheduleIds.has(schedule.id)) {
                    schedules.push(schedule);
                    scheduleIds.add(schedule.id);
                }
            });
            // 参加スケジュール
            participatingSnapshots.docs.forEach((doc) => {
                const schedule = doc.data();
                if (!scheduleIds.has(schedule.id)) {
                    schedules.push(schedule);
                    scheduleIds.add(schedule.id);
                }
            });
            // 日付フィルタリング
            let filteredSchedules = schedules;
            if (options?.startDate && options?.endDate) {
                filteredSchedules = schedules.filter((s) => {
                    const scheduleStart = s.startTime;
                    const scheduleEnd = s.endTime;
                    return (scheduleStart.toDate() <= options.endDate.toDate() &&
                        scheduleEnd.toDate() >= options.startDate.toDate());
                });
            }
            // 開始時刻でソート
            filteredSchedules.sort((a, b) => a.startTime.toDate().getTime() - b.startTime.toDate().getTime());
            // リミット適用
            const limit = options?.limit || 100;
            return filteredSchedules.slice(0, limit);
        }
        catch (error) {
            if (error instanceof errors_1.AppError)
                throw error;
            throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Failed to list schedules");
        }
    }
    /**
     * 参加者のステータス更新
     */
    static async updateParticipantStatus(userId, scheduleId, status) {
        try {
            const db = admin.firestore();
            const scheduleRef = db.collection("schedules").doc(scheduleId);
            const scheduleDoc = await scheduleRef.get();
            if (!scheduleDoc.exists) {
                throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Schedule not found");
            }
            const schedule = scheduleDoc.data();
            // ユーザーが参加者に含まれているか確認
            const participantIndex = schedule.participants.findIndex((p) => p.uid === userId);
            if (participantIndex === -1) {
                throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "User is not a participant");
            }
            // ステータス更新
            schedule.participants[participantIndex].status = status;
            await scheduleRef.update({
                participants: schedule.participants,
                updatedAt: admin.firestore.Timestamp.now(),
            });
        }
        catch (error) {
            if (error instanceof errors_1.AppError)
                throw error;
            throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Failed to update participant status");
        }
    }
}
exports.ScheduleService = ScheduleService;
//# sourceMappingURL=scheduleService.js.map