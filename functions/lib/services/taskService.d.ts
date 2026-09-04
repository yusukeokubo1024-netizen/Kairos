import { Task } from "../types";
export declare class TaskService {
    static createTask(userId: string, data: Omit<Task, "id" | "ownerId" | "createdAt" | "updatedAt" | "completed">): Promise<Task>;
    static getTask(userId: string, taskId: string): Promise<Task>;
    static updateTask(userId: string, taskId: string, data: Partial<Task>): Promise<Task>;
    static deleteTask(userId: string, taskId: string): Promise<void>;
    static listTasks(userId: string, completed?: boolean): Promise<Task[]>;
}
//# sourceMappingURL=taskService.d.ts.map