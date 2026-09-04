# FlutterFlow Cloud Functions Integration

## Firebase connection

In FlutterFlow, connect the project to Firebase project `kairos-3d873` and set the Cloud Functions region to `us-central1`. Every callable function except `healthCheck` requires a signed-in Firebase user.

## Schedule actions

| Action name | Function | Required parameters |
| --- | --- | --- |
| Create Schedule | `createSchedule` | `title`, `startTime`, `endTime` |
| Load Schedule | `getSchedule` | `scheduleId` |
| Update Schedule | `updateSchedule` | `scheduleId` and changed fields |
| Delete Schedule | `deleteSchedule` | `scheduleId` |
| List Schedules | `listSchedules` | Optional `startDate`, `endDate`, `limit` |
| Update RSVP | `updateParticipantStatus` | `scheduleId`, `status` |

Use Firestore `Timestamp` values for `startTime`, `endTime`, `startDate`, and `endDate`. Store the response `data.id` after creation for navigation to the schedule detail page.

## Task actions

| Action name | Function | Required parameters |
| --- | --- | --- |
| Create Task | `createTask` | `title`, `priority` (`low`, `medium`, or `high`) |
| Load Task | `getTask` | `taskId` |
| Update Task | `updateTask` | `taskId` and changed fields |
| Delete Task | `deleteTask` | `taskId` |
| List Tasks | `listTasks` | Optional `completed` boolean |

## Group actions

| Action name | Function | Required parameters |
| --- | --- | --- |
| Create Group | `createGroup` | `name` |
| Load Group | `getGroup` | `groupId` |
| Update Group | `updateGroup` | `groupId` and changed fields |
| Delete Group | `deleteGroup` | `groupId` |
| List Groups | `listGroups` | None |
| Add Group Member | `addGroupMember` | `groupId`, `memberId`, `role` (`editor` or `viewer`) |

## Other actions

| Area | Function | Required parameters |
| --- | --- | --- |
| Location | `updateLocation` | `latitude`, `longitude`; optional `accuracy` |
| Location | `getLocation` | Optional `userId` |
| Location | `setLocationSharing` | `sharedWith` UID array |
| Location | `listSharedLocations` | None |
| Notifications | `registerDeviceToken` | `token` |
| Notifications | `unregisterDeviceToken` | `token` |
| Notifications | `sendScheduleInvitation` | `scheduleId`, `title`, `participantIds` |
| Subscription | `getSubscriptionPlans` | None |
| Subscription | `getMySubscription` | None |

## Recommended page actions

1. On the Home page load, call `listSchedules` for the visible calendar range.
2. On the Tasks page load, call `listTasks` with `completed: false`.
3. After a successful create or update action, refresh the corresponding list and navigate back.
4. At app startup after authentication, obtain the FCM token and call `registerDeviceToken`.

## Local testing

For local development, point the app at the running Functions Emulator on port `5001`, Auth Emulator on port `9099`, and Firestore Emulator on port `8080`. Do not enable these emulator hosts in production builds.