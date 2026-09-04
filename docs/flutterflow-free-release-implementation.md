# Kairos 無料版 FlutterFlow 実装手順

## 初版の構成

初版は Firebase Authentication と Cloud Firestore を FlutterFlow から直接利用する。Cloud Functions、Cloud Storage、Google Maps Platform、有料のアプリ内課金、サーバー経由プッシュ通知は接続しない。

Firebase プロジェクトは `kairos-3d873` を選択し、Firestore は Production モードで作成する。公開前に `firebase/firestore.rules` と `firebase/firestore.indexes.json` をデプロイする。

## 必要なコレクション

FlutterFlow の Firestore 設定で、次のトップレベルコレクションを追加する。

| コレクション | 必須フィールド | 初版の用途 |
| --- | --- | --- |
| `users` | `uid`, `email`, `display_name`, `created_time` | 利用者プロフィール |
| `schedules` | `ownerId`, `title`, `startTime`, `endTime`, `participantIds`, `createdAt`, `updatedAt` | 予定 |
| `tasks` | `ownerId`, `title`, `priority`, `completed`, `createdAt`, `updatedAt` | タスク |
| `sharedGroups` | `ownerId`, `name`, `memberIds`, `createdAt`, `updatedAt` | 共有グループ |

日時はすべて Firestore の `Timestamp`、`participantIds` と `memberIds` は `List<String>` を使用する。`locations` は将来機能用のため、初版の画面・権限要求からは除外する。

## 認証とプロフィール

1. FlutterFlow の Authentication は有効化済み。Firebase Console の Authentication で Email/Password プロバイダーを有効化する。
2. 新規登録画面では `Create Account` アクションの成功後に、`users/{currentUserUid}` を作成する。
3. 作成時は `uid` に Current User UID、`email` に Current User Email、`display_name` に入力値、`created_time` に Current Time を指定する。
4. ログイン済みの利用者は `users/{currentUserUid}` のみを読み書きする。

初版のログインは Email/Password のみとする。Google と Apple のログインボタンは初版の画面から除外する。

## 画面と Firestore アクション

| 画面 | 読み取り | 書き込み |
| --- | --- | --- |
| ホーム | `schedules` を `participantIds` に Current User UID を含む条件で取得 | なし |
| 予定作成 | なし | `schedules` に新規ドキュメントを作成 |
| 予定詳細 | 指定した予定ドキュメント | オーナーだけ更新・削除 |
| タスク一覧 | `tasks` を `ownerId == Current User UID` で取得 | 完了状態の更新 |
| タスク作成 | なし | `tasks` に新規ドキュメントを作成 |
| グループ一覧 | `sharedGroups` を `memberIds` に Current User UID を含む条件で取得 | オーナーだけ作成・更新・削除 |
| 設定 | `users/{currentUserUid}` | 表示名・通知設定の更新 |

予定を作成する際は、`ownerId` を Current User UID、`participantIds` を Current User UID を含むリストとして保存する。複数利用者との共有は、初版ではオーナーが予定またはグループを更新する操作に限定する。

## 通知とアカウント削除

リマインダーは FlutterFlow の Local Notifications を使用する。サーバー経由のプッシュ通知は Cloud Functions を必要とするため、初版では有効化しない。

設定画面に「アカウントを削除」操作を置く。確認ダイアログで了承された場合、利用者自身の `tasks`、所有する `schedules`、所有する `sharedGroups`、`users/{currentUserUid}` を削除してから、FlutterFlow の Delete User アクションで Firebase Authentication アカウントを削除する。複数ユーザーの共有グループは、削除前にオーナーがメンバーを整理するよう案内する。

## 公開前チェック

- Email/Password の登録、ログイン、ログアウト、パスワード再設定を実機で確認する。
- 利用者 A と B の 2 アカウントで、他人のタスクとプロフィールを変更できないことを確認する。
- 予定、タスク、グループの作成、編集、削除を実機で確認する。
- アカウント削除で、本人のプロフィール、タスク、所有予定、Firebase Authentication アカウントが削除されることを確認する。
- アプリの設定画面から、[プライバシーポリシー](../public/privacy-policy.html) と [サポート](../public/index.html) を外部ブラウザで開けるようにする。

## Firebase デプロイ

公開前に、プロジェクトのルートディレクトリで次を実行する。

```powershell
firebase.cmd deploy --only firestore:rules,firestore:indexes,hosting
```

このコマンドは Cloud Functions をデプロイしない。Firebase プロジェクトは Spark プランのままとし、利用量が無料枠を超えないよう Firebase Console で定期的に確認する。