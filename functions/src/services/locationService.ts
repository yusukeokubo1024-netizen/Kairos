import * as admin from "firebase-admin";
import { Location } from "../types";
import { AppError, ErrorCode } from "../utils/errors";
import { validateArray, validateNumber } from "../utils/validation";

export class LocationService {
  static async updateLocation(userId: string, latitude: unknown, longitude: unknown, accuracy?: unknown): Promise<Location> {
    const location: Location = {
      id: userId,
      userId,
      latitude: validateNumber(latitude, "latitude", -90, 90),
      longitude: validateNumber(longitude, "longitude", -180, 180),
      timestamp: admin.firestore.Timestamp.now(),
      ...(accuracy !== undefined ? { accuracy: validateNumber(accuracy, "accuracy", 0, 100000) } : {}),
    };
    const reference = admin.firestore().collection("locations").doc(userId);
    const existing = await reference.get();
    if (existing.exists) location.sharedWith = (existing.data() as Location).sharedWith || [];
    await reference.set(location);
    return location;
  }

  static async getLocation(requesterId: string, userId: string): Promise<Location> {
    const document = await admin.firestore().collection("locations").doc(userId).get();
    if (!document.exists) throw new AppError(ErrorCode.NOT_FOUND, 404, "Location not found");
    const location = document.data() as Location;
    if (requesterId !== userId && !location.sharedWith?.includes(requesterId)) {
      throw new AppError(ErrorCode.PERMISSION_DENIED, 403, "Location is not shared with this user");
    }
    return location;
  }

  static async setSharedWith(userId: string, sharedWith: unknown): Promise<void> {
    const userIds = validateArray(sharedWith, "sharedWith");
    if (!userIds.every((item) => typeof item === "string" && item.length > 0)) {
      throw new AppError(ErrorCode.VALIDATION_ERROR, 400, "sharedWith must contain user IDs");
    }
    const reference = admin.firestore().collection("locations").doc(userId);
    if (!(await reference.get()).exists) throw new AppError(ErrorCode.NOT_FOUND, 404, "Location not found");
    await reference.update({ sharedWith: [...new Set(userIds as string[])] });
  }

  static async listSharedLocations(userId: string): Promise<Location[]> {
    const snapshot = await admin.firestore().collection("locations").where("sharedWith", "array-contains", userId).get();
    return snapshot.docs.map((document) => document.data() as Location);
  }
}