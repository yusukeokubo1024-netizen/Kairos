process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "kairos-3d873" });

const { NotificationService } = require("../lib/services/notificationService");

async function run() {
  await NotificationService.registerToken("user-1", "token-1");
  await NotificationService.registerToken("user-1", "token-1");
  const registered = await admin.firestore().collection("deviceTokens").doc("user-1").get();
  if (registered.data().tokens.length !== 1) throw new Error("Token was not deduplicated");

  const sentCount = await NotificationService.sendToUsers(["user-without-token"], "Test", "Test");
  if (sentCount !== 0) throw new Error("Unexpected notification send result");

  await NotificationService.unregisterToken("user-1", "token-1");
  const unregistered = await admin.firestore().collection("deviceTokens").doc("user-1").get();
  if (unregistered.data().tokens.length !== 0) throw new Error("Token was not removed");
  await admin.firestore().collection("deviceTokens").doc("user-1").delete();
  console.log("Notification service integration test passed");
}

run().catch((error) => { console.error(error); process.exit(1); });