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
exports.SubscriptionService = void 0;
const admin = __importStar(require("firebase-admin"));
const PLANS = [
    { id: "free", name: "Free", monthlyPrice: 0, currency: "JPY" },
];
class SubscriptionService {
    static getPlans() {
        return PLANS;
    }
    static async getSubscription(userId) {
        const document = await admin.firestore().collection("subscriptions").doc(userId).get();
        if (document.exists)
            return document.data();
        const now = admin.firestore.Timestamp.now();
        const subscription = {
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
    static async hasActiveEntitlement(userId, planId) {
        const subscription = await this.getSubscription(userId);
        return subscription.status === "active" && subscription.planId === planId;
    }
}
exports.SubscriptionService = SubscriptionService;
//# sourceMappingURL=subscriptionService.js.map