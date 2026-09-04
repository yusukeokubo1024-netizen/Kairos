import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { handleError } from "./utils/errors";
import { validateString, validateEmail } from "./utils/validation";
import { ScheduleService } from "./services/scheduleService";
import { TaskService } from "./services/taskService";
import { GroupService } from "./services/groupService";
import { LocationService } from "./services/locationService";
import { NotificationService } from "./services/notificationService";
import { SubscriptionService } from "./services/subscriptionService";

// For auth triggers, we need to use v1 SDK
const v1Functions = require("firebase-functions/v1");

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();

// Health check endpoint (simple, no admin SDK)
export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({ 
    status: "ok", 
    timestamp: new Date().toISOString(),
    message: "Cloud Functions is running!"
  });
});

// Test authentication endpoint
export const testAuth = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      return {
        success: true,
        message: `Authenticated as ${uid}`,
        uid,
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// User creation trigger
export const onUserCreate = v1Functions.auth
  .user()
  .onCreate(async (user: admin.auth.UserRecord) => {
    try {
      const userData = {
        uid: user.uid,
        email: user.email || "",
        displayName: user.displayName || "",
        photoURL: user.photoURL || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        preferences: {
          language: "ja",
          timeZone: "Asia/Tokyo",
          notificationsEnabled: true,
        },
      };

      await db.collection("users").doc(user.uid).set(userData);

      // Create initial subscription (free plan)
      await db
        .collection("subscriptions")
        .doc(user.uid)
        .set({
          userId: user.uid,
          planId: "free",
          status: "active",
          startDate: admin.firestore.FieldValue.serverTimestamp(),
          autoRenew: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      functions.logger.info(`User ${user.uid} created successfully`);
    } catch (error) {
      const appError = handleError(error);
      functions.logger.error(`Error creating user ${user.uid}:`, appError);
      throw error;
    }
  });

// User deletion trigger
export const onUserDelete = v1Functions.auth
  .user()
  .onDelete(async (user: admin.auth.UserRecord) => {
    try {
      // Delete user document
      await db.collection("users").doc(user.uid).delete();

      // Delete all user's schedules
      const schedules = await db
        .collection("schedules")
        .where("ownerId", "==", user.uid)
        .get();

      const batch = db.batch();
      schedules.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      // Delete all user's tasks
      const tasks = await db
        .collection("tasks")
        .where("ownerId", "==", user.uid)
        .get();

      const taskBatch = db.batch();
      tasks.docs.forEach((doc) => {
        taskBatch.delete(doc.ref);
      });
      await taskBatch.commit();

      // Delete all user's groups
      const groups = await db
        .collection("sharedGroups")
        .where("ownerId", "==", user.uid)
        .get();

      const groupBatch = db.batch();
      groups.docs.forEach((doc) => {
        groupBatch.delete(doc.ref);
      });
      await groupBatch.commit();

      functions.logger.info(`User ${user.uid} and related data deleted`);
    } catch (error) {
      const appError = handleError(error);
      functions.logger.error(`Error deleting user ${user.uid}:`, appError);
      throw error;
    }
  });

// Create/Update user profile
export const createUserProfile = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const data = request.data as any;

      const displayName = validateString(
        data.displayName,
        "displayName",
        1,
        255
      );
      if (data.email) {
        validateEmail(data.email);
      }

      const userData = {
        displayName,
        email: data.email || (auth.token?.email as string) || "",
        photoURL: data.photoURL || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db.collection("users").doc(uid).update(userData);

      return {
        success: true,
        message: "User profile updated",
        data: userData,
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// Get user profile
export const getUserProfile = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const userDoc = await db.collection("users").doc(uid).get();

      if (!userDoc.exists) {
        throw new Error("User not found");
      }

      return {
        success: true,
        data: userDoc.data(),
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// ==================== SCHEDULE CRUD ====================

// Create schedule
export const createSchedule = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const data = request.data as any;

      // Create schedule using service
      const schedule = await ScheduleService.createSchedule(uid, {
        title: data.title,
        description: data.description,
        startTime: data.startTime,
        endTime: data.endTime,
        location: data.location,
        color: data.color,
        participants: data.participants,
      });

      return {
        success: true,
        message: "Schedule created successfully",
        data: schedule,
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// Get schedule
export const getSchedule = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const scheduleId = (request.data as any).scheduleId;

      if (!scheduleId) {
        throw new Error("scheduleId is required");
      }

      const schedule = await ScheduleService.getSchedule(uid, scheduleId);

      return {
        success: true,
        data: schedule,
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// Update schedule
export const updateSchedule = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const data = request.data as any;
      const scheduleId = data.scheduleId;

      if (!scheduleId) {
        throw new Error("scheduleId is required");
      }

      const updatedSchedule = await ScheduleService.updateSchedule(
        uid,
        scheduleId,
        data
      );

      return {
        success: true,
        message: "Schedule updated successfully",
        data: updatedSchedule,
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// Delete schedule
export const deleteSchedule = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const scheduleId = (request.data as any).scheduleId;

      if (!scheduleId) {
        throw new Error("scheduleId is required");
      }

      await ScheduleService.deleteSchedule(uid, scheduleId);

      return {
        success: true,
        message: "Schedule deleted successfully",
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// List schedules
export const listSchedules = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const data = request.data as any;

      const schedules = await ScheduleService.listSchedules(uid, {
        startDate: data.startDate,
        endDate: data.endDate,
        limit: data.limit || 100,
      });

      return {
        success: true,
        count: schedules.length,
        data: schedules,
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// Update participant status
export const updateParticipantStatus = functions.https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    try {
      const auth = request.auth;
      if (!auth) {
        throw new Error("Unauthenticated");
      }

      const uid = auth.uid;
      const data = request.data as any;
      const scheduleId = data.scheduleId;
      const status = data.status;

      if (!scheduleId || !status) {
        throw new Error("scheduleId and status are required");
      }

      if (!["accepted", "declined", "tentative"].includes(status)) {
        throw new Error("Invalid status");
      }

      await ScheduleService.updateParticipantStatus(
        uid,
        scheduleId,
        status
      );

      return {
        success: true,
        message: "Participant status updated successfully",
      };
    } catch (error) {
      const appError = handleError(error);
      throw new functions.https.HttpsError(
        "internal" as any,
        appError.message
      );
    }
  }
);

// ==================== TASK CRUD ====================

export const createTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    const data = request.data as any;
    return { success: true, data: await TaskService.createTask(request.auth.uid, data) };
  } catch (error) {
    const appError = handleError(error);
    throw new functions.https.HttpsError("internal" as any, appError.message);
  }
});

export const getTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    const taskId = (request.data as any).taskId;
    if (!taskId) throw new Error("taskId is required");
    return { success: true, data: await TaskService.getTask(request.auth.uid, taskId) };
  } catch (error) {
    const appError = handleError(error);
    throw new functions.https.HttpsError("internal" as any, appError.message);
  }
});

export const updateTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    const data = request.data as any;
    if (!data.taskId) throw new Error("taskId is required");
    return { success: true, data: await TaskService.updateTask(request.auth.uid, data.taskId, data) };
  } catch (error) {
    const appError = handleError(error);
    throw new functions.https.HttpsError("internal" as any, appError.message);
  }
});

export const deleteTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    const taskId = (request.data as any).taskId;
    if (!taskId) throw new Error("taskId is required");
    await TaskService.deleteTask(request.auth.uid, taskId);
    return { success: true };
  } catch (error) {
    const appError = handleError(error);
    throw new functions.https.HttpsError("internal" as any, appError.message);
  }
});

export const listTasks = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    const completed = (request.data as any).completed;
    if (completed !== undefined && typeof completed !== "boolean") throw new Error("completed must be a boolean");
    const tasks = await TaskService.listTasks(request.auth.uid, completed);
    return { success: true, count: tasks.length, data: tasks };
  } catch (error) {
    const appError = handleError(error);
    throw new functions.https.HttpsError("internal" as any, appError.message);
  }
});

// ==================== GROUP SHARING ====================

export const createGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const data = request.data as any; return { success: true, data: await GroupService.createGroup(request.auth.uid, data.name, data.description) }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const getGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const groupId = (request.data as any).groupId; if (!groupId) throw new Error("groupId is required"); return { success: true, data: await GroupService.getGroup(request.auth.uid, groupId) }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const updateGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const data = request.data as any; if (!data.groupId) throw new Error("groupId is required"); return { success: true, data: await GroupService.updateGroup(request.auth.uid, data.groupId, data) }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const deleteGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const groupId = (request.data as any).groupId; if (!groupId) throw new Error("groupId is required"); await GroupService.deleteGroup(request.auth.uid, groupId); return { success: true }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const listGroups = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const groups = await GroupService.listGroups(request.auth.uid); return { success: true, count: groups.length, data: groups }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const addGroupMember = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const data = request.data as any; if (!data.groupId || !data.memberId || !["editor", "viewer"].includes(data.role)) throw new Error("groupId, memberId, and a valid role are required"); await GroupService.addMember(request.auth.uid, data.groupId, data.memberId, data.role); return { success: true }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

// ==================== LOCATION SHARING ====================

export const updateLocation = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const data = request.data as any; return { success: true, data: await LocationService.updateLocation(request.auth.uid, data.latitude, data.longitude, data.accuracy) }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const getLocation = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const userId = (request.data as any).userId || request.auth.uid; return { success: true, data: await LocationService.getLocation(request.auth.uid, userId) }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const setLocationSharing = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); await LocationService.setSharedWith(request.auth.uid, (request.data as any).sharedWith); return { success: true }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const listSharedLocations = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); const locations = await LocationService.listSharedLocations(request.auth.uid); return { success: true, count: locations.length, data: locations }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

// ==================== NOTIFICATIONS ====================

export const registerDeviceToken = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); await NotificationService.registerToken(request.auth.uid, (request.data as any).token); return { success: true }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const unregisterDeviceToken = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try { if (!request.auth) throw new Error("Unauthenticated"); await NotificationService.unregisterToken(request.auth.uid, (request.data as any).token); return { success: true }; }
  catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

export const sendScheduleInvitation = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    const data = request.data as any;
    if (!data.scheduleId || !data.title || !Array.isArray(data.participantIds)) throw new Error("scheduleId, title, and participantIds are required");
    await NotificationService.assertScheduleOwner(request.auth.uid, data.scheduleId);
    const sentCount = await NotificationService.sendScheduleInvitation(request.auth.uid, data.participantIds, data.scheduleId, data.title);
    return { success: true, sentCount };
  } catch (error) { const appError = handleError(error); throw new functions.https.HttpsError("internal" as any, appError.message); }
});

// ==================== SUBSCRIPTIONS ====================

export const getSubscriptionPlans = functions.https.onCall(
  { enforceAppCheck: false },
  async () => ({ success: true, data: SubscriptionService.getPlans() })
);

export const getMySubscription = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthenticated");
    return { success: true, data: await SubscriptionService.getSubscription(request.auth.uid) };
  } catch (error) {
    const appError = handleError(error);
    throw new functions.https.HttpsError("internal" as any, appError.message);
  }
});
