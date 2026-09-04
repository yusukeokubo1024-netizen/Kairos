# Kairos - iOS/Android クロスプラットフォーム実装ガイド

## 📱 プラットフォーム対応要件

### ターゲットOSバージョン（推奨）

```
iOS:      14.0以上（実装効率・セキュリティのバランス）
Android:  9.0以上（API Level 28）
```

**理由:**
- iOS 14: 新しいプライバシー機能、バグフィックス
- Android 9: ジェスチャーナビゲーション対応、セキュリティ向上
- このバージョン以下は市場シェア < 5%

---

## 🔧 プラットフォーム固有の設定

### 1. iOS対応設定

#### 環境情報
```
Deployment Target:  iOS 14.0
SDK Version:        17.0以上推奨
言語:               Swift + Objective-C
```

#### Info.plist必須設定

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 位置情報 -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Kairosはスケジュール・タスク管理に位置情報を使用します</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>バックグラウンドでの位置情報取得を許可しますか？</string>
  
  <!-- カメラ -->
  <key>NSCameraUsageDescription</key>
  <string>Kairosはスケジュールに写真を添付するためカメラを使用します</string>
  
  <!-- フォトライブラリ -->
  <key>NSPhotoLibraryUsageDescription</key>
  <string>写真ライブラリにアクセスしていますか？</string>
  <key>NSPhotoLibraryAddUsageDescription</key>
  <string>Kairosで撮影した写真をライブラリに保存します</string>
  
  <!-- カレンダー -->
  <key>NSCalendarsUsageDescription</key>
  <string>KairosはiOSカレンダーと同期します</string>
  
  <!-- リマインダー -->
  <key>NSRemindersUsageDescription</key>
  <string>Kairosはリマインダーアプリと連携します</string>
  
  <!-- 連絡先 -->
  <key>NSContactsUsageDescription</key>
  <string>参加者を追加するため連絡先にアクセスします</string>
  
  <!-- 生体認証 -->
  <key>NSFaceIDUsageDescription</key>
  <string>Face IDで認証します</string>
  
  <!-- Bluetooth -->
  <key>NSBluetoothPeripheralUsageDescription</key>
  <string>Bluetooth接続デバイスと連携します</string>
  
  <!-- バックグラウンド処理 -->
  <key>UIBackgroundModes</key>
  <array>
    <string>location</string>
    <string>remote-notification</string>
    <string>fetch</string>
  </array>
</dict>
</plist>
```

#### Capabilities設定
- ✅ Push Notifications
- ✅ Background Modes (Location, Remote Notification)
- ✅ Sign in with Apple (将来実装)
- ✅ iCloud (CloudKit)

---

### 2. Android対応設定

#### AndroidManifest.xml必須設定

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.kairos.app">

    <!-- 位置情報 -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- カメラ -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- ファイルアクセス -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- カレンダー/連絡先 -->
    <uses-permission android:name="android.permission.READ_CALENDAR" />
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />
    <uses-permission android:name="android.permission.READ_CONTACTS" />
    
    <!-- プッシュ通知 -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Bluetooth -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    
    <!-- インターネット -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application>
        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/LaunchTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### build.gradle設定

```gradle
android {
    compileSdk 34  // 最新
    
    defaultConfig {
        minSdkVersion 28  // Android 9
        targetSdkVersion 34
        
        // Firebase Cloud Messaging
        multiDexEnabled true
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
        }
    }
}

dependencies {
    // Firebase
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    
    // 位置情報
    implementation 'com.google.android.gms:play-services-location:21.0.1'
    
    // カメラ
    implementation 'androidx.camera:camera-camera2:1.2.3'
    
    // 生体認証
    implementation 'androidx.biometric:biometric:1.1.0'
}
```

---

## 🔌 ネイティブ機能の実装

### 1. 位置情報（GPS）

#### iOS実装（Swift）
```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, 
                        didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            // Firestore に保存
            saveLocationToFirestore(lat: latitude, lng: longitude)
        }
    }
}
```

#### Android実装（Kotlin）
```kotlin
import android.location.Location
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices

class LocationManager(context: Context) {
    private val fusedLocationClient: FusedLocationProviderClient = 
        LocationServices.getFusedLocationProviderClient(context)
    
    fun getLastLocation() {
        fusedLocationClient.lastLocation
            .addOnSuccessListener { location: Location? ->
                if (location != null) {
                    val latitude = location.latitude
                    val longitude = location.longitude
                    // Firestore に保存
                    saveLocationToFirestore(latitude, longitude)
                }
            }
    }
}
```

### 2. カメラ（写真操作）

#### iOS実装（UIImagePickerController）
```swift
import UIKit

class CameraManager: NSObject, UIImagePickerControllerDelegate {
    let picker = UIImagePickerController()
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.allowsEditing = true
            // Present picker
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            // Upload to Firebase Storage
            uploadImageToStorage(image)
        }
    }
}
```

#### Android実装（ACTION_IMAGE_CAPTURE）
```kotlin
import android.content.Intent
import android.provider.MediaStore

class CameraManager(activity: Activity) {
    fun openCamera() {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        activity.startActivityForResult(intent, REQUEST_IMAGE_CAPTURE)
    }
    
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_IMAGE_CAPTURE && resultCode == Activity.RESULT_OK) {
            val imageBitmap = data?.getParcelableExtra<Bitmap>("data")
            // Upload to Firebase Storage
            uploadImageToStorage(imageBitmap)
        }
    }
}
```

### 3. プッシュ通知

#### Firebase Cloud Messaging（両プラットフォーム共通）

**iOS設定:**
```swift
import FirebaseMessaging

UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

Messaging.messaging().delegate = self
```

**Android設定:**
```kotlin
import com.google.firebase.messaging.FirebaseMessaging

FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
    if (task.isSuccessful) {
        val token = task.result
        // Store token in Firestore
        saveTokenToFirestore(token)
    }
}
```

### 4. カレンダー同期

#### iOS（EventKit）
```swift
import EventKit

class CalendarSync {
    let eventStore = EKEventStore()
    
    func syncToDeviceCalendar(schedule: Schedule) {
        eventStore.requestAccess(to: .event) { granted, _ in
            if granted {
                let event = EKEvent(eventStore: self.eventStore)
                event.title = schedule.title
                event.startDate = schedule.startTime
                event.endDate = schedule.endTime
                event.location = schedule.location
                
                try? self.eventStore.save(event, span: .thisEvent)
            }
        }
    }
}
```

#### Android（CalendarProvider）
```kotlin
import android.provider.CalendarContract

class CalendarSync(context: Context) {
    fun syncToDeviceCalendar(schedule: Schedule) {
        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, schedule.title)
            put(CalendarContract.Events.DTSTART, schedule.startTime)
            put(CalendarContract.Events.DTEND, schedule.endTime)
            put(CalendarContract.Events.EVENT_LOCATION, schedule.location)
        }
        
        context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
    }
}
```

### 5. 生体認証（Face ID / 指紋認証）

#### iOS（LocalAuthentication）
```swift
import LocalAuthentication

class BiometricAuth {
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                                  localizedReason: "Kairosにログイン") { success, _ in
                completion(success)
            }
        }
    }
}
```

#### Android（BiometricPrompt）
```kotlin
import androidx.biometric.BiometricPrompt

class BiometricAuth(activity: FragmentActivity) {
    fun authenticate() {
        val biometricPrompt = BiometricPrompt(activity, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                // Authentication succeeded
            }
        })
        
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Kairos認証")
            .setNegativeButtonText("キャンセル")
            .build()
        
        biometricPrompt.authenticate(promptInfo)
    }
}
```

---

## 📋 FlutterFlow での実装方法

### ネイティブプラグイン追加

FlutterFlowの「Custom Code」セクションで以下を設定：

1. **firebase_messaging** (プッシュ通知)
   ```yaml
   dependencies:
     firebase_messaging: ^14.0.0
   ```

2. **geolocator** (位置情報)
   ```yaml
   dependencies:
     geolocator: ^9.0.0
   ```

3. **image_picker** (カメラ/フォト)
   ```yaml
   dependencies:
     image_picker: ^1.0.0
   ```

4. **device_calendar** (カレンダー同期)
   ```yaml
   dependencies:
     device_calendar: ^6.0.0
   ```

5. **local_auth** (生体認証)
   ```yaml
   dependencies:
     local_auth: ^2.1.0
   ```

6. **flutter_blue** (Bluetooth)
   ```yaml
   dependencies:
     flutter_blue: ^0.8.0
   ```

### 権限ハンドラ設定

```dart
// permissions_handler.dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestLocationPermission() async {
  final status = await Permission.location.request();
  return status.isGranted;
}

Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}

Future<bool> requestNotificationPermission() async {
  final status = await Permission.notification.request();
  return status.isGranted;
}
```

---

## 🧪 テスト・デバイス確認

### iOS テスト環境

```
デバイス: iPhone 14 / 15
iOS: 14.0 ~ 17.0
Xcode: 15.0以上
Apple Developer Account: 必須（配布時）
```

テストコマンド：
```bash
flutter run -d iphone
```

### Android テスト環境

```
デバイス: Pixel 6 / 7 / Samsung Galaxy
Android: 9.0 ~ 14.0
Android Studio: 2023.1以上
Google Play Console: 必須（配布時）
```

テストコマンド：
```bash
flutter run -d android
```

---

## 📦 ビルド・配布方法

### 1. iOS配布（App Store）

#### 準備
```bash
# Certificate と Provisioning Profile 取得
# Apple Developer Account で"Identifiers", "Certificates", "Devices"設定
```

#### ビルド
```bash
flutter build ios --release
```

#### アップロード
- Xcode → Product → Archive
- App Store Connect でメタデータ設定
- TestFlight で内部テスト
- App Store Review へ申請

### 2. Android配布（Google Play）

#### 準備
```bash
# keystore ファイル生成
keytool -genkey -v -keystore kairos-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kairos-key
```

#### ビルド
```bash
flutter build appbundle --release
```

#### アップロード
- Google Play Console にログイン
- APK/App Bundle をアップロード
- Play Console Review へ申請

---

## 🔒 セキュリティチェックリスト

- [ ] Info.plist / AndroidManifest.xml で権限明記
- [ ] 位置情報をバックグラウンドで取得しない（バッテリー/プライバシー配慮）
- [ ] Firebase セキュリティルール確認（iOS/Android共通）
- [ ] HTTPS通信のみ使用
- [ ] Sensitive データ（トークン等）は暗号化保存
- [ ] 生体認証フォールバック設定
- [ ] キャッシュデータクリア機能実装
- [ ] データベースバックアップ機能実装

---

## 📊 マルチプラットフォーム対応チェックリスト

| 項目 | iOS | Android | 状態 |
|------|-----|---------|------|
| 基本UI | ✅ | ✅ | 実装中 |
| 位置情報 | ⚙️ | ⚙️ | 要実装 |
| カメラ | ⚙️ | ⚙️ | 要実装 |
| プッシュ通知 | ⚙️ | ⚙️ | 要実装 |
| カレンダー同期 | ⚙️ | ⚙️ | 要実装 |
| 生体認証 | ⚙️ | ⚙️ | 要実装 |
| Bluetooth | ⚙️ | ⚙️ | 要実装 |
| テスト | ⬜ | ⬜ | 未開始 |
| 配布準備 | ⬜ | ⬜ | 未開始 |

---

## 📚 参考ドキュメント

- [Flutter 公式ドキュメント](https://flutter.dev)
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Firebase Android SDK](https://firebase.google.com/docs/android/setup)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Google Play Console](https://play.google.com/console)
