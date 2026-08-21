import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { dirname, join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath } from "node:url";

const composeFile = join(dirname(fileURLToPath(import.meta.url)), "searxng", "compose.yml");

/**
 * Checks whether the Docker engine accepts commands.
 *
 * @param pi Pi extension API used to execute Docker.
 * @returns Whether the Docker engine is ready.
 * @sideEffects Starts a short-lived Docker CLI process.
 */
async function isDockerRunning(pi: ExtensionAPI): Promise<boolean> {
  const result = await pi.exec("docker", ["info"], { timeout: 10_000 });
  return result.code === 0;
}

/**
 * Starts Docker Desktop on Windows and waits for its engine to become ready.
 *
 * @param pi Pi extension API used to execute Docker Desktop commands.
 * @returns Whether the Docker engine became ready before the timeout.
 * @sideEffects May start Docker Desktop and waits for up to 120 seconds.
 */
async function startWindowsDockerDesktop(pi: ExtensionAPI): Promise<boolean> {
  if (process.platform !== "win32") {
    return false;
  }

  const start = await pi.exec("docker", ["desktop", "start"], { timeout: 120_000 });
  if (start.code !== 0) {
    return false;
  }

  // Docker Desktop can return before its Linux engine is ready to run containers.
  for (let attempt = 0; attempt < 60; attempt += 1) {
    if (await isDockerRunning(pi)) {
      return true;
    }
    await delay(2_000);
  }

  return false;
}

/**
 * Ensures the SearXNG Compose services from the extension's searxng directory are running.
 *
 * @param pi Pi extension API used to execute Docker Compose.
 * @param ctx Active session context providing the UI.
 * @returns Whether the SearXNG Compose services were started successfully.
 * @sideEffects May start Docker Desktop, create or start containers, and display a warning.
 */
async function ensureSearxngRunning(pi: ExtensionAPI, ctx: ExtensionContext): Promise<boolean> {
  try {
    if (!(await isDockerRunning(pi)) && !(await startWindowsDockerDesktop(pi))) {
      if (ctx.hasUI) {
        const message = process.platform === "win32"
          ? "Docker Desktop or its engine could not be started."
          : "The Docker engine is not running.";
        ctx.ui.notify(`Could not start local SearXNG: ${message}`, "warning");
      }
      return false;
    }

    const composeStart = await pi.exec(
      "docker",
      ["compose", "-f", composeFile, "up", "-d"],
      { timeout: 60_000 },
    );

    if (composeStart.code !== 0) {
      if (ctx.hasUI) {
        const reason = composeStart.stderr.trim() || composeStart.stdout.trim() || "Docker Compose failed.";
        ctx.ui.notify(`Could not start local SearXNG: ${reason}`, "warning");
      }
      return false;
    }

    return true;
  } catch (error) {
    if (ctx.hasUI) {
      const reason = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Could not start local SearXNG: ${reason}`, "warning");
    }
    return false;
  }
}

/**
 * Registers lazy startup of the local SearXNG Compose stack.
 *
 * @param pi Pi extension API used to register the tool hook.
 * @returns Nothing.
 * @sideEffects Registers a tool-call handler.
 */
export default function startSearxngExtension(pi: ExtensionAPI): void {
  let startup: Promise<boolean> | undefined;

  /**
   * Starts SearXNG before the first web search and shares startup across concurrent calls.
   *
   * @param event Tool-call event containing the requested tool name.
   * @param ctx Active Pi context providing the UI.
   * @returns A promise that resolves when startup finishes or immediately for other tools.
   * @sideEffects May start Docker Desktop and the Docker Compose services in the searxng directory.
   */
  async function handleToolCall(
    event: { toolName: string },
    ctx: ExtensionContext,
  ): Promise<void> {
    if (event.toolName !== "web_search") {
      return;
    }

    startup ??= ensureSearxngRunning(pi, ctx);
    const started = await startup;

    // A failed attempt is cleared so a later search can retry after Docker is fixed.
    if (!started) {
      startup = undefined;
    }
  }

  pi.on("tool_call", handleToolCall);
}
