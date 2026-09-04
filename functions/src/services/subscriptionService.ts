import * as admin from "firebase-admin";
import { Subscription } from "../types";

export interface SubscriptionPlan {
  id: "free" | "premium" | "family";
  name: string;
  monthlyPrice: number;
  currency: "JPY";
}

const PLANS: SubscriptionPlan[] = [
  { id: "free", name: "Free", monthlyPrice: 0, currency: "JPY" },
];

export class SubscriptionService {
  static getPlans(): SubscriptionPlan[] {
    return PLANS;
  }

  static async getSubscription(userId: string): Promise<Subscription> {
    const document = await admin.firestore().collection("subscriptions").doc(userId).get();
    if (document.exists) return document.data() as Subscription;

    const now = admin.firestore.Timestamp.now();
    const subscription: Subscription = {
      id: userId,
      userId,
      planId: "free",
      status: "active",
      startDate: now,
      autoRenew: false,
      createdAt: now,
      updatedAt: now,
    };
    await document.ref.set(subscription);
    return subscription;
  }

  static async hasActiveEntitlement(userId: string, planId: "premium" | "family"): Promise<boolean> {
    const subscription = await this.getSubscription(userId);
    return subscription.status === "active" && subscription.planId === planId;
  }
}