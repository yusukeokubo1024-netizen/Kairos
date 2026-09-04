import * as admin from "firebase-admin";
import { GroupMember, SharedGroup } from "../types";
import { AppError, ErrorCode } from "../utils/errors";
import { validateString } from "../utils/validation";

export class GroupService {
  static async createGroup(userId: string, name: string, description?: string): Promise<SharedGroup> {
    const groupRef = admin.firestore().collection("sharedGroups").doc();
    const owner: GroupMember = { uid: userId, role: "owner", joinedAt: admin.firestore.Timestamp.now() };
    const group: SharedGroup = {
      id: groupRef.id, ownerId: userId, name: validateString(name, "name", 1, 100),
      members: [owner], memberIds: [userId], createdAt: admin.firestore.Timestamp.now(), updatedAt: admin.firestore.Timestamp.now(),
      ...(description !== undefined ? { description: validateString(description, "description", 0, 1000) } : {}),
    };
    await groupRef.set(group);
    return group;
  }

  static async getGroup(userId: string, groupId: string): Promise<SharedGroup> {
    const document = await admin.firestore().collection("sharedGroups").doc(groupId).get();
    if (!document.exists) throw new AppError(ErrorCode.NOT_FOUND, 404, "Group not found");
    const group = document.data() as SharedGroup;
    if (!group.memberIds.includes(userId)) throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Access denied");
    return group;
  }

  static async updateGroup(userId: string, groupId: string, data: Pick<SharedGroup, "name" | "description">): Promise<SharedGroup> {
    const group = await this.getGroup(userId, groupId);
    if (group.ownerId !== userId) throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Only owner can update group");
    const update: admin.firestore.UpdateData<SharedGroup> = { updatedAt: admin.firestore.Timestamp.now() };
    if (data.name !== undefined) update.name = validateString(data.name, "name", 1, 100);
    if (data.description !== undefined) update.description = validateString(data.description, "description", 0, 1000);
    await admin.firestore().collection("sharedGroups").doc(groupId).update(update);
    return (await admin.firestore().collection("sharedGroups").doc(groupId).get()).data() as SharedGroup;
  }

  static async deleteGroup(userId: string, groupId: string): Promise<void> {
    const group = await this.getGroup(userId, groupId);
    if (group.ownerId !== userId) throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Only owner can delete group");
    await admin.firestore().collection("sharedGroups").doc(groupId).delete();
  }

  static async listGroups(userId: string): Promise<SharedGroup[]> {
    const snapshot = await admin.firestore().collection("sharedGroups").where("memberIds", "array-contains", userId).get();
    return snapshot.docs.map((document) => document.data() as SharedGroup);
  }

  static async addMember(userId: string, groupId: string, memberId: string, role: "editor" | "viewer"): Promise<void> {
    const group = await this.getGroup(userId, groupId);
    if (group.ownerId !== userId) throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Only owner can add members");
    if (group.memberIds.includes(memberId)) throw new AppError(ErrorCode.CONFLICT, 409, "User is already a member");
    await admin.firestore().collection("sharedGroups").doc(groupId).update({
      members: [...group.members, { uid: memberId, role, joinedAt: admin.firestore.Timestamp.now() }],
      memberIds: [...group.memberIds, memberId], updatedAt: admin.firestore.Timestamp.now(),
    });
  }
}