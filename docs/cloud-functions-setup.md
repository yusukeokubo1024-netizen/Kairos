# Kairos Cloud Functions セットアップガイド

## 🚀 Cloud Functions 初期化手順

### 前提条件

```bash
# 確認
node --version    # v18.0.0 以上
npm --version     # v9.0.0 以上
firebase --version # v12.0.0 以上
```

未インストールの場合：
- [Node.js](https://nodejs.org) インストール
- Firebase CLI: `npm install -g firebase-tools`

---

## Step 1: Firebase CLI ログイン

```bash
# Firebase にログイン
firebase login

# ブラウザで Google アカウント認証
# → Firebase Console にアクセス権があるか確認
```

---

## Step 2: プロジェクト初期化

```bash
# Kairos プロジェクトフォルダに移動
cd c:\Users\yusuk\OneDrive\Desktop\kairos

# functions ディレクトリに移動（なければ作成）
mkdir -p functions
cd functions

# Firebase Functions を初期化
firebase init functions

# 以下の質問に答える:
# ? Which of these options do you want? → TypeScript を選択
# ? Do you want to use ESLint? → Yes を選択
# ? Do you want to install dependencies now? → Yes を選択
```

---

## Step 3: プロジェクト構造確認

```
kairos/functions/
├─ src/
│  ├─ index.ts           (メインエントリー)
│  ├─ auth.ts            (認証関連)
│  ├─ users.ts           (ユーザー関連)
│  └─ schedule.ts        (スケジュール関連)
├─ lib/                  (コンパイル後)
├─ node_modules/
├─ package.json
├─ tsconfig.json
├─ .eslintrc.js
├─ .gitignore
└─ firebase-debug.log
```

---

## Step 4: 依存パッケージ追加

```bash
# functions フォルダで実行
npm install

# 追加パッケージ
npm install cors uuid date-fns

# 開発用
npm install --save-dev @types/cors @types/uuid @types/date-fns
```

---

## Step 5: TypeScript 設定確認

**tsconfig.json** を確認：

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./lib",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "lib", "**/*.spec.ts"]
}
```

---

## Step 6: スクリプト設定

**package.json** を編集：

```json
{
  "name": "kairos-functions",
  "version": "1.0.0",
  "description": "Kairos backend Cloud Functions",
  "scripts": {
    "lint": "eslint --ext .js,.ts src/",
    "lint:fix": "eslint --ext .js,.ts --fix src/",
    "build": "tsc",
    "build:watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "start": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "deploy": "npm run build && firebase deploy --only functions",
    "logs": "firebase functions:log",
    "test": "jest"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.4.0",
    "cors": "^2.8.5",
    "uuid": "^9.0.0",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "typescript": "^5.1.0",
    "@types/node": "^20.0.0",
    "@types/cors": "^2.8.13",
    "@types/uuid": "^9.0.0",
    "@types/date-fns": "^2.6.0",
    "eslint": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0"
  }
}
```

---

## Step 7: ESLint 設定

**.eslintrc.js** を確認/編集：

```javascript
module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // コンパイル後のファイル
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["error", "double"],
    "import/no-unresolved": 0,
    "@typescript-eslint/no-unused-vars": ["warn"],
    "indent": ["error", 2],
  },
};
```

---

## Step 8: 基本コード実装

### 型定義作成

**src/types.ts**:

```typescript
// ユーザー型
export interface User {
  uid: string;
  email: string;
  displayName: string;
  profileImageUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

// スケジュール型
export interface Schedule {
  scheduleId: string;
  ownerId: string;
  title: string;
  description?: string;
  startTime: Date;
  endTime: Date;
  location?: string;
  participants?: string[];
  createdAt: Date;
  updatedAt: Date;
}

// タスク型
export interface Task {
  taskId: string;
  ownerId: string;
  title: string;
  description?: string;
  dueDate: Date;
  priority: "low" | "medium" | "high";
  completed: boolean;
  completedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

// グループ型
export interface Group {
  groupId: string;
  ownerId: string;
  name: string;
  description?: string;
  memberIds: string[];
  createdAt: Date;
  updatedAt: Date;
}

// API レスポンス型
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: Date;
}

// エラー型
export interface ApiError {
  code: string;
  message: string;
  statusCode: number;
}
```

### ユーティリティ関数作成

**src/utils/errors.ts**:

```typescript
import * as functions from "firebase-functions";

export class CustomError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    message: string
  ) {
    super(message);
    this.name = "CustomError";
  }
}

export const throwError = (code: string, message: string, statusCode: number = 400) => {
  throw new CustomError(code, statusCode, message);
};

export const handleError = (error: unknown, context: string = "") => {
  console.error(`Error in ${context}:`, error);
  
  if (error instanceof CustomError) {
    return {
      success: false,
      error: error.message,
      code: error.code,
      statusCode: error.statusCode,
    };
  }

  if (error instanceof Error) {
    return {
      success: false,
      error: error.message,
      code: "UNKNOWN_ERROR",
      statusCode: 500,
    };
  }

  return {
    success: false,
    error: "Unknown error occurred",
    code: "UNKNOWN_ERROR",
    statusCode: 500,
  };
};
```

**src/utils/auth.ts**:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { CustomError } from "./errors";

export interface DecodedToken {
  uid: string;
  email?: string;
  iat: number;
}

export const verifyAuth = async (req: functions.https.Request): Promise<DecodedToken> => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new CustomError("UNAUTHORIZED", 401, "No token provided");
  }

  const token = authHeader.substring(7);
  
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return {
      uid: decodedToken.uid,
      email: decodedToken.email,
      iat: decodedToken.iat,
    };
  } catch (error) {
    throw new CustomError("INVALID_TOKEN", 401, "Invalid or expired token");
  }
};

export const verifyOwner = (userId: string, resourceOwnerId: string) => {
  if (userId !== resourceOwnerId) {
    throw new CustomError("FORBIDDEN", 403, "You do not own this resource");
  }
};
```

**src/utils/validation.ts**:

```typescript
export const validateEmail = (email: string): boolean => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

export const validateString = (value: string, minLength: number = 1, maxLength: number = 500): boolean => {
  return typeof value === "string" && value.length >= minLength && value.length <= maxLength;
};

export const validateDate = (date: unknown): date is Date => {
  return date instanceof Date && !isNaN(date.getTime());
};

export const validateSchedule = (data: unknown) => {
  if (typeof data !== "object" || !data) {
    throw new Error("Invalid schedule data");
  }

  const schedule = data as Record<string, unknown>;

  if (!validateString(schedule.title as string)) {
    throw new Error("Title is required");
  }

  if (!validateDate(new Date(schedule.startTime as string))) {
    throw new Error("Valid startTime is required");
  }

  if (!validateDate(new Date(schedule.endTime as string))) {
    throw new Error("Valid endTime is required");
  }

  return true;
};
```

### メインインデックス作成

**src/index.ts**:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as cors from "cors";
import { handleError } from "./utils/errors";
import { verifyAuth } from "./utils/auth";

// Firebase Admin 初期化
admin.initializeApp();

// CORS 設定
const corsHandler = cors({ origin: true });

// ============================================
// Health Check
// ============================================

export const healthCheck = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    res.status(200).json({
      success: true,
      data: {
        status: "OK",
        version: "1.0.0",
        timestamp: new Date().toISOString(),
      },
    });
  });
});

// ============================================
// Test API
// ============================================

export const testAuth = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const decodedToken = await verifyAuth(req);
      res.status(200).json({
        success: true,
        data: {
          message: "Authentication successful",
          uid: decodedToken.uid,
          email: decodedToken.email,
        },
      });
    } catch (error) {
      const errorResponse = handleError(error, "testAuth");
      res.status(errorResponse.statusCode).json(errorResponse);
    }
  });
});

// ============================================
// Firestore Triggers
// ============================================

// ユーザー作成時のトリガー
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  try {
    const userRef = admin.firestore().collection("users").doc(user.uid);
    
    await userRef.set({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName || "User",
      profileImageUrl: user.photoURL || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User ${user.uid} created successfully`);
  } catch (error) {
    console.error("Error creating user:", error);
  }
});

// ユーザー削除時のトリガー
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  try {
    const userRef = admin.firestore().collection("users").doc(user.uid);
    
    // ユーザードキュメント削除
    await userRef.delete();

    // ユーザーが作成したスケジュール削除
    const schedulesSnapshot = await admin
      .firestore()
      .collection("schedules")
      .where("ownerId", "==", user.uid)
      .get();

    const batch = admin.firestore().batch();
    schedulesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    console.log(`User ${user.uid} and related data deleted successfully`);
  } catch (error) {
    console.error("Error deleting user:", error);
  }
});

export const logger = functions.logger;
```

---

## Step 9: ビルド & テスト

```bash
# TypeScript コンパイル
npm run build

# ESLint チェック
npm run lint

# ローカルエミュレーターで テスト
npm start

# ブラウザで確認
# http://localhost:5000/kairos-3d873/us-central1/healthCheck
```

**期待される出力**:
```json
{
  "success": true,
  "data": {
    "status": "OK",
    "version": "1.0.0",
    "timestamp": "2026-08-30T10:30:00.000Z"
  }
}
```

---

## Step 10: デプロイ（本番環境）

```bash
# Firebase にデプロイ
npm run deploy

# ログ確認
npm run logs

# デプロイ後の URL
# https://us-central1-kairos-3d873.cloudfunctions.net/healthCheck
```

---

## 📁 ファイル一覧（Sprint 0 完了後）

```
kairos/functions/
├─ src/
│  ├─ index.ts              ✅ メインエントリー
│  ├─ types.ts              ✅ 型定義
│  ├─ utils/
│  │  ├─ errors.ts          ✅ エラーハンドリング
│  │  ├─ auth.ts            ✅ 認証ユーティリティ
│  │  └─ validation.ts      ✅ バリデーション
│  ├─ services/
│  │  ├─ user.service.ts    ⬜ (Sprint 1 で実装)
│  │  ├─ schedule.service.ts ⬜ (Sprint 2 で実装)
│  │  └─ task.service.ts    ⬜ (Sprint 3 で実装)
│  └─ triggers/
│     ├─ auth.trigger.ts    ✅ Auth トリガー
│     └─ firestore.trigger.ts ⬜ (後日実装)
├─ lib/                     (コンパイル後)
├─ node_modules/
├─ package.json             ✅
├─ tsconfig.json            ✅
├─ .eslintrc.js             ✅
├─ .gitignore               ✅
└─ firebase-debug.log
```

---

## 🧪 ローカルテスト方法

### Firebase Emulator Suite 起動

```bash
# 全エミュレーター起動
firebase emulators:start

# 特定のエミュレーターのみ
firebase emulators:start --only functions,firestore

# Firestore Emulator UI
# http://localhost:4000
```

### HTTP リクエストテスト

```bash
# Health Check
curl http://localhost:5000/kairos-3d873/us-central1/healthCheck

# 認証テスト（トークン必須）
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  http://localhost:5000/kairos-3d873/us-central1/testAuth
```

### VS Code デバッグ設定

**.vscode/launch.json**:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Attach to Functions Emulator",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "skipFiles": ["<node_internals>/**"],
      "outFiles": ["${workspaceRoot}/functions/lib/**/*.js"]
    }
  ]
}
```

デバッグ開始:
```bash
firebase emulators:start --inspect-functions
```

---

## 🚀 次のステップ

Sprint 0 完了後：

1. **FlutterFlow**で ホーム画面スケルトン作成
2. **Firebase** で Firestore ルール配置
3. **Cloud Functions** で User Service 実装 (Sprint 1)

現在の状態：
- ✅ Cloud Functions プロジェクト初期化
- ✅ Health Check デプロイ可能
- ⏳ Service 層の実装待ち

