# Kairos - Firestoreデータモデル設計

## 📋 特許回避・独自設計について

### 設計原則
- **TimeTreeとの差別化**: 単なる共有カレンダーではなく、タスク・位置情報・内課金を統合したプロダクティビティプラットフォーム
- **独自技術**: リアルタイム同期はFirestore Listenersで実装（特許技術ではなく一般的なDB技術）
- **UI/UXの独自性**: カレンダーUIは完全にオリジナル設計
- **名称**: 「Kairos」（時の神）として完全に独立したブランド
- **色分け表示**: 単なる補助機能（TimeTreeの特許対象ではない）

### 特許リスク管理
| リスク項目 | 対策 |
|-----------|------|
| 共有カレンダー機能 | 単なる読み書きではなく、タスク・位置情報と統合 |
| リアルタイム同期 | Firestore標準機能の利用（特許回避） |
| UI表現 | 独自デザイン・レイアウト |
| 機能の組み合わせ | 独自の統合方法（タスク+カレンダー+位置情報） |

---

## コレクション構成

### 1. **users** - ユーザー情報
```
users/{uid}
├── uid: string (Firebase Auth UID)
├── email: string
├── displayName: string
├── profileImageUrl: string
├── createdAt: timestamp
├── updatedAt: timestamp
├── subscription: {
│   ├── tier: "free" | "premium" | "family"
│   ├── status: "active" | "cancelled" | "expired"
│   └── expiresAt: timestamp
├── preferences: {
│   ├── theme: "light" | "dark"
│   ├── language: string
│   ├── notifications: boolean
│   └── locationSharing: boolean
└── subCollections:
    ├── schedules/  (自分のスケジュール)
    ├── tasks/      (自分のタスク)
    └── sharedSchedules/  (共有されたスケジュール)
```

### 2. **schedules** - スケジュール（イベント）
```
schedules/{scheduleId}
├── scheduleId: string (auto-generated)
├── ownerId: string (owners/{uid})
├── title: string
├── description: string
├── startTime: timestamp
├── endTime: timestamp
├── location: string
├── locationCoordinates: {
│   ├── latitude: number
│   └── longitude: number
├── color: string (hex color)
├── participants: string[] (user IDs)
├── sharedGroupIds: string[]
├── attachedImages: string[] (image IDs)
├── reminderTime: number (minutes before)
├── isRecurring: boolean
├── recurrenceRule: string (RRULE format)
├── createdAt: timestamp
├── updatedAt: timestamp
└── subCollections:
    ├── participants/{participantId}
    │   ├── userId: string
    │   ├── status: "pending" | "accepted" | "declined"
    │   ├── joinedAt: timestamp
    │   └── leftAt: timestamp (optional)
    ├── comments/{commentId}
    │   ├── userId: string
    │   ├── text: string
    │   ├── createdAt: timestamp
    │   └── updatedAt: timestamp
    └── images/{imageId}
        ├── userId: string
        ├── uploadedBy: string
        ├── imageUrl: string
        ├── thumbnailUrl: string
        ├── description: string
        └── uploadedAt: timestamp
```

### 3. **tasks** - タスク/TODO
```
tasks/{taskId}
├── taskId: string (auto-generated)
├── ownerId: string
├── title: string
├── description: string
├── dueDate: timestamp
├── priority: "low" | "medium" | "high"
├── completed: boolean
├── completedAt: timestamp (optional)
├── category: string
├── tags: string[]
├── createdAt: timestamp
├── updatedAt: timestamp
└── assignees: string[] (shared tasks)
```

### 4. **sharedGroups** - 共有グループ
```
sharedGroups/{groupId}
├── groupId: string (auto-generated)
├── ownerId: string
├── name: string
├── description: string
├── memberIds: string[]
├── createdAt: timestamp
├── updatedAt: timestamp
└── subCollections:
    └── members/{memberId}
        ├── userId: string
        ├── role: "owner" | "editor" | "viewer"
        └── joinedAt: timestamp
```

### 5. **locations** - 位置情報共有
```
locations/{locationId}
├── locationId: string (auto-generated)
├── userId: string
├── coordinates: {
│   ├── latitude: number
│   └── longitude: number
├── address: string
├── accuracy: number (meters)
├── sharedWith: string[] (user IDs who can see this)
├── expiresAt: timestamp (optional - 位置情報の共有期限)
├── updatedAt: timestamp
└── scheduleId: string (optional - 関連スケジュール)
```

### 6. **purchases** - 内課金（購入履歴）
```
purchases/{purchaseId}
├── purchaseId: string (auto-generated)
├── userId: string
├── productId: string
├── productName: string
├── price: number (cents)
├── currency: string
├── transactionId: string (Payment Gateway)
├── status: "pending" | "completed" | "failed" | "refunded"
├── purchasedAt: timestamp
└── expiresAt: timestamp (optional - サブスク期限)
```

### 7. **subscriptions** - サブスクリプション管理
```
subscriptions/{subscriptionId}
├── subscriptionId: string
├── userId: string
├── tier: "free" | "premium" | "family"
├── status: "active" | "paused" | "cancelled"
├── startDate: timestamp
├── endDate: timestamp
├── autoRenew: boolean
├── paymentMethodId: string
└── updatedAt: timestamp
```

## インデックス設定

複合インデックスが必要な場合：
- `schedules`: ownerId + startTime (スケジュール一覧取得)
- `tasks`: ownerId + dueDate (タスク一覧取得)
- `tasks`: ownerId + completed + dueDate (未完了タスク取得)
- `locations`: userId + sharedWith (共有位置情報)

## セキュリティルール概要

| コレクション | 作成 | 読取 | 更新 | 削除 |
|-----------|------|------|------|------|
| users | 認証者のみ | 自分 | 自分 | 自分 |
| schedules | 認証者 | オーナー/参加者 | オーナー | オーナー |
| tasks | 認証者 | オーナー | オーナー | オーナー |
| sharedGroups | 認証者 | オーナー/メンバー | オーナー | オーナー |
| locations | 認証者 | 本人/共有対象者 | 本人 | 本人 |
| purchases | 認証者 | 本人 | 管理者 | 管理者 |
| subscriptions | 認証者 | 本人 | 本人 | 管理者 |

## マイグレーション注意点

1. `schedules.participants` は配列から `participants` サブコレクションへの移行を検討
2. `timestamps` はクライアント側で `serverTimestamp()` を使用
3. 大規模ユーザー対応時はシャーディングを検討
