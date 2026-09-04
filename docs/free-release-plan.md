# Kairos 無料版リリース方針

## 目的

初回リリースは、運用に追加料金が発生しない Firebase 構成とし、有料サブスクリプションを提供しない。

## リリース対象

- Firebase Authentication
- Cloud Firestore の Spark プラン無料枠内でのデータ保存
- Firebase Hosting による法務・サポートページの公開
- 端末内ローカル通知

アプリは Firestore セキュリティルールを通じて直接データを操作する。Firestore の無料枠を超えないよう、位置情報の常時送信、短い間隔でのポーリング、大量データの一括読み込みは初回リリースでは実装しない。

## リリース対象外

- Cloud Functions の本番デプロイ
- 有料サブスクリプションとアプリ内課金
- Cloud Storage への画像・動画アップロード
- Google Maps Platform など請求先登録が必要な外部 API
- 常時バックグラウンド位置情報共有
- Firebase Cloud Messaging によるサーバープッシュ通知
- Google、Apple、電話番号、匿名のログイン

`firebase.json` から Functions のデプロイ設定を外しているため、通常の `firebase deploy` では Firestore ルールとインデックスのみが対象となる。Functions コードはローカルエミュレータでの検証用に保持する。

## 料金に関する注意

Firebase の無料枠には利用上限がある。上限超過時の請求を避けるため、Firebase プロジェクトは Spark プランのまま運用し、請求先アカウントを接続しない。上限に達したサービスは停止するため、利用量を Firebase Console で定期的に確認する。

ストア公開には Firebase とは別に次の固定費が必要であり、ゼロにはできない。

| 項目 | 費用 |
| --- | --- |
| Apple Developer Program | 年額 99 USD |
| Google Play Developer | 登録時 25 USD |

## 将来の有料機能

有料プランを再開する場合は、ストアのアプリ内課金設定、サーバー側購入検証、Firebase の請求先設定、利用量アラートをすべて用意してから、別バージョンとして公開する。