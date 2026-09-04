process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "kairos-3d873" });

const { TaskService } = require("../lib/services/taskService");

async function run() {
  const dueDate = admin.firestore.Timestamp.fromDate(
    new Date("2026-09-02T09:00:00Z")
  );
  const task = await TaskService.createTask("owner-1", {
    title: "Integration task",
    dueDate,
    priority: "high",
    tags: ["work"],
  });

  const incompleteTasks = await TaskService.listTasks("owner-1", false);
  if (!incompleteTasks.some((item) => item.id === task.id)) {
    throw new Error("Created task was not listed as incomplete");
  }

  const updatedTask = await TaskService.updateTask("owner-1", task.id, {
    completed: true,
    title: "Updated integration task",
  });
  if (!updatedTask.completed || updatedTask.title !== "Updated integration task") {
    throw new Error("Task was not updated");
  }

  const completedTasks = await TaskService.listTasks("owner-1", true);
  if (!completedTasks.some((item) => item.id === task.id)) {
    throw new Error("Updated task was not listed as completed");
  }

  const fetchedTask = await TaskService.getTask("owner-1", task.id);
  if (fetchedTask.id !== task.id) {
    throw new Error("Task was not retrieved");
  }

  await TaskService.deleteTask("owner-1", task.id);
  console.log("Task CRUD integration test passed");
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});