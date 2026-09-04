import * as admin from "firebase-admin";
import { AppError, ErrorCode } from "../utils/errors";
import { validateString } from "../utils/validation";

interface DeviceTokenDocument {
  tokens: string[];
  updatedAt: admin.firestore.Timestamp;
}

export class NotificationService {
  static async registerToken(userId: string, token: unknown): Promise<void> {
    const value = validateString(token, "token", 1, 4096);
    const reference = admin.firestore().collection("deviceTokens").doc(userId);
    await reference.set({
      tokens: admin.firestore.FieldValue.arrayUnion(value),
      updatedAt: admin.firestore.Timestamp.now(),
    }, { merge: true });
  }

  static async unregisterToken(userId: string, token: unknown): Promise<void> {
    const value = validateString(token, "token", 1, 4096);
    await admin.firestore().collection("deviceTokens").doc(userId).update({
      tokens: admin.firestore.FieldValue.arrayRemove(value),
      updatedAt: admin.firestore.Timestamp.now(),
    });
  }

  static async sendToUsers(
    userIds: string[],
    title: string,
    body: string,
    data: Record<string, string> = {}
  ): Promise<number> {
    const uniqueUserIds = [...new Set(userIds)];
    if (uniqueUserIds.length === 0) return 0;
    const documents = await Promise.all(
      uniqueUserIds.map((userId) => admin.firestore().collection("deviceTokens").doc(userId).get())
    );
    const tokens = documents.flatMap((document) => (document.data() as DeviceTokenDocument | undefined)?.tokens || []);
    if (tokens.length === 0) return 0;

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
    });
    return response.successCount;
  }

  static async sendScheduleInvitation(ownerId: string, participantIds: string[], scheduleId: string, title: string): Promise<number> {
    if (participantIds.includes(ownerId)) {
      participantIds = participantIds.filter((userId) => userId !== ownerId);
    }
    return this.sendToUsers(participantIds, "予定への招待", title, { type: "schedule_invitation", scheduleId });
  }

  static async assertScheduleOwner(userId: string, scheduleId: string): Promise<void> {
    const schedule = await admin.firestore().collection("schedules").doc(scheduleId).get();
    if (!schedule.exists) throw new AppError(ErrorCode.NOT_FOUND, 404, "Schedule not found");
    if (schedule.data()?.ownerId !== userId) throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Only owner can send invitations");
  }
}