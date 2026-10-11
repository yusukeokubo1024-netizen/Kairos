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
exports.sendChatMessageNotification = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const pushText_1 = require("./utils/pushText");
/** Pushes an FCM notification to every other member of a group the moment
 * a chat message is created — unlike schedule reminders, group membership
 * already requires the recipient's consent (join request + owner
 * approval, see firestore.rules joinRequests), so there's no
 * harassment-vector concern in pushing to every member the way there was
 * for a schedule's unrestricted participantIds. */
exports.sendChatMessageNotification = (0, firestore_1.onDocumentCreated)({ document: "sharedGroups/{groupId}/messages/{messageId}", region: "asia-northeast1" }, async (event) => {
    const snapshot = event.data;
    if (!snapshot)
        return;
    const message = snapshot.data();
    const { groupId } = event.params;
    const db = admin.firestore();
    const groupDoc = await db.collection("sharedGroups").doc(groupId).get();
    const group = groupDoc.data();
    if (!group)
        return;
    const recipientIds = (group.memberIds ?? []).filter((uid) => uid !== message.senderId);
    if (recipientIds.length === 0)
        return;
    const [userDocs, tokenDocs] = await Promise.all([
        Promise.all(recipientIds.map((uid) => db.collection("users").doc(uid).get())),
        Promise.all(recipientIds.map((uid) => db.collection("deviceTokens").doc(uid).get())),
    ]);
    // Different recipients may have picked different notification sounds
    // (NotificationSoundService), each living on its own Android channel,
    // and use different app languages — FCM only takes one channelId and
    // one body per send, so group tokens by (channel, language) and send
    // once per group.
    const tokensByChannel = new Map();
    recipientIds.forEach((uid, i) => {
        const notificationsEnabled = userDocs[i].data()?.notifications_enabled ?? true;
        if (!notificationsEnabled)
            return;
        const mutedGroupIds = userDocs[i].data()?.mutedGroupIds ?? [];
        if (mutedGroupIds.includes(groupId))
            return;
        const channelId = userDocs[i].data()?.notificationChannels?.chat ?? "chat_messages";
        const docTokens = tokenDocs[i].data()?.tokens ?? [];
        if (docTokens.length === 0)
            return;
        const locale = (0, pushText_1.pushLocale)(userDocs[i].data()?.locale);
        const key = `${channelId}|${locale}`;
        const entry = tokensByChannel.get(key) ?? { channelId, locale, tokens: [] };
        entry.tokens.push(...docTokens);
        tokensByChannel.set(key, entry);
    });
    if (tokensByChannel.size === 0) {
        logger.info(`sendChatMessageNotification: group ${groupId} — no recipient to notify ` +
            `(${recipientIds.length} other member(s); all muted, disabled or without a token)`);
        return;
    }
    // Deliberately doesn't include the sender name or message text (LINE-
    // style privacy) — the lock screen/notification shade is a more public
    // surface than the chat itself, and a shared family device could have
    // this visible to people who aren't in the conversation.
    try {
        const staleTokens = [];
        for (const { channelId, locale, tokens } of tokensByChannel.values()) {
            const response = await admin.messaging().sendEachForMulticast({
                tokens,
                notification: { title: group.name ?? "Kairos", body: (0, pushText_1.pushText)("newChatMessage", locale) },
                android: { notification: { channelId, sound: "default" }, priority: "high" },
                apns: { payload: { aps: { sound: "default" } } },
                data: { type: "groupChat", groupId },
            });
            logger.info(`sendChatMessageNotification: group ${groupId} channel ${channelId} — ` +
                `${response.successCount} sent, ${response.failureCount} failed`);
            response.responses.forEach((r, i) => {
                if (r.success)
                    return;
                logger.warn(`sendChatMessageNotification: token …${tokens[i].slice(-8)} failed: ` +
                    `${r.error?.code} ${r.error?.message}`);
                if (r.error?.code === "messaging/registration-token-not-registered") {
                    staleTokens.push(tokens[i]);
                }
            });
        }
        if (staleTokens.length > 0) {
            await Promise.all(recipientIds.map((uid) => db
                .collection("deviceTokens")
                .doc(uid)
                .update({ tokens: admin.firestore.FieldValue.arrayRemove(...staleTokens) })
                .catch(() => undefined)));
        }
    }
    catch (err) {
        logger.error(`sendChatMessageNotification: failed for group ${groupId}`, err);
    }
});
//# sourceMappingURL=chatNotifications.js.map