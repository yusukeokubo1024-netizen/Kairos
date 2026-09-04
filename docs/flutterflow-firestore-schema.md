# FlutterFlow Firestore Schema

Create the following collections in FlutterFlow's Firestore schema editor. Field names and types must match exactly so that the deployed Firestore rules permit direct access.

## schedules

| Field | FlutterFlow type | Required |
| --- | --- | --- |
| `ownerId` | String | Yes |
| `title` | String | Yes |
| `description` | String | No |
| `startTime` | DateTime | Yes |
| `endTime` | DateTime | Yes |
| `location` | String | No |
| `color` | String | No |
| `participantIds` | List of String | Yes |
| `createdAt` | DateTime | Yes |
| `updatedAt` | DateTime | Yes |

For direct FlutterFlow creation, set `ownerId` to the authenticated user's UID, include that UID in `participantIds`, and set timestamps with the current time.

## tasks

| Field | FlutterFlow type | Required |
| --- | --- | --- |
| `ownerId` | String | Yes |
| `title` | String | Yes |
| `description` | String | No |
| `dueDate` | DateTime | No |
| `priority` | String | Yes |
| `completed` | Boolean | Yes |
| `category` | String | No |
| `tags` | List of String | No |
| `createdAt` | DateTime | Yes |
| `updatedAt` | DateTime | Yes |

Use `low`, `medium`, or `high` for `priority` and initialize `completed` as `false`.

## sharedGroups

| Field | FlutterFlow type | Required |
| --- | --- | --- |
| `ownerId` | String | Yes |
| `name` | String | Yes |
| `description` | String | No |
| `memberIds` | List of String | Yes |
| `createdAt` | DateTime | Yes |
| `updatedAt` | DateTime | Yes |

Set `ownerId` to the authenticated user's UID and include it in `memberIds` when creating a group.

## locations

| Field | FlutterFlow type | Required |
| --- | --- | --- |
| `userId` | String | Yes |
| `latitude` | Double | Yes |
| `longitude` | Double | Yes |
| `accuracy` | Double | No |
| `sharedWith` | List of String | No |
| `timestamp` | DateTime | Yes |

Use one document per user and use their UID as the document ID. The owner may update their own location; users listed in `sharedWith` may read it.

## Query configuration

On each list page, filter by the authenticated user's UID:

| Page | Collection | Filter |
| --- | --- | --- |
| Home | `schedules` | `participantIds` array contains current user's UID |
| Tasks | `tasks` | `ownerId` equals current user's UID |
| Groups | `sharedGroups` | `memberIds` array contains current user's UID |

Use ascending `startTime` for schedules and ascending `dueDate` for tasks. The required indexes are deployed from `firebase/firestore.indexes.json`.