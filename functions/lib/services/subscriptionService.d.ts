import { Subscription } from "../types";
export interface SubscriptionPlan {
    id: "free" | "premium" | "family";
    name: string;
    monthlyPrice: number;
    currency: "JPY";
}
export declare class SubscriptionService {
    static getPlans(): SubscriptionPlan[];
    static getSubscription(userId: string): Promise<Subscription>;
    static hasActiveEntitlement(userId: string, planId: "premium" | "family"): Promise<boolean>;
}
//# sourceMappingURL=subscriptionService.d.ts.map