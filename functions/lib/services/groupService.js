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
exports.GroupService = void 0;
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("../utils/errors");
const validation_1 = require("../utils/validation");
class GroupService {
    static async createGroup(userId, name, description) {
        const groupRef = admin.firestore().collection("sharedGroups").doc();
        const owner = { uid: userId, role: "owner", joinedAt: admin.firestore.Timestamp.now() };
        const group = {
            id: groupRef.id, ownerId: userId, name: (0, validation_1.validateString)(name, "name", 1, 100),
            members: [owner], memberIds: [userId], createdAt: admin.firestore.Timestamp.now(), updatedAt: admin.firestore.Timestamp.now(),
            ...(description !== undefined ? { description: (0, validation_1.validateString)(description, "description", 0, 1000) } : {}),
        };
        await groupRef.set(group);
        return group;
    }
    static async getGroup(userId, groupId) {
        const document = await admin.firestore().collection("sharedGroups").doc(groupId).get();
        if (!document.exists)
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Group not found");
        const group = document.data();
        if (!group.memberIds.includes(userId))
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Access denied");
        return group;
    }
    static async updateGroup(userId, groupId, data) {
        const group = await this.getGroup(userId, groupId);
        if (group.ownerId !== userId)
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Only owner can update group");
        const update = { updatedAt: admin.firestore.Timestamp.now() };
        if (data.name !== undefined)
            update.name = (0, validation_1.validateString)(data.name, "name", 1, 100);
        if (data.description !== undefined)
            update.description = (0, validation_1.validateString)(data.description, "description", 0, 1000);
        await admin.firestore().collection("sharedGroups").doc(groupId).update(update);
        return (await admin.firestore().collection("sharedGroups").doc(groupId).get()).data();
    }
    static async deleteGroup(userId, groupId) {
        const group = await this.getGroup(userId, groupId);
        if (group.ownerId !== userId)
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Only owner can delete group");
        await admin.firestore().collection("sharedGroups").doc(groupId).delete();
    }
    static async listGroups(userId) {
        const snapshot = await admin.firestore().collection("sharedGroups").where("memberIds", "array-contains", userId).get();
        return snapshot.docs.map((document) => document.data());
    }
    static async addMember(userId, groupId, memberId, role) {
        const group = await this.getGroup(userId, groupId);
        if (group.ownerId !== userId)
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Only owner can add members");
        if (group.memberIds.includes(memberId))
            throw new errors_1.AppError(errors_1.ErrorCode.CONFLICT, 409, "User is already a member");
        await admin.firestore().collection("sharedGroups").doc(groupId).update({
            members: [...group.members, { uid: memberId, role, joinedAt: admin.firestore.Timestamp.now() }],
            memberIds: [...group.memberIds, memberId], updatedAt: admin.firestore.Timestamp.now(),
        });
    }
}
exports.GroupService = GroupService;
//# sourceMappingURL=groupService.js.map