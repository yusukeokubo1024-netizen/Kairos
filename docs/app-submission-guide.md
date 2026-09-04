# Kairos アプリ申請ロードマップ

## 📋 申請までの完全ガイド

申請タイプ：**個人事業主/一人企業** による申請

---

## Phase 1: 事前準備（1-2週間）

### 1. 会社・個人情報整備

#### 必要書類
- [ ] 個人事業主の場合：身分証明書（運転免許証など）
- [ ] 法人登録の場合：法人登記簿謄本
- [ ] 住所・電話番号・メールアドレス確認

#### Kairosプロジェクト情報
```
企業/個人名: ___________________
住所: ___________________
電話番号: ___________________
メールアドレス: ___________________
Webサイト: ___________________
サポート連絡先: ___________________
```

### 2. 開発者アカウント取得

#### ✅ Apple Developer Program の登録

**費用**: 年間 $99 USD

**登録手順**:
1. [Apple Developer](https://developer.apple.com/) にアクセス
2. 「Account」→「Enroll」
3. 個人情報入力（ID・パスポート確認可）
4. Apple IDでサインイン（新規作成可）
5. 契約条件に同意
6. 支払い情報登録（クレジットカード）
7. メール確認 → アカウント有効化（2-3日）

**チェックリスト**:
- [ ] Apple IDを作成/ログイン
- [ ] 個人情報登録
- [ ] 支払い方法登録
- [ ] 契約条件確認・同意
- [ ] アカウント有効化確認

#### ✅ Google Play Developer Account の登録

**費用**: 登録時 $25 USD（一度きり）

**登録手順**:
1. [Google Play Console](https://play.google.com/console) にアクセス
2. Googleアカウントでログイン（新規作成可）
3. 契約条件に同意
4. 支払い情報登録
5. 個人情報・住所入力
6. 成人確認
7. アカウント有効化（即座〜数日）

**チェックリスト**:
- [ ] Googleアカウント作成/ログイン
- [ ] 支払い情報登録
- [ ] 個人情報入力
- [ ] 契約条件同意
- [ ] アカウント有効化確認

---

## Phase 2: アプリ情報準備（1週間）

### 1. アプリアイコン・スクリーンショット準備

#### iOS アイコン要件
```
App Icon:
- サイズ: 1024x1024 px (最大)
- フォーマット: PNG
- 背景: 透明化不可（塗りつぶし必須）
- コーナー: 自動で角丸化される

必要なサイズ:
- 1024x1024 (App Store 表示用)
- 180x180 (iPhone 6s Plus)
- 167x167 (iPad Pro)
- 152x152 (iPad)
- 120x120 (iPhone)
- 87x87 (Apple Watch など)

→ Xcode で自動生成可
```

#### Android アイコン要件
```
App Icon:
- サイズ: 512x512 px (最大)
- フォーマット: PNG
- コーナー: 自動で角丸化

Google Play Store では:
- 512x512 用の高品質画像必須
```

#### スクリーンショット要件

**iOS**:
```
最小: 5-8 枚
推奨: 10 枚
解像度:
- iPhone Pro Max: 1242x2688 px
- iPhone: 1125x2436 px
- iPad: 1536x2048 px
言語: 日本語
```

**Android**:
```
最小: 2-8 枚
推奨: 10 枚
解像度:
- 1080x1920 px (標準)
- 1440x2560 px (推奨)
言語: 日本語
```

#### スクリーンショット撮影画面
```
1. ホーム（カレンダービュー）
2. スケジュール詳細
3. タスク一覧
4. グループ管理
5. 位置情報表示
6. 設定・プレミアム紹介
```

#### 準備物チェックリスト
- [ ] アプリアイコン（1024x1024 PNG）
- [ ] iOS スクリーンショット（5-10枚）
- [ ] Android スクリーンショット（5-10枚）
- [ ] プレビュー画像（広告用）

### 2. アプリ説明文・メタデータ準備

#### アプリ名
```
日本: Kairos - スケジュール・タスク管理
English: Kairos - Schedule & Task Manager
```

#### 短い説明（サブタイトル）
```
日本: 家族・チームの予定を一元管理
English: Manage schedules with your family & team
```

#### 詳細説明（アプリ説明）
```
日本語版（150-4000文字）:
-----------------------
Kairosは、家族やチームのスケジュール・タスク管理を簡単にするアプリです。

【主な機能】
✅ 共有カレンダー - 家族・チームの予定を一目で確認
✅ タスク管理 - TODOリストで優先度管理
✅ 位置情報共有 - 家族の居場所をリアルタイム表示
✅ グループ管理 - プロジェクト・チーム単位での共有
✅ リマインダー - 重要な予定を通知

シンプルで使いやすいUIで、誰でも直感的に操作できます。

対応: iOS 14+ / Android 9+
```

#### キーワード（タグ）
```
日本: カレンダー, スケジュール, タスク管理, 共有, 家族, チーム, 予定, TODO, グループ

英語: calendar, schedule, task, planner, family, team, shared, reminder, todo, productivity
```

#### サポートURL・プライバシーポリシーURL
```
サポートページ: https://kairos.app/support
プライバシーポリシー: https://kairos.app/privacy-policy
利用規約: https://kairos.app/terms-of-service
```

#### 対象年齢
```
iOS: 4+ (Parental Controls 対応)
Android: 3+ (コンテンツレーティング: 一般向け)
```

#### チェックリスト
- [ ] アプリ名（日本語・英語）
- [ ] 短い説明
- [ ] 詳細説明（4000文字以内）
- [ ] キーワード 5-10個
- [ ] サポートURL
- [ ] プライバシーポリシーURL
- [ ] カテゴリ選択（Lifestyle/Productivity）
- [ ] 対象年齢設定

---

## Phase 3: ビルド・署名準備（3-5日）

### 1. 署名証明書・プロビジョニングプロファイル（iOS）

#### Apple Certificate 取得
```bash
# 1. Apple Developer Account にログイン
# 2. Certificates, Identifiers & Profiles にアクセス
# 3. "Certificates" → "+" → "App Store and Ad Hoc" 選択
# 4. CSR (Certificate Signing Request) をアップロード
#    - Macキーチェーン、または FlutterFlow で自動生成可
# 5. Certificate ダウンロード（.cer）
# 6. Keychain に登録
```

#### App ID 作成
```
Bundle ID: com.kairos.app
App Name: Kairos
Capabilities: Push Notifications, Sign in with Apple（今後）
```

#### Provisioning Profile 作成
```
Type: App Store
Certificates: 上記で取得したもの
App ID: com.kairos.app
Devices: すべてを選択
```

**FlutterFlow での設定**:
- Certificates (WWDR) をアップロード
- Provisioning Profile をアップロード
- Bundle ID: com.kairos.app

#### チェックリスト
- [ ] Apple Certificate 取得
- [ ] App ID 登録
- [ ] Provisioning Profile 取得
- [ ] FlutterFlow へ設定

### 2. キーストア・署名設定（Android）

#### Keystore ファイル生成
```bash
keytool -genkey -v -keystore kairos-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kairos-key \
  -storepass <PASSWORD> \
  -keypass <PASSWORD>
```

**入力項目**:
```
名前: Kairos 開発チーム
所属部署: Engineering
企業: Your Company Name
都市: Tokyo
都道府県: Tokyo
国コード: JP
署名の正確性確認: yes
```

**重要**: keystore ファイルを**絶対に失わない**こと
```
✅ 保管場所: 暗号化外部ストレージ + クラウドバックアップ
✅ パスワード: パスワード管理ツールで保管
❌ 絶対にGitにコミットしない
```

#### Google Play Console での登録
```
Play Console → Settings → App Signing
→ 公開鍵をアップロード
```

#### FlutterFlow での設定
```
Android Settings:
- Keystore: kairos-release.keystore
- Keystore Password: ___
- Key Alias: kairos-key
- Key Password: ___
```

#### チェックリスト
- [ ] Keystore ファイル生成
- [ ] パスワード安全に保管
- [ ] Google Play Console へ公開鍵登録
- [ ] FlutterFlow へ設定

---

## Phase 4: ビルド・テスト（3-7日）

### 1. ローカルテスト

#### 実機テスト
```bash
# iOS
flutter run -d iphone

# Android
flutter run -d android
```

#### テスト項目
- [ ] 全ページ表示確認
- [ ] ログイン・アカウント作成
- [ ] スケジュール・タスク作成・編集・削除
- [ ] グループ作成・管理
- [ ] 位置情報取得
- [ ] 通知機能
- [ ] プッシュ通知受信
- [ ] プレミアム機能（サブスク表示）

### 2. ビルド（Release）

#### iOS ビルド
```bash
flutter build ios --release
```

FlutterFlow ないでは：
```
Settings → iOS → Build
→ Release Mode チェック
→ Build button
```

#### Android ビルド
```bash
flutter build appbundle --release
# または
flutter build apk --release
```

FlutterFlow ないでは：
```
Settings → Android → Build
→ Release Mode チェック
→ Build button
```

---

## Phase 5: App Store申請（iOS）

### 1. App Store Connect 登録

#### アプリ新規登録
```
App Store Connect にログイン
→ "My Apps" → "+"
→ "New App"
→ Platform: iOS
→ App Name: Kairos
→ Bundle ID: com.kairos.app
→ SKU: kairos-001 (任意)
```

### 2. アプリ情報入力

#### Basic Information
```
✅ Category: Productivity
✅ Subcategory: Organizers
✅ Content Rating: 一般向け (実施要)
✅ Pricing: Free
   (Premium は In-App Purchase として別設定)
```

#### Privacy Policy / Support URL
```
✅ Privacy Policy URL: https://kairos.app/privacy-policy
✅ Support URL: https://kairos.app/support
✅ Marketing URL: (オプション) https://kairos.app
```

#### 年齢制限 (Age Ratings)
```
質問に回答:
- 暴力: いいえ
- 恐怖: いいえ
- アルコール・タバコ: いいえ
- 医療情報: いいえ（位置情報は個人情報に該当）
- 個人情報: はい（位置情報共有）
```

### 3. バージョン情報（Build 登録）

#### Version Release Information
```
Version Number: 1.0.0
Build Number: 1
Release Notes: 
"初回リリース
主な機能: カレンダー・スケジュール管理、タスク管理、位置情報共有"
```

#### App Preview & Screenshots
```
✅ 最低 5 枚、最大 10 枚
✅ 解像度: iPhone Pro Max: 1242x2688 px
✅ 言語: Japanese
✅ テキスト: ローカライズ対応
```

#### App Description
```
✅ キーワード: calendar, schedule, task, family, team
✅ Promotional Text: 
"シンプルで使いやすいスケジュール管理アプリ"
✅ Description: 上記で準備したテキスト
✅ Support URL / Privacy Policy: 登録済み
```

### 4. アプリアイコン & 追加情報
```
✅ App Icon: 1024x1024 PNG
✅ Watch App Icon: (不要)
✅ Messages Framework: (不要)
```

### 5. ビルド選択 & テスト

#### Build Selection
```
Builds → 先ほどアップロードした Build を選択
Build Status: "Ready to Submit"状態まで待機
```

#### TestFlight 内部テスト（オプション）
```
TestFlight Testers → "+" → テスターメール
→ テスターが App をダウンロード・テスト
→ フィードバック確認
```

### 6. App Review 情報
```
✅ App Review Information:
  - Contact Email: support@kairos.app
  - Phone: 090-XXXX-XXXX
  - Demo Account: (不要)
  - Notes: 
    "このアプリはスケジュール・タスク管理アプリです。
     位置情報機能は家族・チーム内での共有のみで使用。"
```

### 7. 申請

```
✅ 全項目確認
✅ Pricing and Availability: 確認
✅ "Submit for Review" ボタン
→ Apple Review 開始（通常 1-2日）
```

#### チェックリスト
- [ ] App Store Connect でアプリ登録
- [ ] 基本情報入力
- [ ] プライバシーポリシー URL 登録
- [ ] 年齢制限設定
- [ ] スクリーンショット追加
- [ ] 説明文入力
- [ ] アイコン登録
- [ ] ビルド選択
- [ ] App Review 情報入力
- [ ] Submit for Review

---

## Phase 6: Google Play Store 申請（Android）

### 1. Google Play Console アプリ登録

#### アプリ新規登録
```
Play Console → "Create app"
→ App name: Kairos
→ Default language: 日本語
→ App type: Applications
→ Category: Productivity
→ Email: support@kairos.app
```

### 2. アプリ情報入力

#### App Details
```
✅ App name: Kairos
✅ Short description: 家族・チームのスケジュール管理
✅ Full description: 上記で準備したテキスト
✅ Category: Productivity
✅ Content rating: 一般向け
```

#### App icon & Feature graphic
```
✅ App Icon: 512x512 PNG
✅ Feature Graphic: 1024x500 PNG
✅ Screenshots: 5-8 枚 (1080x1920)
```

#### Content Rating
```
質問票に回答:
Google Play Content Rating Questionnaire
→ すべての質問に「いいえ」または「はい」回答
→ Rating: PEGI3 相当
```

#### Pricing & Distribution
```
✅ Pricing: Free
✅ Free trial: なし
✅ Countries: 全国
✅ Requires payment method: いいえ
```

### 3. ビルド登録

#### Google Play Release
```
Release → Production → Release version
→ APK/App Bundle: Upload
→ Version name: 1.0.0
→ Version code: 1
```

#### Release notes
```
"初回リリース
主な機能: カレンダー・スケジュール管理、タスク管理、位置情報共有"
```

### 4. プライバシー & ポリシー

#### Privacy Policy
```
✅ Privacy policy: https://kairos.app/privacy-policy
✅ Target Audience: Family
✅ Permissions: 
   - Location (GPS)
   - Camera
   - Notification
   - Calendar
```

### 5. Permissions & APIs
```
✅ Sensitive permissions: 確認・同意
  - android.permission.ACCESS_FINE_LOCATION
  - android.permission.CAMERA
  - 他 (AndroidManifest.xml で宣言済みのもの)
```

### 6. 申請

```
✅ 全項目確認
✅ "Submit"
→ Google Play Review 開始（通常 1-3時間、長くて数日）
```

#### チェックリスト
- [ ] Google Play Console でアプリ登録
- [ ] App Details 入力
- [ ] アイコン・スクリーンショット追加
- [ ] Content Rating 回答
- [ ] 価格設定
- [ ] ビルド登録
- [ ] Privacy Policy 設定
- [ ] Permissions 確認
- [ ] Submit

---

## Phase 7: リリース後対応（リリース〜）

### 1. リリース確認
```
iOS:
- App Store で検索可能か確認（最大 6時間）
- ストアページの表示確認

Android:
- Google Play で検索可能か確認（即座）
- ストアページの表示確認
```

### 2. ユーザーサポート開始
```
✅ サポートメール監視開始
✅ バグレポート対応体制
✅ FAQ ページ作成
✅ コミュニティ管理（必要に応じ）
```

### 3. 初期段階の改善
```
Version 1.0.1 計画（1-2週間後）:
- ユーザーフィードバック反映
- 軽微なバグ修正
- パフォーマンス改善
```

### 4. アップデート申請フロー
```
Version UP → Rebuild → TestFlight/Beta テスト
→ App Store Connect/Play Console に新 Build 登録
→ Release notes 更新 → Submit
→ Review 待機 → Approval
```

---

## 📊 全体スケジュール

```
Week 1-2:
  - Developer Account 取得・費用支払い
  - メタデータ・画像準備

Week 3:
  - 署名証明書・キーストア作成
  - ローカルテスト

Week 4:
  - ビルド (Release Mode)
  - App Store Connect/Play Console 登録
  - 申請

Week 5:
  - Review 待機 & 対応
  - Approval 取得
  - リリース

==============================
合計: 約 4-6 週間
```

---

## 💰 必要な費用

| 項目 | 費用 | 時期 |
|------|------|------|
| Apple Developer Program | $99/年 | 即座 |
| Google Play Developer | $25 | 即座 |
| **合計初期費用** | **$124** | 申請前 |
| プレミアム機能（In-App Purchase） | 0 | 実装後 |

---

## ✅ 最終チェックリスト

### ビルド前
- [ ] Firestore セキュリティルール最終確認
- [ ] プライバシーポリシー・利用規約完成
- [ ] すべてのテキストの日本語化完了
- [ ] イメージ・アイコン最終化

### 申請前
- [ ] 実機テスト完了（iOS/Android）
- [ ] Battery/Memory 最適化
- [ ] クラッシュレポート確認
- [ ] Developer Account 準備完了

### 申請時
- [ ] メタデータすべて入力
- [ ] スクリーンショット 5-10 枚
- [ ] プライバシーポリシー URL 確認
- [ ] Release notes 作成

### リリース後
- [ ] App Store/Play Store で表示確認
- [ ] サポートメール監視開始
- [ ] バージョン 1.0.1 計画立案

---

## 🆘 申請時よくある質問

### Q. Apple/Google による審査で却下される理由は？

**よくある理由**:
- プライバシーポリシーが不正確
- クラッシュが発生
- 位置情報の使用目的が不明確
- データ削除機能がない
- COPPA対応（13歳未満）漏れ

**対策**:
- テスト充分実施
- プライバシーポリシー弁護士確認推奨
- User Data Deletion API 実装

### Q. 審査期間はどれくらい？

```
iOS: 1-3 日（通常 1-2 日）
Android: 数時間〜数日（通常 1日以内）
```

### Q. テスターを追加したい場合は？

**iOS**:
```
App Store Connect → TestFlight → Testers
→ Add Tester → メール追加
```

**Android**:
```
Play Console → Testing → Internal testing
→ Testers を追加
```

