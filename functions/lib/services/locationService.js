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
exports.LocationService = void 0;
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("../utils/errors");
const validation_1 = require("../utils/validation");
class LocationService {
    static async updateLocation(userId, latitude, longitude, accuracy) {
        const location = {
            id: userId,
            userId,
            latitude: (0, validation_1.validateNumber)(latitude, "latitude", -90, 90),
            longitude: (0, validation_1.validateNumber)(longitude, "longitude", -180, 180),
            timestamp: admin.firestore.Timestamp.now(),
            ...(accuracy !== undefined ? { accuracy: (0, validation_1.validateNumber)(accuracy, "accuracy", 0, 100000) } : {}),
        };
        const reference = admin.firestore().collection("locations").doc(userId);
        const existing = await reference.get();
        if (existing.exists)
            location.sharedWith = existing.data().sharedWith || [];
        await reference.set(location);
        return location;
    }
    static async getLocation(requesterId, userId) {
        const document = await admin.firestore().collection("locations").doc(userId).get();
        if (!document.exists)
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Location not found");
        const location = document.data();
        if (requesterId !== userId && !location.sharedWith?.includes(requesterId)) {
            throw new errors_1.AppError(errors_1.ErrorCode.PERMISSION_DENIED, 403, "Location is not shared with this user");
        }
        return location;
    }
    static async setSharedWith(userId, sharedWith) {
        const userIds = (0, validation_1.validateArray)(sharedWith, "sharedWith");
        if (!userIds.every((item) => typeof item === "string" && item.length > 0)) {
            throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, "sharedWith must contain user IDs");
        }
        const reference = admin.firestore().collection("locations").doc(userId);
        if (!(await reference.get()).exists)
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Location not found");
        await reference.update({ sharedWith: [...new Set(userIds)] });
    }
    static async listSharedLocations(userId) {
        const snapshot = await admin.firestore().collection("locations").where("sharedWith", "array-contains", userId).get();
        return snapshot.docs.map((document) => document.data());
    }
}
exports.LocationService = LocationService;
//# sourceMappingURL=locationService.js.map