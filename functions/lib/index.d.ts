import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
export declare const healthCheck: functions.https.HttpsFunction;
export declare const testAuth: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    message: string;
    uid: string;
}>, unknown>;
export declare const onUserCreate: any;
export declare const onUserDelete: any;
export declare const createUserProfile: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    message: string;
    data: {
        displayName: string;
        email: any;
        photoURL: any;
        updatedAt: admin.firestore.FieldValue;
    };
}>, unknown>;
export declare const getUserProfile: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: admin.firestore.DocumentData | undefined;
}>, unknown>;
export declare const createSchedule: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    message: string;
    data: import("./types").Schedule;
}>, unknown>;
export declare const getSchedule: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Schedule;
}>, unknown>;
export declare const updateSchedule: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    message: string;
    data: import("./types").Schedule;
}>, unknown>;
export declare const deleteSchedule: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    message: string;
}>, unknown>;
export declare const listSchedules: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    count: number;
    data: import("./types").Schedule[];
}>, unknown>;
export declare const updateParticipantStatus: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    message: string;
}>, unknown>;
export declare const createTask: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Task;
}>, unknown>;
export declare const getTask: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Task;
}>, unknown>;
export declare const updateTask: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Task;
}>, unknown>;
export declare const deleteTask: functions.https.CallableFunction<any, Promise<{
    success: boolean;
}>, unknown>;
export declare const listTasks: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    count: number;
    data: import("./types").Task[];
}>, unknown>;
export declare const createGroup: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").SharedGroup;
}>, unknown>;
export declare const getGroup: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").SharedGroup;
}>, unknown>;
export declare const updateGroup: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").SharedGroup;
}>, unknown>;
export declare const deleteGroup: functions.https.CallableFunction<any, Promise<{
    success: boolean;
}>, unknown>;
export declare const listGroups: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    count: number;
    data: import("./types").SharedGroup[];
}>, unknown>;
export declare const addGroupMember: functions.https.CallableFunction<any, Promise<{
    success: boolean;
}>, unknown>;
export declare const updateLocation: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Location;
}>, unknown>;
export declare const getLocation: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Location;
}>, unknown>;
export declare const setLocationSharing: functions.https.CallableFunction<any, Promise<{
    success: boolean;
}>, unknown>;
export declare const listSharedLocations: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    count: number;
    data: import("./types").Location[];
}>, unknown>;
export declare const registerDeviceToken: functions.https.CallableFunction<any, Promise<{
    success: boolean;
}>, unknown>;
export declare const unregisterDeviceToken: functions.https.CallableFunction<any, Promise<{
    success: boolean;
}>, unknown>;
export declare const sendScheduleInvitation: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    sentCount: number;
}>, unknown>;
export declare const getSubscriptionPlans: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./services/subscriptionService").SubscriptionPlan[];
}>, unknown>;
export declare const getMySubscription: functions.https.CallableFunction<any, Promise<{
    success: boolean;
    data: import("./types").Subscription;
}>, unknown>;
//# sourceMappingURL=index.d.ts.map