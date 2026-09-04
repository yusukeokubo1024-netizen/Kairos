import * as admin from "firebase-admin";
export declare function verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken>;
export declare function verifyOwnership(userId: string, docRef: admin.firestore.DocumentReference): Promise<boolean>;
export declare function verifyEditAccess(userId: string, docRef: admin.firestore.DocumentReference): Promise<boolean>;
export declare function verifyReadAccess(userId: string, docRef: admin.firestore.DocumentReference): Promise<boolean>;
//# sourceMappingURL=auth.d.ts.map