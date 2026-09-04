# Kairos 開発進捗管理・申請チェックリスト

## 📊 開発段階別進捗

### ✅ 完了項目

#### 1. 企画・設計フェーズ
- [x] Firestoreデータモデル設計
- [x] Firestore セキュリティルール実装
- [x] 特許回避戦略・差別化ドキュメント作成
- [x] UI/UXデザインガイドライン作成
- [x] iOS/Android対応ガイド作成
- [x] FlutterFlow設定ガイド作成
- [x] 無料版の料金体系設計
- [x] 利用規約・契約書テンプレート作成

#### 2. 法的準備
- [x] 利用規約（Terms of Service）
- [x] プライバシーポリシーテンプレート
- [x] サブスクリプション契約書テンプレート
- [x] 特定商取引法表示テンプレート

---

### 🔄 進行中/今後の項目

#### Phase 1: 事前準備（1-2週間）
- [ ] **個人事業主登録**（必要に応じて）
  - [ ] 開業届提出
  - [ ] 屋号決定
- [ ] **Apple Developer Program 登録**
  - [ ] Apple ID 作成
  - [ ] 契約条件確認
  - [ ] 支払い情報登録（$99/年）
  - [ ] メール確認 → アカウント有効化
- [ ] **Google Play Developer Account 登録**
  - [ ] Googleアカウント確認
  - [ ] 支払い情報登録（$25）
  - [ ] 個人情報・住所入力
  - [ ] アカウント有効化

**期限**: _______________  
**担当**: _______________

#### Phase 2: アプリ情報準備（1週間）
- [ ] **画像・アイコン作成**
  - [ ] アプリアイコン（1024x1024 PNG）
  - [ ] Feature Graphic（1024x500 PNG）
  - [ ] iOS スクリーンショット（5-10枚, 1242x2688）
  - [ ] Android スクリーンショット（5-10枚, 1080x1920）
- [ ] **メタデータ準備**
  - [ ] アプリ名（日本語・英語）
  - [ ] 短い説明
  - [ ] 詳細説明（4000文字以内）
  - [ ] キーワード（5-10個）
  - [ ] プレビューテキスト

**期限**: _______________  
**担当**: _______________

#### Phase 3: 署名・ビルド準備（3-5日）
- [ ] **iOS 証明書・プロファイル作成**
  - [ ] Certificate Signing Request (CSR) 生成
  - [ ] App Store and Ad Hoc Certificate 取得
  - [ ] App ID 登録（com.kairos.app）
  - [ ] Provisioning Profile 作成
  - [ ] FlutterFlow へ登録
- [ ] **Android Keystore 作成**
  - [ ] Keystore ファイル生成
  - [ ] パスワード安全に保管
  - [ ] Google Play Console へ公開鍵登録
  - [ ] FlutterFlow へ登録

**期限**: _______________  
**担当**: _______________

#### Phase 4: ローカルテスト（3-7日）
- [ ] **実機テスト（iOS）**
  - [ ] ホーム画面表示確認
  - [ ] ログイン・新規登録
  - [ ] スケジュール作成・編集・削除
  - [ ] タスク管理
  - [ ] グループ機能
  - [ ] 位置情報取得（iOS 14+対応）
  - [ ] 通知・リマインダー
  - [ ] プッシュ通知
  - [ ] App Store への支払い流れ
  - [ ] クラッシュレポート
- [ ] **実機テスト（Android）**
  - [ ] 上記すべてを Android で実施
  - [ ] 権限要求フロー確認
  - [ ] Google Play への支払い流れ
- [ ] **パフォーマンステスト**
  - [ ] Battery 消費量確認
  - [ ] Memory リーク確認
  - [ ] 起動時間 < 3秒

**期限**: _______________  
**担当**: _______________

#### Phase 5: ビルド（Release）
- [ ] **iOS ビルド作成**
  - [ ] flutter build ios --release
  - [ ] Archive 生成
  - [ ] App Store Connect へアップロード
  - [ ] Build Status "Ready to Submit" まで待機
- [ ] **Android ビルド作成**
  - [ ] flutter build appbundle --release
  - [ ] App Bundle 生成
  - [ ] Google Play Console へアップロード

**期限**: _______________  
**担当**: _______________

#### Phase 6: App Store 申請（iOS）
- [ ] **アプリ登録**
  - [ ] App Store Connect でアプリ登録
  - [ ] Bundle ID: com.kairos.app
  - [ ] Platform: iOS
- [ ] **基本情報入力**
  - [ ] Category: Productivity / Organizers
  - [ ] Pricing: Free
  - [ ] Content Rating: 一般向け
- [ ] **プライバシー関連**
  - [ ] Privacy Policy URL: https://kairos.app/privacy-policy
  - [ ] Support URL: https://kairos.app/support
  - [ ] Marketing URL: https://kairos.app
- [ ] **年齢制限設定**
  - [ ] 個人情報: はい（位置情報共有）
  - [ ] その他: いいえ
- [ ] **App Preview & Screenshots**
  - [ ] 5-10 枚のスクリーンショット
  - [ ] 言語: Japanese
  - [ ] テキスト: ローカライズ対応
- [ ] **App Description**
  - [ ] Keywords: calendar, schedule, task, family, team
  - [ ] Promotional Text: 入力
  - [ ] Description: 入力
- [ ] **Build Selection**
  - [ ] Build: Ready to Submit 状態から選択
- [ ] **App Review Information**
  - [ ] Contact Email: support@kairos.app
  - [ ] Phone: _______________
  - [ ] Demo Account: (不要)
  - [ ] Notes: 位置情報について説明
- [ ] **提出**
  - [ ] Submit for Review

**期限**: _______________  
**担当**: _______________

#### Phase 7: Google Play Store 申請（Android）
- [ ] **アプリ登録**
  - [ ] Play Console でアプリ作成
  - [ ] Package Name: com.kairos.app
  - [ ] App Name: Kairos
- [ ] **アプリ情報入力**
  - [ ] Short description 入力
  - [ ] Full description 入力
  - [ ] Category: Productivity
- [ ] **画像関連**
  - [ ] App Icon: 512x512 PNG
  - [ ] Feature Graphic: 1024x500 PNG
  - [ ] Screenshots: 5-8 枚
- [ ] **Content Rating**
  - [ ] Questionnaire 回答
  - [ ] Rating: PEGI3 相当
- [ ] **Pricing & Distribution**
  - [ ] Pricing: Free
  - [ ] Countries: 全国
- [ ] **ビルド登録**
  - [ ] Release: Production に登録
  - [ ] Version name: 1.0.0
  - [ ] Version code: 1
  - [ ] Release notes: 入力
- [ ] **プライバシー & ポリシー**
  - [ ] Privacy Policy URL: 入力
  - [ ] Target Audience: Family
- [ ] **Permissions & APIs**
  - [ ] Sensitive permissions: 確認
- [ ] **提出**
  - [ ] Submit

**期限**: _______________  
**担当**: _______________

#### Phase 8: Review 待機・対応
- [ ] **Apple Review 対応**
  - [ ] ステータス確認（App Store Connect）
  - [ ] Rejection された場合、原因確認・修正
  - [ ] Resubmit
- [ ] **Google Play Review 対応**
  - [ ] ステータス確認（Play Console）
  - [ ] Rejection された場合、原因確認・修正
  - [ ] Resubmit
- [ ] **Approval 取得**
  - [ ] iOS: Approved ステータス
  - [ ] Android: Published ステータス

**期限**: _______________  
**担当**: _______________

#### Phase 9: リリース・ローンチ
- [ ] **リリース確認**
  - [ ] App Store で検索可能か確認
  - [ ] Google Play で検索可能か確認
  - [ ] ストア掲載情報が正しいか確認
- [ ] **初期ユーザーサポート**
  - [ ] サポートメール監視開始
  - [ ] バグレポート対応体制構築
  - [ ] FAQ ページ作成
- [ ] **初期マーケティング**
  - [ ] SNS での発表
  - [ ] プレスリリース（必要に応じ）
  - [ ] Webサイト更新

**期限**: _______________  
**担当**: _______________

---

## 🎯 最優先実装項目（申請前必須）

### 機能実装チェック
- [ ] **認証**
  - [ ] Email/Password ログイン
  - [ ] アカウント作成・削除
- [ ] **基本機能**
  - [ ] カレンダー表示
  - [ ] スケジュール作成・編集・削除
  - [ ] タスク管理
  - [ ] グループ管理
- [ ] **共有機能**
  - [ ] グループ参加者管理
  - [ ] スケジュール共有
  - [ ] リアルタイム同期
- [ ] **通知**
  - [ ] ローカル通知（リマインダー）
  - [ ] 通知設定画面
- [x] **無料版の料金体系**
  - [x] 有料サブスクリプションを初回リリースから除外
  - [x] In-App Purchase を実装しない
  - [x] [無料版リリース方針](./free-release-plan.md)を確認
- [ ] **データ管理**
  - [ ] アカウント削除時のデータ削除

### セキュリティチェック
- [ ] Firestore セキュリティルール配置
- [ ] HTTPS通信のみ使用
- [ ] プライバシーポリシー実装

### UX チェック
- [ ] 日本語ローカライズ完成
- [ ] 画面遷移スムーズ
- [ ] ボタン・アイコンサイズ適切
- [ ] 色分け表示確認
- [ ] アクセシビリティ確認

---

## 💰 費用概算

| 項目 | 費用 | 支払い時期 |
|------|------|----------|
| Apple Developer Program（年間） | $99 | 申請前 |
| Google Play Developer（一度きり） | $25 | 申請前 |
| ドメイン（kairos.app など） | ¥2,000-5,000/年 | サービス開始時 |
| SSL Certificate（Let's Encrypt） | 無料 | 随時 |
| Firebase（Spark プラン） | 無料枠内 | リリース後 |
| **初期合計** | **約$124** | 申請前 |

---

## 📅 推奨スケジュール

```
Week 1:
  Mon: Developer Account 登録・支払い
  Tue-Thu: メタデータ・画像準備
  Fri: 署名証明書・キーストア作成

Week 2:
  Mon-Wed: ローカルテスト
  Thu: ビルド（Release Mode）
  Fri: App Store Connect/Play Console 登録

Week 3:
  Mon-Tue: メタデータ最終入力
  Wed: 申請（iOS + Android 同時）
  Thu-Fri: Review 待機

Week 4:
  Mon: Approval 取得（予想）
  Tue: リリース確認
  Wed-: ユーザーサポート開始
```

**合計: 約 4週間**

---

## 🆘 困った時の相談先

### Official リソース
- Apple Developer Support: https://developer.apple.com/support/
- Google Play Help: https://support.google.com/googleplay/
- Flutter Documentation: https://flutter.dev/docs
- Firebase Documentation: https://firebase.google.com/docs

### コミュニティ
- Flutter Community: https://github.com/flutter/flutter
- Firebase Slack: https://firebase-community.slack.com
- Reddit: r/flutter, r/androiddev

### 専門家相談（推奨）
- 弁理士（特許・法務）
- 税理士（個人事業主向け）
- App Review コンサルティング（必要に応じ）

---

## ✨ リリース後の継続項目

- [ ] ユーザーレビュー監視
- [ ] クラッシュレポート分析
- [ ] 定期アップデート（1ヶ月ごと）
- [ ] ユーザーサポート充実
- [ ] マーケティング活動
- [ ] プレミアム機能の推進
- [ ] データ分析・改善

