/** Pushes an FCM notification to every other member of a group the moment
 * a chat message is created — unlike schedule reminders, group membership
 * already requires the recipient's consent (join request + owner
 * approval, see firestore.rules joinRequests), so there's no
 * harassment-vector concern in pushing to every member the way there was
 * for a schedule's unrestricted participantIds. */
export declare const sendChatMessageNotification: import("firebase-functions").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    groupId: string;
    messageId: string;
}>>;
//# sourceMappingURL=chatNotifications.d.ts.map