// User data model
export interface User {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  preferences?: {
    language: string;
    timeZone: string;
    notificationsEnabled: boolean;
  };
}

// Schedule data model
export interface Schedule {
  id: string;
  ownerId: string;
  title: string;
  description?: string;
  startTime: admin.firestore.Timestamp;
  endTime: admin.firestore.Timestamp;
  location?: string;
  color?: string;
  participants: ParticipantInfo[];
  participantIds: string[];
  comments?: CommentData[];
  images?: ImageData[];
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

export interface ParticipantInfo {
  uid: string;
  status: "invited" | "accepted" | "declined" | "tentative";
  addedAt: admin.firestore.Timestamp;
}

export interface CommentData {
  id: string;
  userId: string;
  text: string;
  createdAt: admin.firestore.Timestamp;
}

export interface ImageData {
  id: string;
  url: string;
  uploadedBy: string;
  uploadedAt: admin.firestore.Timestamp;
}

// Task data model
export interface Task {
  id: string;
  ownerId: string;
  title: string;
  description?: string;
  dueDate?: admin.firestore.Timestamp;
  priority: "low" | "medium" | "high";
  completed: boolean;
  category?: string;
  tags?: string[];
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// Shared Group data model
export interface SharedGroup {
  id: string;
  ownerId: string;
  name: string;
  description?: string;
  members: GroupMember[];
  memberIds: string[];
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

export interface GroupMember {
  uid: string;
  role: "owner" | "editor" | "viewer";
  joinedAt: admin.firestore.Timestamp;
}

// Location data model
export interface Location {
  id: string;
  userId: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp: admin.firestore.Timestamp;
  sharedWith?: string[]; // UIDs who can see this location
}

// Purchase data model
export interface Purchase {
  id: string;
  userId: string;
  planId: string;
  amount: number;
  currency: string;
  status: "pending" | "completed" | "failed" | "refunded";
  transactionId?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// Subscription data model
export interface Subscription {
  id: string;
  userId: string;
  planId: "free" | "premium" | "family";
  status: "active" | "cancelled" | "expired";
  startDate: admin.firestore.Timestamp;
  endDate?: admin.firestore.Timestamp;
  autoRenew: boolean;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

import * as admin from "firebase-admin";
