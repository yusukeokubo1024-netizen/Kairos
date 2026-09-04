# Kairos グループ招待フロー実装手順（FlutterFlow）

## 背景

無料版の初期設計（[flutterflow-free-release-implementation.md](./flutterflow-free-release-implementation.md)）には、他人を `sharedGroups` に追加する具体的な手段が定義されていなかった。オーナーが相手の Firebase UID（ユーザーには見えないランダムな内部ID）を直接指定しない限りメンバーを追加できず、実際には誰も招待できない状態だった。

Cloud Functions を使わず、Firestore のセキュリティルールだけで動く招待フローを追加する。追加コストは発生しない。

## 仕組み

Firestore のドキュメントID（`sharedGroups/{groupId}` の `groupId`）は20文字程度のランダム文字列で、推測はほぼ不可能。この `groupId` そのものを「招待コード」として使う。

- グループIDを **知っている人だけ** が、そのグループを1件取得（`get`）してプレビューできる
- グループの一覧取得（`list`、クエリ）は自分がすでにメンバーのグループに限られる
- 招待コードを知る人は、**自分自身のUIDだけ** を `memberIds` に追加する更新が可能（他人を追加したり、他のフィールドを書き換えることはできない）

セキュリティルールは [firebase/firestore.rules](../firebase/firestore.rules) に実装済み。デプロイは次のコマンドで行う。

```powershell
firebase.cmd deploy --only firestore:rules,firestore:indexes,hosting
```

## FlutterFlow に追加する画面・アクション

### 1. グループ詳細画面に「招待」ボタンを追加

- 表示するグループの `groupId`（ドキュメントID）を使い、次のようなテキストを共有する
  ```
  Kairosで予定を共有しよう！
  「グループに参加」画面でこのコードを入力してください: {groupId}
  ```
- FlutterFlow の **Share** アクション（ネイティブ共有シート）でSMS・LINE・メールなどに渡せる

### 2. 新規画面「グループに参加」を作成

| ステップ | UI | アクション |
| --- | --- | --- |
| 1. コード入力 | テキストフィールド + 「確認」ボタン | 入力値を `groupId` としてページ状態に保持 |
| 2. プレビュー取得 | - | **Get Document**: `sharedGroups/{groupId}`（クエリではなく単体取得）。存在しない/コード誤りの場合はエラー表示 |
| 3. プレビュー表示 | グループ名・メンバー数を表示、「参加する」ボタン | - |
| 4. 参加 | - | **Update Document**: `sharedGroups/{groupId}` の `memberIds` に `arrayUnion(Current User UID)` を適用。他のフィールドは一切変更しない |
| 5. 完了 | グループ詳細画面へ遷移 | - |

**重要**: ステップ4の Update Document アクションで、`memberIds` 以外のフィールド（`ownerId`, `name` など）を一緒に送信しないこと。セキュリティルールが「`memberIds` と `updatedAt` 以外のフィールドは変更禁止」を強制しているため、他のフィールドを含めると更新が拒否される。

### 3. メンバー一覧の表示名解決

`memberIds` は UID の配列（表示名は含まない）。メンバー一覧画面では、各 UID ごとに `users/{uid}` を個別取得（Get Document）して `display_name` を表示する。ユーザー一覧のクエリ（List）は禁止されているため、必ず「UID を指定した単体取得」で行うこと。

## 公開前チェック（追加分）

- [ ] コードを知らない第三者が、対象グループを検索・列挙できないことを確認する（`list` クエリで他人のグループが返らないこと）
- [ ] 参加フローで、`memberIds` 以外のフィールドを書き換えようとすると拒否されることを確認する
- [ ] 誤ったコードを入力した場合にエラーメッセージが表示されることを確認する
- [ ] 既にメンバーのグループに再度参加しようとした場合の挙動を確認する（ルール上、二重追加は拒否されるため、事前に自分がメンバーかどうかで「参加する」ボタンの表示を出し分けるとよい）
