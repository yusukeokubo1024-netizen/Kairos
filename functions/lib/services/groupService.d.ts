import { SharedGroup } from "../types";
export declare class GroupService {
    static createGroup(userId: string, name: string, description?: string): Promise<SharedGroup>;
    static getGroup(userId: string, groupId: string): Promise<SharedGroup>;
    static updateGroup(userId: string, groupId: string, data: Pick<SharedGroup, "name" | "description">): Promise<SharedGroup>;
    static deleteGroup(userId: string, groupId: string): Promise<void>;
    static listGroups(userId: string): Promise<SharedGroup[]>;
    static addMember(userId: string, groupId: string, memberId: string, role: "editor" | "viewer"): Promise<void>;
}
//# sourceMappingURL=groupService.d.ts.map