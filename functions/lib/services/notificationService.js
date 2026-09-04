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
exports.NotificationService = void 0;
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("../utils/errors");
const validation_1 = require("../utils/validation");
class NotificationService {
    static async registerToken(userId, token) {
        const value = (0, validation_1.validateString)(token, "token", 1, 4096);
        const reference = admin.firestore().collection("deviceTokens").doc(userId);
        await reference.set({
            tokens: admin.firestore.FieldValue.arrayUnion(value),
            updatedAt: admin.firestore.Timestamp.now(),
        }, { merge: true });
    }
    static async unregisterToken(userId, token) {
        const value = (0, validation_1.validateString)(token, "token", 1, 4096);
        await admin.firestore().collection("deviceTokens").doc(userId).update({
            tokens: admin.firestore.FieldValue.arrayRemove(value),
            updatedAt: admin.firestore.Timestamp.now(),
        });
    }
    static async sendToUsers(userIds, title, body, data = {}) {
        const uniqueUserIds = [...new Set(userIds)];
        if (uniqueUserIds.length === 0)
            return 0;
        const documents = await Promise.all(uniqueUserIds.map((userId) => admin.firestore().collection("deviceTokens").doc(userId).get()));
        const tokens = documents.flatMap((document) => document.data()?.tokens || []);
        if (tokens.length === 0)
            return 0;
        const response = await admin.messaging().sendEachForMulticast({
            tokens,
            notification: { title, body },
            data,
        });
        return response.successCount;
    }
    static async sendScheduleInvitation(ownerId, participantIds, scheduleId, title) {
        if (participantIds.includes(ownerId)) {
            participantIds = participantIds.filter((userId) => userId !== ownerId);
        }
        return this.sendToUsers(participantIds, "予定への招待", title, { type: "schedule_invitation", scheduleId });
    }
    static async assertScheduleOwner(userId, scheduleId) {
        const schedule = await admin.firestore().collection("schedules").doc(scheduleId).get();
        if (!schedule.exists)
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Schedule not found");
        if (schedule.data()?.ownerId !== userId)
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Only owner can send invitations");
    }
}
exports.NotificationService = NotificationService;
//# sourceMappingURL=notificationService.js.map