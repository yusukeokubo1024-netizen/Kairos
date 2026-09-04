# Kairos 開発ロードマップ & 実装スプリント計画

## 🎯 開発体制

```
┌─────────────────────────────────────┐
│   FlutterFlow（フロントエンド）     │
│  ├─ UI/UX 画面設計               │
│  ├─ 状態管理・ナビゲーション      │
│  └─ ユーザーインタラクション      │
└─────────────────────────────────────┘
           ↓ Firebase API連携 ↓
┌─────────────────────────────────────┐
│   VS Code + Cloud Functions         │
│  ├─ バックエンドロジック          │
│  ├─ データバリデーション          │
│  ├─ 権限管理                      │
│  └─ 第三者 API 連携               │
└─────────────────────────────────────┘
           ↓ Firestore/Storage ↓
┌─────────────────────────────────────┐
│   Firebase バックエンド            │
│  ├─ Firestore（Database）         │
│  ├─ Firebase Storage             │
│  ├─ Cloud Messaging              │
│  └─ Authentication               │
└─────────────────────────────────────┘
```

---

## 📋 Sprint スケジュール

### Sprint 0: 基盤整備（1週間）

#### 目標: 開発環境セットアップ完了

**FlutterFlow 側**
- [ ] プロジェクト基本構造確認
- [ ] ナビゲーション設計（BottomTabBar）
- [ ] テーマ・カラーシステム設定
- [ ] フォント・サイズ統一
- [ ] 基本コンポーネント作成（Button, Card, Input など）

**VS Code 側**
- [ ] Cloud Functions プロジェクト初期化
- [ ] Firebase CLI セットアップ
- [ ] TypeScript 設定
- [ ] ESLint / Prettier 設定
- [ ] ログ・デバッグシステム構築

**Firebase 側**
- [ ] Firestore コレクション作成
- [ ] セキュリティルール配置
- [ ] Firebase Storage バケット設定
- [ ] Cloud Messaging 設定
- [ ] Authentication プロバイダー設定

**デリバリー**:
```
✅ FlutterFlow: ホーム画面スケルトン
✅ Cloud Functions: Hello World デプロイ確認
✅ Firebase: 全基本設定完了
```

---

### Sprint 1: 認証・ユーザー管理（2週間）

#### 目標: ユーザー登録・ログイン機能完成

**FlutterFlow（Week 1）**
- [ ] スプラッシュ画面作成
- [ ] ログイン画面実装
  - [ ] Email/Password 入力フォーム
  - [ ] Google ログインボタン
  - [ ] Apple ID ログインボタン（iOS）
  - [ ] バリデーション表示
- [ ] 新規登録画面実装
  - [ ] ユーザー情報入力フォーム
  - [ ] 利用規約同意チェック
  - [ ] メール確認フロー
- [ ] パスワードリセット画面

**Cloud Functions（Week 1）**
- [ ] Authentication トリガー実装
  - [ ] ユーザー作成時に `users/{uid}` ドキュメント作成
  - [ ] ユーザー削除時にデータ削除
- [ ] メール確認ロジック
- [ ] エラーハンドリング

**FlutterFlow（Week 2）**
- [ ] ホーム画面トランジション
- [ ] ユーザープロフィール画面
  - [ ] プロフィール表示
  - [ ] 基本情報編集
  - [ ] プロフィール画像アップロード

**Cloud Functions（Week 2）**
- [ ] ユーザー情報更新 API
- [ ] プロフィール画像リサイズ・最適化
- [ ] データ削除 API（GDPR対応）

**デリバリー**:
```
✅ ユーザーが新規登録 → ホーム画面遷移
✅ ユーザーがログイン → ホーム画面表示
✅ プロフィール編集 → Firestore 反映
```

---

### Sprint 2: カレンダー・スケジュール基本（2週間）

#### 目標: カレンダービュー・スケジュール CRUD 完成

**FlutterFlow（Week 1）**
- [ ] ホーム画面実装
  - [ ] カレンダー表示（table_calendar）
  - [ ] 当日スケジュール一覧表示
  - [ ] 新規スケジュール作成ボタン
- [ ] スケジュール作成画面
  - [ ] タイトル・説明入力
  - [ ] 日時選択（開始・終了）
  - [ ] 位置情報入力
  - [ ] 保存ボタン

**Cloud Functions（Week 1）**
- [ ] スケジュール作成 API
  - [ ] バリデーション
  - [ ] Firestore への保存
  - [ ] 重複チェック
- [ ] スケジュール削除 API

**FlutterFlow（Week 2）**
- [ ] スケジュール詳細画面
  - [ ] 詳細情報表示
  - [ ] 編集ボタン
  - [ ] 削除ボタン
  - [ ] 共有ボタン
- [ ] スケジュール編集画面
- [ ] スケジュール削除確認ダイアログ

**Cloud Functions（Week 2）**
- [ ] スケジュール更新 API
- [ ] スケジュール検索 API
- [ ] リアルタイム同期ロジック

**デリバリー**:
```
✅ カレンダーに日付が表示される
✅ スケジュール作成 → カレンダーに表示
✅ スケジュール編集・削除が機能
```

---

### Sprint 3: タスク管理機能（1.5週間）

#### 目標: タスク一覧・CRUD 完成

**FlutterFlow（Week 1）**
- [ ] タスク一覧画面
  - [ ] タスク一覧表示
  - [ ] 優先度別フィルタ
  - [ ] 完了/未完了タブ
  - [ ] 新規タスク作成ボタン
- [ ] タスク作成画面
  - [ ] タイトル・説明
  - [ ] 期限日時選択
  - [ ] 優先度選択
  - [ ] カテゴリ選択

**Cloud Functions（Week 1）**
- [ ] タスク作成 API
- [ ] タスク完了状態更新 API
- [ ] タスク削除 API
- [ ] タスク検索 API（優先度・期限フィルタ）

**FlutterFlow（Week 2 前半）**
- [ ] タスク詳細画面
- [ ] タスク編集画面
- [ ] タスク完了チェック機能

**デリバリー**:
```
✅ タスク一覧表示
✅ タスク作成・編集・削除機能
✅ タスク検索・フィルタ機能
```

---

### Sprint 4: グループ・共有機能（2週間）

#### 目標: グループ管理・スケジュール共有完成

**FlutterFlow（Week 1）**
- [ ] グループ一覧画面
  - [ ] グループ一覧表示
  - [ ] グループ作成ボタン
  - [ ] グループ選択
- [ ] グループ作成画面
  - [ ] グループ名入力
  - [ ] 説明入力
  - [ ] グループアイコン設定
- [ ] グループ詳細画面
  - [ ] メンバー一覧表示
  - [ ] メンバー追加・削除
  - [ ] グループ編集・削除

**Cloud Functions（Week 1）**
- [ ] グループ作成 API
- [ ] メンバー追加 API
  - [ ] メール招待
  - [ ] リアルタイム通知
- [ ] メンバー削除 API
- [ ] グループ削除 API（オーナーのみ）

**FlutterFlow（Week 2）**
- [ ] スケジュール共有画面
  - [ ] グループ選択
  - [ ] 共有範囲設定
- [ ] グループスケジュール表示
  - [ ] グループメンバーのスケジュール表示
  - [ ] 参加者ステータス表示
- [ ] 招待受け入れ画面

**Cloud Functions（Week 2）**
- [ ] スケジュール共有 API
- [ ] グループスケジュール取得 API
- [ ] 招待通知 API
- [ ] 権限チェックロジック

**デリバリー**:
```
✅ グループ作成・管理
✅ メンバー招待（メール送信）
✅ スケジュール共有表示
```

---

### Sprint 5: 位置情報機能（1.5週間）

#### 目標: リアルタイム位置情報共有完成

**FlutterFlow（Week 1）**
- [ ] 位置情報設定画面
  - [ ] GPS許可リクエスト
  - [ ] 位置情報共有設定
  - [ ] 共有対象グループ選択
  - [ ] 共有時間設定（期限）
- [ ] 位置情報表示画面
  - [ ] 地図表示（Google Maps）
  - [ ] グループメンバーの位置表示
  - [ ] 更新頻度設定

**Cloud Functions（Week 1-2）**
- [ ] 位置情報更新 API
  - [ ] GPS座標保存
  - [ ] バッテリー効率最適化
- [ ] 位置情報取得 API（権限チェック）
- [ ] 位置情報自動削除タスク（期限切れ）
- [ ] Geohashing（近傍検索最適化）

**デリバリー**:
```
✅ ユーザーが位置情報共有を有効化
✅ 共有メンバーに位置が表示される
✅ リアルタイム位置更新
```

---

### Sprint 6: 通知・リマインダー（1.5週間）

#### 目標: ローカル通知・プッシュ通知完成

**FlutterFlow（Week 1）**
- [ ] 通知設定画面
  - [ ] リマインダー時間設定
  - [ ] 通知方法選択（音・振動）
  - [ ] 通知ON/OFF

**Cloud Functions（Week 1-2）**
- [ ] ローカル通知スケジューラ
  - [ ] スケジュール前 N 分に通知
  - [ ] タスク期限前に通知
- [ ] Firebase Cloud Messaging（FCM）統合
  - [ ] デバイストークン管理
  - [ ] プッシュ通知送信
  - [ ] ユーザーセグメンテーション
- [ ] 通知ログ記録

**デリバリー**:
```
✅ ローカル通知が時間に表示
✅ プッシュ通知が配信される
✅ 通知クリック時にスケジュール詳細表示
```

---

### Sprint 7: プレミアム機能・内課金（2週間）

#### 目標: サブスクリプション・課金システム完成

**FlutterFlow（Week 1）**
- [ ] プレミアム紹介画面
  - [ ] 機能比較表
  - [ ] 価格表示
  - [ ] 購入ボタン
- [ ] 購入画面
  - [ ] In-App Purchase 実装
  - [ ] iOS/Android 統一UI

**Cloud Functions（Week 1）**
- [ ] サブスクリプション管理 API
  - [ ] 購入検証（Receipt検証）
  - [ ] サブスクリプション有効期限チェック
  - [ ] 自動更新キャンセル
- [ ] Webhooks 実装
  - [ ] App Store Server Notifications
  - [ ] Google Play Billing Library
- [ ] サブスクリプションステータス API

**FlutterFlow（Week 2）**
- [ ] 設定画面
  - [ ] サブスクリプション ステータス表示
  - [ ] 課金履歴表示
  - [ ] 解約ボタン
- [ ] プレミアム機能ロック画面
  - [ ] 制限機能の表示

**Cloud Functions（Week 2）**
- [ ] 権限チェックミドルウェア
  - [ ] プレミアム機能への アクセス制御
- [ ] 返金処理 API
- [ ] 解約時のデータ処理

**デリバリー**:
```
✅ サブスクリプション購入
✅ プレミアム機能が有効化
✅ 課金履歴・管理画面
```

---

### Sprint 8: 高度な機能・最適化（2週間）

#### 目標: AI提案・分析・パフォーマンス最適化

**FlutterFlow**
- [ ] レポート・分析画面
  - [ ] スケジュール統計表示
  - [ ] タスク完了率
  - [ ] 時間追跡
- [ ] 検索・フィルタ機能の充実
  - [ ] 全文検索
  - [ ] 高度なフィルタ UI

**Cloud Functions**
- [ ] AI提案ロジック
  - [ ] タスク自動分類
  - [ ] 所要時間推定
  - [ ] スケジュール提案
- [ ] 分析エンジン
  - [ ] 時間集計
  - [ ] トレンド分析
  - [ ] レポート生成
- [ ] パフォーマンス最適化
  - [ ] Firestore インデックス最適化
  - [ ] クエリの高速化
  - [ ] キャッシング戦略

**デリバリー**:
```
✅ スケジュール統計表示
✅ AI提案表示
✅ 検索・フィルタ高速化
```

---

## 📊 全体進捗表

| Sprint | 期間 | FlutterFlow | Cloud Functions | 状態 |
|--------|------|------------|-----------------|------|
| 0 | 1週 | 基本構造 | 初期化 | ⬜ 未開始 |
| 1 | 2週 | 認証・ログイン | ユーザー管理 | ⬜ 未開始 |
| 2 | 2週 | カレンダー・スケジュール | Schedule API | ⬜ 未開始 |
| 3 | 1.5週 | タスク管理 | Task API | ⬜ 未開始 |
| 4 | 2週 | グループ・共有 | Group/Share API | ⬜ 未開始 |
| 5 | 1.5週 | 位置情報表示 | Location API | ⬜ 未開始 |
| 6 | 1.5週 | 通知設定 | Notification API | ⬜ 未開始 |
| 7 | 2週 | プレミアム UI | Subscription API | ⬜ 未開始 |
| 8 | 2週 | 分析・検索 | AI/Analytics | ⬜ 未開始 |
| **合計** | **15.5週** | | | |

---

## 🚀 Sprint 0 : 基盤整備 - 詳細タスク

### FlutterFlow 側（初日）

#### 1. ナビゲーション設計

```dart
// 想定ナビゲーション構造
BottomTabBar:
├─ Home (カレンダー・スケジュール)
├─ Tasks (タスク一覧)
├─ Groups (グループ・共有)
└─ Settings (設定・プレミアム)

各タブ内でのスタック：
Home:
  ├─ Calendar View
  ├─ Schedule Detail
  └─ Schedule Create/Edit

Tasks:
  ├─ Task List
  ├─ Task Detail
  └─ Task Create/Edit

Groups:
  ├─ Group List
  ├─ Group Detail
  └─ Group Create

Settings:
  ├─ Profile
  ├─ Notifications
  ├─ Premium
  └─ Legal/Support
```

#### 2. Design System 設定

**カラー**:
```
Primary:   #2563EB
Secondary: #0EA5E9
Success:   #10B981
Warning:   #F59E0B
Error:     #EF4444
```

**Typography**:
```
Heading 1: 32pt Bold
Heading 2: 24pt Bold
Heading 3: 20pt SemiBold
Body:      16pt Regular
Caption:   12pt Regular
```

**Spacing**: 8px グリッド

**コンポーネント**:
```
- CustomButton
- CustomCard
- CustomInput
- CustomAppBar
- LoadingIndicator
- EmptyState
```

#### 3. チェックリスト

```
FlutterFlow:
  ✅ プロジェクト開く
  ✅ Navigation Structure 作成
  ✅ Color Theme 設定
  ✅ Typography 設定
  ✅ 基本コンポーネント作成
  ✅ ホーム画面スケルトン（レイアウトのみ）
```

### VS Code 側（初日-3日）

#### 1. Cloud Functions 初期化

```bash
# Firebase CLI インストール確認
firebase --version

# Functions プロジェクトディレクトリ作成
cd c:\Users\yusuk\OneDrive\Desktop\kairos\functions

# Firebase functions init
firebase init functions

# TypeScript テンプレート選択
# ESLint選択
```

#### 2. package.json 設定

```json
{
  "name": "kairos-functions",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "start": "firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.4.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "eslint": "^8.0.0"
  }
}
```

#### 3. TypeScript 設定

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
    "resolveJsonModule": true
  }
}
```

#### 4. ディレクトリ構造

```
functions/
├─ src/
│  ├─ index.ts              (エントリーポイント)
│  ├─ models/               (型定義)
│  │  ├─ user.ts
│  │  ├─ schedule.ts
│  │  ├─ task.ts
│  │  ├─ group.ts
│  │  └─ location.ts
│  ├─ utils/                (ユーティリティ)
│  │  ├─ auth.ts            (認証チェック)
│  │  ├─ validation.ts      (バリデーション)
│  │  └─ errors.ts          (エラーハンドリング)
│  ├─ services/             (ビジネスロジック)
│  │  ├─ user.service.ts
│  │  ├─ schedule.service.ts
│  │  ├─ task.service.ts
│  │  └─ group.service.ts
│  └─ triggers/             (Firebase トリガー)
│     ├─ auth.trigger.ts    (ユーザー作成時)
│     ├─ firestore.trigger.ts
│     └─ storage.trigger.ts
├─ .eslintrc.json
├─ tsconfig.json
├─ package.json
└─ .gitignore
```

#### 5. Hello World Function 実装

**src/index.ts**:
```typescript
import * as functions from "firebase-functions";
import * as cors from "cors";

// CORS 設定
const corsHandler = cors({origin: true});

// Health Check Function
export const healthCheck = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    res.json({
      status: "OK",
      timestamp: new Date().toISOString(),
      version: "1.0.0"
    });
  });
});
```

#### 6. チェックリスト

```
VS Code:
  ✅ Firebase CLI インストール
  ✅ Cloud Functions プロジェクト作成
  ✅ TypeScript 設定
  ✅ Package.json 設定
  ✅ ディレクトリ構造作成
  ✅ Hello World Function デプロイ確認
  ✅ ESLint/Prettier 設定
```

### Firebase 側（初日-3日）

#### 1. Firestore 設定

```
✅ Database Mode: Production (セキュリティルール有効)
✅ Location: asia-northeast1 (東京)
✅ Firestore Rules: [firestore.rules を配置]
```

#### 2. Storage 設定

```
✅ Bucket: gs://kairos-3d873.appspot.com
✅ Location: asia-northeast1
✅ Storage Rules: デフォルト（認証ユーザーのみアクセス）
```

#### 3. Authentication 設定

```
✅ Enable Providers:
   - Email/Password
   - Google
   - Apple (iOS)
   - Anonymous
```

#### 4. Cloud Messaging 設定

```
✅ Server API Key: 自動生成確認
✅ APNs Certificate: 後で登録
✅ Android Notification Channel: 後で設定
```

#### 5. チェックリスト

```
Firebase:
  ✅ Firestore Database 有効化
  ✅ Storage バケット確認
  ✅ Authentication 設定
  ✅ Cloud Messaging 確認
  ✅ セキュリティルール配置
  ✅ Emulator Suite 起動確認
```

---

## 🧪 Sprint 0 デリバリー基準

### 受け入れ基準

```
✅ FlutterFlow:
   - ナビゲーション構造が実装されている
   - ホーム画面のスケルトンが表示される
   - ボタン・テキストフィールドなどのコンポーネントが作成されている
   - Color/Typography ガイドラインが設定されている

✅ Cloud Functions:
   - firebase deploy で成功する
   - https://us-central1-kairos-3d873.cloudfunctions.net/healthCheck にアクセス可能
   - JSON レスポンスが返される

✅ Firebase:
   - Firestore Dashboard に接続できる
   - セキュリティルール が配置されている
   - Emulator Suite で local テスト可能
```

---

## 📅 実装開始チェックリスト

### 事前準備

- [ ] **ユーザー確認**: 

  **FlutterFlow アカウント**: _________  
  **Google Cloud Project ID**: kairos-3d873  
  **Firebase Project**: kairos-3d873  

- [ ] **環境確認**: 

  ```bash
  node --version     # v18+
  npm --version      # v9+
  firebase --version # v13+
  ```

- [ ] **リポジトリ確認**: 

  - [ ] GitHub/GitLab リポジトリ作成（オプション）
  - [ ] .gitignore 設定
  - [ ] リモート接続確認

- [ ] **アクセス権限確認**: 

  - [ ] Firebase Console アクセス可能
  - [ ] FlutterFlow エディタ アクセス可能
  - [ ] Cloud Functions デプロイ権限

### 開始宣言

```
開始日時: _______________
担当者: _______________
期限: _______________
```

---

**次のステップ**: Sprint 0 の具体的なタスクに進む前に、上記の事前準備チェックリストが完了しているか確認してください。

