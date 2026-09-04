import * as admin from "firebase-admin";
import { AppError, ErrorCode } from "./errors";

export async function verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    throw new AppError(
      ErrorCode.AUTHENTICATION_ERROR,
      401,
      "Invalid or expired ID token"
    );
  }
}

export async function verifyOwnership(
  userId: string,
  docRef: admin.firestore.DocumentReference
): Promise<boolean> {
  try {
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new AppError(ErrorCode.NOT_FOUND, 404, "Document not found");
    }

    const data = doc.data() as { ownerId?: string };
    return data.ownerId === userId;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(
      ErrorCode.INTERNAL_ERROR,
      500,
      "Error verifying ownership"
    );
  }
}

export async function verifyEditAccess(
  userId: string,
  docRef: admin.firestore.DocumentReference
): Promise<boolean> {
  try {
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new AppError(ErrorCode.NOT_FOUND, 404, "Document not found");
    }

    const data = doc.data() as {
      ownerId?: string;
      participants?: Array<{ uid: string; role?: string }>;
    };

    // Owner has full access
    if (data.ownerId === userId) return true;

    // Check participant access with editor role
    if (data.participants) {
      const participant = data.participants.find((p) => p.uid === userId);
      return participant?.role === "editor" || !participant;
    }

    return false;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(
      ErrorCode.INTERNAL_ERROR,
      500,
      "Error verifying access"
    );
  }
}

export async function verifyReadAccess(
  userId: string,
  docRef: admin.firestore.DocumentReference
): Promise<boolean> {
  try {
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new AppError(ErrorCode.NOT_FOUND, 404, "Document not found");
    }

    const data = doc.data() as {
      ownerId?: string;
      participants?: Array<{ uid: string }>;
    };

    // Owner has full access
    if (data.ownerId === userId) return true;

    // Check if user is a participant
    if (data.participants) {
      return data.participants.some((p) => p.uid === userId);
    }

    return false;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(
      ErrorCode.INTERNAL_ERROR,
      500,
      "Error verifying access"
    );
  }
}
