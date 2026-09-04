import * as admin from "firebase-admin";
import { Task } from "../types";
import { AppError, ErrorCode } from "../utils/errors";
import { validateEnum, validateString } from "../utils/validation";

export class TaskService {
  static async createTask(
    userId: string,
    data: Omit<Task, "id" | "ownerId" | "createdAt" | "updatedAt" | "completed">
  ): Promise<Task> {
    const db = admin.firestore();
    const taskRef = db.collection("tasks").doc();
    const task: Task = {
      id: taskRef.id,
      ownerId: userId,
      title: validateString(data.title, "title", 1, 255),
      priority: validateEnum(data.priority, "priority", ["low", "medium", "high"]) as Task["priority"],
      completed: false,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
      ...(data.description !== undefined ? { description: validateString(data.description, "description", 0, 1000) } : {}),
      ...(data.dueDate !== undefined ? { dueDate: data.dueDate } : {}),
      ...(data.category !== undefined ? { category: validateString(data.category, "category", 1, 100) } : {}),
      ...(data.tags !== undefined ? { tags: data.tags } : {}),
    };
    await taskRef.set(task);
    return task;
  }

  static async getTask(userId: string, taskId: string): Promise<Task> {
    const taskDoc = await admin.firestore().collection("tasks").doc(taskId).get();
    if (!taskDoc.exists) throw new AppError(ErrorCode.NOT_FOUND, 404, "Task not found");
    const task = taskDoc.data() as Task;
    if (task.ownerId !== userId) throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Access denied");
    return task;
  }

  static async updateTask(userId: string, taskId: string, data: Partial<Task>): Promise<Task> {
    const task = await this.getTask(userId, taskId);
    const update: admin.firestore.UpdateData<Task> = {
      updatedAt: admin.firestore.Timestamp.now(),
    };
    if (data.title !== undefined) update.title = validateString(data.title, "title", 1, 255);
    if (data.description !== undefined) update.description = validateString(data.description, "description", 0, 1000);
    if (data.dueDate !== undefined) update.dueDate = data.dueDate;
    if (data.priority !== undefined) {
      update.priority = validateEnum(data.priority, "priority", ["low", "medium", "high"]) as Task["priority"];
    }
    if (data.completed !== undefined) update.completed = data.completed;
    if (data.category !== undefined) update.category = validateString(data.category, "category", 1, 100);
    if (data.tags !== undefined) update.tags = data.tags;
    await admin.firestore().collection("tasks").doc(task.id).update(update);
    return (await admin.firestore().collection("tasks").doc(task.id).get()).data() as Task;
  }

  static async deleteTask(userId: string, taskId: string): Promise<void> {
    await this.getTask(userId, taskId);
    await admin.firestore().collection("tasks").doc(taskId).delete();
  }

  static async listTasks(userId: string, completed?: boolean): Promise<Task[]> {
    let query: admin.firestore.Query = admin.firestore().collection("tasks").where("ownerId", "==", userId);
    if (completed !== undefined) query = query.where("completed", "==", completed);
    const snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Task);
  }
}