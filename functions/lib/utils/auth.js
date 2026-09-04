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
exports.verifyIdToken = verifyIdToken;
exports.verifyOwnership = verifyOwnership;
exports.verifyEditAccess = verifyEditAccess;
exports.verifyReadAccess = verifyReadAccess;
const admin = __importStar(require("firebase-admin"));
const errors_1 = require("./errors");
async function verifyIdToken(idToken) {
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        return decodedToken;
    }
    catch (error) {
        throw new errors_1.AppError(errors_1.ErrorCode.AUTHENTICATION_ERROR, 401, "Invalid or expired ID token");
    }
}
async function verifyOwnership(userId, docRef) {
    try {
        const doc = await docRef.get();
        if (!doc.exists) {
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Document not found");
        }
        const data = doc.data();
        return data.ownerId === userId;
    }
    catch (error) {
        if (error instanceof errors_1.AppError)
            throw error;
        throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Error verifying ownership");
    }
}
async function verifyEditAccess(userId, docRef) {
    try {
        const doc = await docRef.get();
        if (!doc.exists) {
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Document not found");
        }
        const data = doc.data();
        // Owner has full access
        if (data.ownerId === userId)
            return true;
        // Check participant access with editor role
        if (data.participants) {
            const participant = data.participants.find((p) => p.uid === userId);
            return participant?.role === "editor" || !participant;
        }
        return false;
    }
    catch (error) {
        if (error instanceof errors_1.AppError)
            throw error;
        throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Error verifying access");
    }
}
async function verifyReadAccess(userId, docRef) {
    try {
        const doc = await docRef.get();
        if (!doc.exists) {
            throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, 404, "Document not found");
        }
        const data = doc.data();
        // Owner has full access
        if (data.ownerId === userId)
            return true;
        // Check if user is a participant
        if (data.participants) {
            return data.participants.some((p) => p.uid === userId);
        }
        return false;
    }
    catch (error) {
        if (error instanceof errors_1.AppError)
            throw error;
        throw new errors_1.AppError(errors_1.ErrorCode.INTERNAL_ERROR, 500, "Error verifying access");
    }
}
//# sourceMappingURL=auth.js.map