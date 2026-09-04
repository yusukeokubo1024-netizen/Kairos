process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "kairos-3d873" });

const { ScheduleService } = require("../lib/services/scheduleService");

async function run() {
  const startTime = admin.firestore.Timestamp.fromDate(
    new Date("2026-09-01T09:00:00Z")
  );
  const endTime = admin.firestore.Timestamp.fromDate(
    new Date("2026-09-01T10:00:00Z")
  );
  const schedule = await ScheduleService.createSchedule("owner-1", {
    title: "Integration test",
    startTime,
    endTime,
    participants: ["participant-1"],
  });

  if (!schedule.participantIds.includes("participant-1")) {
    throw new Error("participantIds was not saved");
  }

  const participantSchedules = await ScheduleService.listSchedules("participant-1");
  if (!participantSchedules.some((item) => item.id === schedule.id)) {
    throw new Error("Participant schedule was not returned");
  }

  const updatedSchedule = await ScheduleService.updateSchedule(
    "owner-1",
    schedule.id,
    { title: "Updated integration test" }
  );
  if (updatedSchedule.title !== "Updated integration test") {
    throw new Error("Schedule was not updated");
  }

  await ScheduleService.updateParticipantStatus(
    "participant-1",
    schedule.id,
    "accepted"
  );
  const fetchedSchedule = await ScheduleService.getSchedule(
    "participant-1",
    schedule.id
  );
  const participant = fetchedSchedule.participants.find(
    (item) => item.uid === "participant-1"
  );
  if (participant?.status !== "accepted") {
    throw new Error("Participant status was not updated");
  }

  await ScheduleService.deleteSchedule("owner-1", schedule.id);
  console.log("Schedule CRUD integration test passed");
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});