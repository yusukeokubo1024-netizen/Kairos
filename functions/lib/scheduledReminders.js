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
exports.sendDueReminders = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const pushText_1 = require("./utils/pushText");
// Mirrors NotificationService.scheduleForSchedule in the Flutter app
// (lib/services/notification_service.dart), but as a server-side push so
// reminders still arrive when the app isn't running. Schedules are always
// entered/displayed in Asia/Tokyo (the app hardcodes this timezone), so all
// wall-clock math here assumes JST rather than the server's UTC clock.
const WINDOW_MINUTES = 5;
const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
function toJstWall(instant) {
    const t = new Date(instant.getTime() + JST_OFFSET_MS);
    return {
        year: t.getUTCFullYear(),
        month: t.getUTCMonth() + 1,
        day: t.getUTCDate(),
        hour: t.getUTCHours(),
        minute: t.getUTCMinutes(),
    };
}
function fromJstWall(w) {
    return new Date(Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, 0) - JST_OFFSET_MS);
}
// The next (year, month) after (year, month) that actually has [day] as a
// valid date, skipping any that don't (e.g. day 31 skips April, June,
// September, November, February) — matches
// NotificationService._nextMonthWithDay on the Dart side.
function nextMonthWithDay(year, month, day) {
    let y = year;
    let m = month;
    for (let i = 0; i < 24; i++) {
        m++;
        if (m > 12) {
            m = 1;
            y++;
        }
        const daysInMonth = new Date(Date.UTC(y, m, 0)).getUTCDate();
        if (day <= daysInMonth)
            return { year: y, month: m };
    }
    return { year, month: month + 1 };
}
// One step forward along a recurrence pattern, in JST wall-clock space —
// matches NotificationService._stepForward on the Dart side.
function stepWallForward(recurrence, w) {
    switch (recurrence) {
        case "daily": {
            const ms = Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, 0) + 24 * 60 * 60 * 1000;
            const d = new Date(ms);
            return { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate(), hour: w.hour, minute: w.minute };
        }
        case "weekly": {
            const ms = Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, 0) + 7 * 24 * 60 * 60 * 1000;
            const d = new Date(ms);
            return { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate(), hour: w.hour, minute: w.minute };
        }
        case "monthly": {
            const { year, month } = nextMonthWithDay(w.year, w.month, w.day);
            return { year, month, day: w.day, hour: w.hour, minute: w.minute };
        }
        case "yearly":
            return { year: w.year + 1, month: w.month, day: w.day, hour: w.hour, minute: w.minute };
        default:
            return w;
    }
}
/** The reminder's first-ever fire time (event start minus reminderMinutes),
 * in JST wall-clock terms consistent with the Dart implementation. */
function initialReminderInstant(data) {
    const start = data.startTime.toDate();
    const base = data.isAllDay ? fromJstWall({ ...toJstWall(start), hour: 9, minute: 0 }) : start;
    return new Date(base.getTime() - (data.reminderMinutes ?? 0) * 60 * 1000);
}
async function sendReminder(db, scheduleId, data) {
    // Deliberately NOT including data.participantIds: a schedule's owner can
    // add any uid they can resolve (e.g. via emailIndex) to participantIds
    // with no consent step from that person (firestore.rules has no
    // acceptance gate on this field, unlike sharedGroups' join-request flow).
    // That was a low-impact gap while it only granted silent read access;
    // pushing a recurring, owner-controlled-title notification to that uid's
    // device would turn it into a harassment vector. Restrict pushes to the
    // owner — the person who actually created and controls the reminder —
    // until participantIds has a real consent/acceptance step.
    const recipientIds = [data.ownerId];
    const [userDocs, tokenDocs] = await Promise.all([
        Promise.all(recipientIds.map((uid) => db.collection("users").doc(uid).get())),
        Promise.all(recipientIds.map((uid) => db.collection("deviceTokens").doc(uid).get())),
    ]);
    const tokens = [];
    // Only ever one recipient (the owner — see above), so there's exactly
    // one channel choice to look up, not a per-recipient grouping problem.
    let channelId = "schedule_reminders";
    let locale = (0, pushText_1.pushLocale)(undefined);
    recipientIds.forEach((uid, i) => {
        const notificationsEnabled = userDocs[i].data()?.notifications_enabled ?? true;
        if (!notificationsEnabled)
            return;
        channelId =
            userDocs[i].data()?.notificationChannels?.schedule ?? channelId;
        locale = (0, pushText_1.pushLocale)(userDocs[i].data()?.locale);
        const docTokens = tokenDocs[i].data()?.tokens ?? [];
        tokens.push(...docTokens);
    });
    if (tokens.length === 0)
        return;
    const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
            title: data.title,
            body: (0, pushText_1.pushText)("reminderSoon", locale),
        },
        // Without an explicit Android channel/sound, FCM delivers through a
        // generic default channel on some devices/OEMs that doesn't play a
        // sound — point it at whichever channel the recipient has configured
        // client-side (NotificationSoundService), falling back to the base
        // channel id for anyone who's never customized it.
        android: { notification: { channelId, sound: "default" }, priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
        data: { type: "scheduleReminder", scheduleId },
    });
    // Clean up tokens the device uninstalled the app for / that are no longer
    // valid, so they stop being billed against send quota and retried forever.
    const staleTokens = [];
    response.responses.forEach((r, i) => {
        if (!r.success && r.error?.code === "messaging/registration-token-not-registered") {
            staleTokens.push(tokens[i]);
        }
    });
    if (staleTokens.length > 0) {
        await Promise.all(recipientIds.map((uid) => db.collection("deviceTokens").doc(uid).update({
            tokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
        }).catch(() => undefined)));
    }
}
exports.sendDueReminders = (0, scheduler_1.onSchedule)({ schedule: `every ${WINDOW_MINUTES} minutes`, timeZone: "Asia/Tokyo", region: "asia-northeast1" }, async () => {
    const db = admin.firestore();
    const now = new Date();
    const windowEnd = new Date(now.getTime() + WINDOW_MINUTES * 60 * 1000);
    // Scale is tiny (a few dozen users) — scanning the whole collection each
    // run is far cheaper than the index/complexity of a range query here.
    const snapshot = await db.collection("schedules").get();
    const updates = [];
    for (const doc of snapshot.docs) {
        const data = doc.data();
        if (!data.reminderMinutes || data.reminderMinutes <= 0)
            continue;
        const recurrence = data.recurrence ?? "none";
        const isRecurring = recurrence !== "none";
        // Non-recurring: fires once, ever.
        if (!isRecurring) {
            if (data.lastReminderFiredAt)
                continue;
            const reminderAt = initialReminderInstant(data);
            if (reminderAt >= now && reminderAt < windowEnd) {
                updates.push(sendReminder(db, doc.id, data)
                    .then(() => doc.ref.update({ lastReminderFiredAt: admin.firestore.Timestamp.fromDate(reminderAt) }))
                    .catch((err) => logger.error(`sendDueReminders: failed for schedule ${doc.id}`, err)));
            }
            continue;
        }
        // Recurring: resume stepping from the last occurrence we already
        // notified (if any) rather than from the original anchor every run,
        // so this stays cheap no matter how old the schedule is.
        let candidate = data.lastReminderFiredAt
            ? stepWallForward(recurrence, toJstWall(data.lastReminderFiredAt.toDate()))
            : toJstWall(initialReminderInstant(data));
        let candidateInstant = fromJstWall(candidate);
        const endDate = data.recurrenceEndDate?.toDate();
        let guard = 0;
        while (candidateInstant < now && guard < 1000) {
            candidate = stepWallForward(recurrence, candidate);
            candidateInstant = fromJstWall(candidate);
            guard++;
        }
        if (endDate) {
            // recurrenceEndDate is stored as midnight JST of the end day and is
            // inclusive (see Schedule.recurrenceEndDate's doc comment on the
            // Dart side) — compare JST calendar dates, not raw instants, or the
            // end day's own occurrence (almost never exactly midnight) would
            // always be wrongly excluded.
            const eventInstant = new Date(candidateInstant.getTime() + (data.reminderMinutes ?? 0) * 60 * 1000);
            const eventDay = toJstWall(eventInstant);
            const endDay = toJstWall(endDate);
            const eventDayMs = Date.UTC(eventDay.year, eventDay.month - 1, eventDay.day);
            const endDayMs = Date.UTC(endDay.year, endDay.month - 1, endDay.day);
            if (eventDayMs > endDayMs)
                continue;
        }
        if (candidateInstant >= now && candidateInstant < windowEnd) {
            updates.push(sendReminder(db, doc.id, data)
                .then(() => doc.ref.update({ lastReminderFiredAt: admin.firestore.Timestamp.fromDate(candidateInstant) }))
                .catch((err) => logger.error(`sendDueReminders: failed for schedule ${doc.id}`, err)));
        }
    }
    await Promise.all(updates);
    logger.info(`sendDueReminders: checked ${snapshot.size} schedules, sent ${updates.length} reminders`);
});
//# sourceMappingURL=scheduledReminders.js.map