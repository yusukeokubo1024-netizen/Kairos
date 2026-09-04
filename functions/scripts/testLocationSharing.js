process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "kairos-3d873" });

const { LocationService } = require("../lib/services/locationService");

async function run() {
  const location = await LocationService.updateLocation(
    "owner-1",
    35.6812,
    139.7671,
    10
  );
  if (location.latitude !== 35.6812 || location.sharedWith !== undefined) {
    throw new Error("Location was not created correctly");
  }

  await LocationService.setSharedWith("owner-1", ["viewer-1"]);
  const sharedLocation = await LocationService.getLocation("viewer-1", "owner-1");
  if (sharedLocation.longitude !== 139.7671) {
    throw new Error("Shared location was not retrieved");
  }

  const sharedLocations = await LocationService.listSharedLocations("viewer-1");
  if (!sharedLocations.some((item) => item.userId === "owner-1")) {
    throw new Error("Shared location was not listed");
  }

  try {
    await LocationService.getLocation("unauthorized-1", "owner-1");
    throw new Error("Unauthorized location access was allowed");
  } catch (error) {
    if (error.code !== "PERMISSION_DENIED") throw error;
  }

  await admin.firestore().collection("locations").doc("owner-1").delete();
  console.log("Location sharing integration test passed");
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});