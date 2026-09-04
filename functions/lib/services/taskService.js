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
exports.TaskService = void 0;
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("../utils/errors");
const validation_1 = require("../utils/validation");
class TaskService {
    static async createTask(userId, data) {
        const db = admin.firestore();
        const taskRef = db.collection("tasks").doc();
        const task = {
            id: taskRef.id,
            ownerId: userId,
            title: (0, validation_1.validateString)(data.title, "title", 1, 255),
            priority: (0, validation_1.validateEnum)(data.priority, "priority", ["low", "medium", "high"]),
            completed: false,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
            ...(data.description !== undefined ? { description: (0, validation_1.validateString)(data.description, "description", 0, 1000) } : {}),
            ...(data.dueDate !== undefined ? { dueDate: data.dueDate } : {}),
            ...(data.category !== undefined ? { category: (0, validation_1.validateString)(data.category, "category", 1, 100) } : {}),
            ...(data.tags !== undefined ? { tags: data.tags } : {}),
        };
        await taskRef.set(task);
        return task;
    }
    static async getTask(userId, taskId) {
        const taskDoc = await admin.firestore().collection("tasks").doc(taskId).get();
        if (!taskDoc.exists)
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Task not found");
        const task = taskDoc.data();
        if (task.ownerId !== userId)
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Access denied");
        return task;
    }
    static async updateTask(userId, taskId, data) {
        const task = await this.getTask(userId, taskId);
        const update = {
            updatedAt: admin.firestore.Timestamp.now(),
        };
        if (data.title !== undefined)
            update.title = (0, validation_1.validateString)(data.title, "title", 1, 255);
        if (data.description !== undefined)
            update.description = (0, validation_1.validateString)(data.description, "description", 0, 1000);
        if (data.dueDate !== undefined)
            update.dueDate = data.dueDate;
        if (data.priority !== undefined) {
            update.priority = (0, validation_1.validateEnum)(data.priority, "priority", ["low", "medium", "high"]);
        }
        if (data.completed !== undefined)
            update.completed = data.completed;
        if (data.category !== undefined)
            update.category = (0, validation_1.validateString)(data.category, "category", 1, 100);
        if (data.tags !== undefined)
            update.tags = data.tags;
        await admin.firestore().collection("tasks").doc(task.id).update(update);
        return (await admin.firestore().collection("tasks").doc(task.id).get()).data();
    }
    static async deleteTask(userId, taskId) {
        await this.getTask(userId, taskId);
        await admin.firestore().collection("tasks").doc(taskId).delete();
    }
    static async listTasks(userId, completed) {
        let query = admin.firestore().collection("tasks").where("ownerId", "==", userId);
        if (completed !== undefined)
            query = query.where("completed", "==", completed);
        const snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data());
    }
}
exports.TaskService = TaskService;
//# sourceMappingURL=taskService.js.map