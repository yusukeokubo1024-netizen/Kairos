import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

/** Pushes an FCM notification to every other member of a group the moment
 * a chat message is created — unlike schedule reminders, group membership
 * already requires the recipient's consent (join request + owner
 * approval, see firestore.rules joinRequests), so there's no
 * harassment-vector concern in pushing to every member the way there was
 * for a schedule's unrestricted participantIds. */
export const sendChatMessageNotification = onDocumentCreated(
  { document: "sharedGroups/{groupId}/messages/{messageId}", region: "asia-northeast1" },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const message = snapshot.data() as { senderId: string };
    const { groupId } = event.params;
    const db = admin.firestore();

    const groupDoc = await db.collection("sharedGroups").doc(groupId).get();
    const group = groupDoc.data() as { name?: string; memberIds?: string[] } | undefined;
    if (!group) return;

    const recipientIds = (group.memberIds ?? []).filter((uid) => uid !== message.senderId);
    if (recipientIds.length === 0) return;

    const [userDocs, tokenDocs] = await Promise.all([
      Promise.all(recipientIds.map((uid) => db.collection("users").doc(uid).get())),
      Promise.all(recipientIds.map((uid) => db.collection("deviceTokens").doc(uid).get())),
    ]);

    const tokens: string[] = [];
    recipientIds.forEach((uid, i) => {
      const notificationsEnabled = userDocs[i].data()?.notifications_enabled ?? true;
      if (!notificationsEnabled) return;
      const mutedGroupIds = (userDocs[i].data()?.mutedGroupIds as string[] | undefined) ?? [];
      if (mutedGroupIds.includes(groupId)) return;
      const docTokens = (tokenDocs[i].data()?.tokens as string[] | undefined) ?? [];
      tokens.push(...docTokens);
    });
    if (tokens.length === 0) return;

    // Deliberately doesn't include the sender name or message text (LINE-
    // style privacy) — the lock screen/notification shade is a more public
    // surface than the chat itself, and a shared family device could have
    // this visible to people who aren't in the conversation.
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title: group.name ?? "Kairos", body: "新しいメッセージが届きました" },
        data: { type: "groupChat", groupId },
      });

      const staleTokens: string[] = [];
      response.responses.forEach((r, i) => {
        if (!r.success && r.error?.code === "messaging/registration-token-not-registered") {
          staleTokens.push(tokens[i]);
        }
      });
      if (staleTokens.length > 0) {
        await Promise.all(
          recipientIds.map((uid) =>
            db
              .collection("deviceTokens")
              .doc(uid)
              .update({ tokens: admin.firestore.FieldValue.arrayRemove(...staleTokens) })
              .catch(() => undefined)
          )
        );
      }
    } catch (err) {
      logger.error(`sendChatMessageNotification: failed for group ${groupId}`, err);
    }
  }
);
