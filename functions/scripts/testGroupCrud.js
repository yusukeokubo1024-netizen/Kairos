process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "kairos-3d873" });

const { GroupService } = require("../lib/services/groupService");

async function run() {
  const group = await GroupService.createGroup(
    "owner-1",
    "Integration group",
    "Shared group test"
  );
  await GroupService.addMember("owner-1", group.id, "member-1", "editor");

  const memberGroups = await GroupService.listGroups("member-1");
  if (!memberGroups.some((item) => item.id === group.id)) {
    throw new Error("Member group was not listed");
  }

  const fetchedGroup = await GroupService.getGroup("member-1", group.id);
  if (!fetchedGroup.memberIds.includes("member-1")) {
    throw new Error("Member was not added");
  }

  const updatedGroup = await GroupService.updateGroup("owner-1", group.id, {
    name: "Updated integration group",
    description: "Updated shared group test",
  });
  if (updatedGroup.name !== "Updated integration group") {
    throw new Error("Group was not updated");
  }

  await GroupService.deleteGroup("owner-1", group.id);
  console.log("Group sharing integration test passed");
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});