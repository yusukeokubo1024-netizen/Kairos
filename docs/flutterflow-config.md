# Kairos - FlutterFlow設定ガイド

## 📱 FlutterFlowでのプラットフォーム設定

### プロジェクト基本設定

#### Package Name / Bundle ID

| プラットフォーム | 設定値 |
|------------|--------|
| **iOS** | `com.kairos.app` (Bundle ID) |
| **Android** | `com.kairos.app` (Package Name) |

#### アプリ名
```
Display Name: Kairos
Short Display Name: Kairos
```

---

## 🔑 Firebase 連携設定

### 1. GoogleService ファイル登録

#### iOS（GoogleService-Info.plist）

1. Firebase Console で iOS アプリ追加
2. `GoogleService-Info.plist` ダウンロード
3. FlutterFlow の「Settings」→「iOS」→ファイルアップロード

#### Android（google-services.json）

1. Firebase Console で Android アプリ追加
2. `google-services.json` ダウンロード
3. FlutterFlow の「Settings」→「Android」→ファイルアップロード

### 2. Firebase 認証設定

#### Firestore Database
- ロケーション: `asia-northeast1` (東京)
- モード: `Production`
- セキュリティルール: [firestore.rules を参照](./firebase/firestore.rules)

#### Authentication
有効化するサインイン方法：
- ✅ Email/Password
- ✅ Google
- ✅ Apple (iOS)
- ✅ Anonymous

#### Storage
- バケット: `gs://kairos-3d873.appspot.com`
- ロケーション: `asia-northeast1`

---

## 🎨 マルチプラットフォーム UI設定

### レスポンシブ設計

#### ブレークポイント設定

FlutterFlow内で以下の幅で設定：

```
Mobile Small (xs):    < 360px
Mobile (sm):          360px - 479px
Mobile Large (md):    480px - 767px
Tablet (lg):          768px - 1024px
Desktop (xl):         > 1024px
```

#### 条件付きUI表示

```
Responsive Visibility を使用：
- 「Show only when」設定で各ブレークポイントを指定
- iOS/Android共通のレスポンシブレイアウト
```

### サンドボックス対応

#### iOS
```
- Safe Area 対応 (notch/Dynamic Island)
- Padding: top 12px, bottom 24px
```

#### Android
```
- System UI Inset対応 (status bar/nav bar)
- Padding: top 16px, bottom 32px
```

---

## 📍 ネイティブプラグイン統合

### FlutterFlow「Custom Code」セクション設定

#### pubspec.yaml の依存関係追加

FlutterFlow の Custom Code → pubspec.yaml に以下を追加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.20.0
  firebase_auth: ^4.12.0
  firebase_firestore: ^4.12.0
  firebase_storage: ^11.2.0
  firebase_messaging: ^14.6.0
  
  # ロケーション
  geolocator: ^9.0.2
  geocoding: ^2.1.0
  
  # カメラ・画像
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  
  # カレンダー
  table_calendar: ^3.0.9
  device_calendar: ^6.0.3
  
  # 生体認証
  local_auth: ^2.1.7
  
  # 通知
  flutter_local_notifications: ^14.1.0
  
  # Bluetooth
  flutter_blue: ^0.8.8
  
  # 権限管理
  permission_handler: ^11.4.4
  
  # その他ユーティリティ
  intl: ^0.19.0
  uuid: ^4.0.0
  equatable: ^2.0.5
```

### iOS 追加設定

#### Podfile カスタマイズ

FlutterFlow内の「iOS」セクションで以下を設定：

```ruby
# iOS minimum deployment target
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

#### Info.plist 許可要求メッセージ

FlutterFlow の「iOS」設定で以下を入力：

```
NSLocationWhenInUseUsageDescription:
"Kairosはスケジュール・タスク管理に位置情報を使用します"

NSLocationAlwaysAndWhenInUseUsageDescription:
"バックグラウンドでの位置情報取得を許可しますか？"

NSCameraUsageDescription:
"Kairosはスケジュールに写真を添付するためカメラを使用します"

NSPhotoLibraryUsageDescription:
"写真ライブラリにアクセスしていますか？"

NSCalendarsUsageDescription:
"KairosはiOSカレンダーと同期します"

NSFaceIDUsageDescription:
"Face IDで認証します"
```

### Android 追加設定

#### AndroidManifest.xml カスタマイズ

FlutterFlow の「Android」セクションで以下を設定：

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### build.gradle カスタマイズ

```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 28
        targetSdkVersion 34
    }
}
```

---

## 🧪 ローカル開発・テスト

### FlutterFlow プレビューモード

1. **Web Preview** - ブラウザでプレビュー
2. **iOS Simulator** - Xcode シミュレータ
3. **Android Emulator** - Android Studio エミュレータ

### デバイステスト

#### iOS デバイステスト

```bash
# FlutterFlow から生成された Flutter プロジェクトをダウンロード
cd kairos
flutter pub get
flutter run -d <iOS Device ID>
```

#### Android デバイステスト

```bash
flutter devices  # デバイス確認
flutter run -d <Android Device ID>
```

---

## 📲 プッシュ通知設定

### Firebase Cloud Messaging (FCM)

#### 1. iOS 通知設定

FlutterFlow の「Notifications」セクション：
- Firebase Cloud Messaging を有効化
- APNs Certificate をアップロード

#### 2. Android 通知設定

Firebase Console → Project Settings → Cloud Messaging タブ：
- Server API Key を確認（自動生成済み）
- Android Notification Channel を設定

#### 3. FlutterFlow Notification Action

「Custom Code」で以下を実装：

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// バックグラウンド通知ハンドラ
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}

// 通知クリック時のハンドラ
FirebaseMessaging.instance.onMessageOpenedApp.listen((RemoteMessage message) {
  // スケジュール詳細画面へ遷移
  if (message.data.containsKey('scheduleId')) {
    navigateToScheduleDetail(message.data['scheduleId']);
  }
});
```

---

## 🌍 多言語対応設定

### i18n (国際化)

#### 言語ファイル構成

FlutterFlow の「Localization」セクションで以下を設定：

| 言語 | コード | ファイル |
|------|-------|---------|
| 日本語 | ja | `lib/locales/ja.json` |
| 英語 | en | `lib/locales/en.json` |

#### 言語ファイル例（ja.json）

```json
{
  "app_title": "Kairos",
  "home_title": "ホーム",
  "tasks_title": "タスク",
  "groups_title": "グループ",
  "settings_title": "設定",
  
  "new_schedule": "新しいスケジュール",
  "new_task": "新しいタスク",
  "new_group": "新しいグループ",
  
  "location": "位置情報",
  "participants": "参加者",
  "priority": "優先度",
  "due_date": "期限",
  
  "edit": "編集",
  "delete": "削除",
  "save": "保存",
  "cancel": "キャンセル",
  
  "loading": "読み込み中...",
  "no_data": "データがありません",
  "error": "エラーが発生しました"
}
```

---

## 📊 パフォーマンス最適化

### FlutterFlow 最適化設定

#### Build Settings

```
Release Mode でのビルド推奨：
flutter build ios --release
flutter build apk --release
flutter build appbundle --release
```

#### Code Obfuscation

FlutterFlow の「Build」セクション：
- Android: Obfuscation ON
- iOS: Bitcode ON

#### Asset 最適化

- 画像: WebP または PNG with compression
- サイズ: 最大 5MB未満（アイコンは < 1MB）
- キャッシュ: `cached_network_image` 使用

---

## 🔐 セキュリティ設定

### Firebase セキュリティルール

[firestore.rules](./firebase/firestore.rules) を参照

### 認証セキュリティ

1. **Email Verification** を必須に
2. **ReCAPTCHA** を有効化
3. **2FA (Two-Factor Authentication)** 実装（将来）

### データ暗号化

- Firestore: 自動暗号化（Firebase デフォルト）
- Firebase Storage: 自動暗号化
- Local Cache: Dart `SharedPreferences` で暗号化

---

## 📋 ビルド・配布チェックリスト

### ビルド前確認

- [ ] package/bundle ID が正しい
- [ ] GoogleService ファイル登録済み
- [ ] パーミッション設定完了
- [ ] アイコン・スプラッシュ画面設定
- [ ] バージョン番号設定 (e.g., 1.0.0)
- [ ] ビルド番号設定 (iOS: 1, Android: 1)

### iOS リリース準備

- [ ] Apple Developer Account 登録
- [ ] App ID 登録
- [ ] Certificate・Provisioning Profile 取得
- [ ] アプリアイコン・スクリーンショット準備
- [ ] プライバシーポリシー URL 用意
- [ ] TestFlight テスト実施

### Android リリース準備

- [ ] Google Play Developer Account 登録
- [ ] keystore ファイル生成・保管
- [ ] App Release Notes 準備
- [ ] アプリアイコン・スクリーンショット準備
- [ ] プライバシーポリシー URL 用意
- [ ] Google Play Console テスト実施

---

## 🚀 ローンチ計画

### Phase 1: テスト
- Internal Testing (3-4週間)
- TestFlight (iOS) / Google Play Beta (Android)

### Phase 2: ソフトローンチ
- 限定国でリリース（日本）

### Phase 3: グローバルローンチ
- 複数国での同時配布

