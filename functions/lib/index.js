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
exports.getMySubscription = exports.getSubscriptionPlans = exports.sendScheduleInvitation = exports.unregisterDeviceToken = exports.registerDeviceToken = exports.listSharedLocations = exports.setLocationSharing = exports.getLocation = exports.updateLocation = exports.addGroupMember = exports.listGroups = exports.deleteGroup = exports.updateGroup = exports.getGroup = exports.createGroup = exports.listTasks = exports.deleteTask = exports.updateTask = exports.getTask = exports.createTask = exports.updateParticipantStatus = exports.listSchedules = exports.deleteSchedule = exports.updateSchedule = exports.getSchedule = exports.createSchedule = exports.getUserProfile = exports.createUserProfile = exports.onUserDelete = exports.onUserCreate = exports.testAuth = exports.healthCheck = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("./utils/errors");
const validation_1 = require("./utils/validation");
const scheduleService_1 = require("./services/scheduleService");
const taskService_1 = require("./services/taskService");
const groupService_1 = require("./services/groupService");
const locationService_1 = require("./services/locationService");
const notificationService_1 = require("./services/notificationService");
const subscriptionService_1 = require("./services/subscriptionService");
// For auth triggers, we need to use v1 SDK
const v1Functions = require("firebase-functions/v1");
// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();
// Health check endpoint (simple, no admin SDK)
exports.healthCheck = functions.https.onRequest((req, res) => {
    res.status(200).json({
        status: "ok",
        timestamp: new Date().toISOString(),
        message: "Cloud Functions is running!"
    });
});
// Test authentication endpoint
exports.testAuth = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
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
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// User creation trigger
exports.onUserCreate = v1Functions.auth
    .user()
    .onCreate(async (user) => {
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
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        functions.logger.error(`Error creating user ${user.uid}:`, appError);
        throw error;
    }
});
// User deletion trigger
exports.onUserDelete = v1Functions.auth
    .user()
    .onDelete(async (user) => {
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
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        functions.logger.error(`Error deleting user ${user.uid}:`, appError);
        throw error;
    }
});
// Create/Update user profile
exports.createUserProfile = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const data = request.data;
        const displayName = (0, validation_1.validateString)(data.displayName, "displayName", 1, 255);
        if (data.email) {
            (0, validation_1.validateEmail)(data.email);
        }
        const userData = {
            displayName,
            email: data.email || auth.token?.email || "",
            photoURL: data.photoURL || "",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await db.collection("users").doc(uid).update(userData);
        return {
            success: true,
            message: "User profile updated",
            data: userData,
        };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// Get user profile
exports.getUserProfile = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
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
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// ==================== SCHEDULE CRUD ====================
// Create schedule
exports.createSchedule = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const data = request.data;
        // Create schedule using service
        const schedule = await scheduleService_1.ScheduleService.createSchedule(uid, {
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
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// Get schedule
exports.getSchedule = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const scheduleId = request.data.scheduleId;
        if (!scheduleId) {
            throw new Error("scheduleId is required");
        }
        const schedule = await scheduleService_1.ScheduleService.getSchedule(uid, scheduleId);
        return {
            success: true,
            data: schedule,
        };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// Update schedule
exports.updateSchedule = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const data = request.data;
        const scheduleId = data.scheduleId;
        if (!scheduleId) {
            throw new Error("scheduleId is required");
        }
        const updatedSchedule = await scheduleService_1.ScheduleService.updateSchedule(uid, scheduleId, data);
        return {
            success: true,
            message: "Schedule updated successfully",
            data: updatedSchedule,
        };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// Delete schedule
exports.deleteSchedule = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const scheduleId = request.data.scheduleId;
        if (!scheduleId) {
            throw new Error("scheduleId is required");
        }
        await scheduleService_1.ScheduleService.deleteSchedule(uid, scheduleId);
        return {
            success: true,
            message: "Schedule deleted successfully",
        };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// List schedules
exports.listSchedules = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const data = request.data;
        const schedules = await scheduleService_1.ScheduleService.listSchedules(uid, {
            startDate: data.startDate,
            endDate: data.endDate,
            limit: data.limit || 100,
        });
        return {
            success: true,
            count: schedules.length,
            data: schedules,
        };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// Update participant status
exports.updateParticipantStatus = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        const auth = request.auth;
        if (!auth) {
            throw new Error("Unauthenticated");
        }
        const uid = auth.uid;
        const data = request.data;
        const scheduleId = data.scheduleId;
        const status = data.status;
        if (!scheduleId || !status) {
            throw new Error("scheduleId and status are required");
        }
        if (!["accepted", "declined", "tentative"].includes(status)) {
            throw new Error("Invalid status");
        }
        await scheduleService_1.ScheduleService.updateParticipantStatus(uid, scheduleId, status);
        return {
            success: true,
            message: "Participant status updated successfully",
        };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// ==================== TASK CRUD ====================
exports.createTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        return { success: true, data: await taskService_1.TaskService.createTask(request.auth.uid, data) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.getTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const taskId = request.data.taskId;
        if (!taskId)
            throw new Error("taskId is required");
        return { success: true, data: await taskService_1.TaskService.getTask(request.auth.uid, taskId) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.updateTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        if (!data.taskId)
            throw new Error("taskId is required");
        return { success: true, data: await taskService_1.TaskService.updateTask(request.auth.uid, data.taskId, data) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.deleteTask = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const taskId = request.data.taskId;
        if (!taskId)
            throw new Error("taskId is required");
        await taskService_1.TaskService.deleteTask(request.auth.uid, taskId);
        return { success: true };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.listTasks = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const completed = request.data.completed;
        if (completed !== undefined && typeof completed !== "boolean")
            throw new Error("completed must be a boolean");
        const tasks = await taskService_1.TaskService.listTasks(request.auth.uid, completed);
        return { success: true, count: tasks.length, data: tasks };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// ==================== GROUP SHARING ====================
exports.createGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        return { success: true, data: await groupService_1.GroupService.createGroup(request.auth.uid, data.name, data.description) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.getGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const groupId = request.data.groupId;
        if (!groupId)
            throw new Error("groupId is required");
        return { success: true, data: await groupService_1.GroupService.getGroup(request.auth.uid, groupId) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.updateGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        if (!data.groupId)
            throw new Error("groupId is required");
        return { success: true, data: await groupService_1.GroupService.updateGroup(request.auth.uid, data.groupId, data) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.deleteGroup = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const groupId = request.data.groupId;
        if (!groupId)
            throw new Error("groupId is required");
        await groupService_1.GroupService.deleteGroup(request.auth.uid, groupId);
        return { success: true };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.listGroups = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const groups = await groupService_1.GroupService.listGroups(request.auth.uid);
        return { success: true, count: groups.length, data: groups };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.addGroupMember = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        if (!data.groupId || !data.memberId || !["editor", "viewer"].includes(data.role))
            throw new Error("groupId, memberId, and a valid role are required");
        await groupService_1.GroupService.addMember(request.auth.uid, data.groupId, data.memberId, data.role);
        return { success: true };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// ==================== LOCATION SHARING ====================
exports.updateLocation = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        return { success: true, data: await locationService_1.LocationService.updateLocation(request.auth.uid, data.latitude, data.longitude, data.accuracy) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.getLocation = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const userId = request.data.userId || request.auth.uid;
        return { success: true, data: await locationService_1.LocationService.getLocation(request.auth.uid, userId) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.setLocationSharing = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        await locationService_1.LocationService.setSharedWith(request.auth.uid, request.data.sharedWith);
        return { success: true };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.listSharedLocations = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const locations = await locationService_1.LocationService.listSharedLocations(request.auth.uid);
        return { success: true, count: locations.length, data: locations };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// ==================== NOTIFICATIONS ====================
exports.registerDeviceToken = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        await notificationService_1.NotificationService.registerToken(request.auth.uid, request.data.token);
        return { success: true };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.unregisterDeviceToken = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        await notificationService_1.NotificationService.unregisterToken(request.auth.uid, request.data.token);
        return { success: true };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
exports.sendScheduleInvitation = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        const data = request.data;
        if (!data.scheduleId || !data.title || !Array.isArray(data.participantIds))
            throw new Error("scheduleId, title, and participantIds are required");
        await notificationService_1.NotificationService.assertScheduleOwner(request.auth.uid, data.scheduleId);
        const sentCount = await notificationService_1.NotificationService.sendScheduleInvitation(request.auth.uid, data.participantIds, data.scheduleId, data.title);
        return { success: true, sentCount };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
// ==================== SUBSCRIPTIONS ====================
exports.getSubscriptionPlans = functions.https.onCall({ enforceAppCheck: false }, async () => ({ success: true, data: subscriptionService_1.SubscriptionService.getPlans() }));
exports.getMySubscription = functions.https.onCall({ enforceAppCheck: false }, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthenticated");
        return { success: true, data: await subscriptionService_1.SubscriptionService.getSubscription(request.auth.uid) };
    }
    catch (error) {
        const appError = (0, errors_1.handleError)(error);
        throw new functions.https.HttpsError("internal", appError.message);
    }
});
//# sourceMappingURL=index.js.map