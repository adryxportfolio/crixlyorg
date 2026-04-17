import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn } from "node:child_process";
import * as p from "@clack/prompts";
import pc from "picocolors";
import { bootstrapCeoInvite } from "./auth-bootstrap-ceo.js";
import { onboard } from "./onboard.js";
import { doctor } from "./doctor.js";
import { loadCrixlyEnvFile } from "../config/env.js";
import { configExists, resolveConfigPath } from "../config/store.js";
import type { CrixlyConfig } from "../config/schema.js";
import { readConfig } from "../config/store.js";
import {
  describeLocalInstancePaths,
  resolveCrixlyHomeDir,
  resolveCrixlyInstanceId,
} from "../config/home.js";

interface RunOptions {
  config?: string;
  instance?: string;
  repair?: boolean;
  yes?: boolean;
}

interface StartedServer {
  apiUrl: string;
  databaseUrl: string;
  host: string;
  listenPort: number;
}

export async function runCommand(opts: RunOptions): Promise<void> {
  const instanceId = resolveCrixlyInstanceId(opts.instance);
  process.env.CRIXLY_INSTANCE_ID = instanceId;

  const homeDir = resolveCrixlyHomeDir();
  fs.mkdirSync(homeDir, { recursive: true });

  const paths = describeLocalInstancePaths(instanceId);
  fs.mkdirSync(paths.instanceRoot, { recursive: true });

  const configPath = resolveConfigPath(opts.config);
  process.env.CRIXLY_CONFIG = configPath;
  loadCrixlyEnvFile(configPath);

  p.intro(pc.bgCyan(pc.black(" crixlyai run ")));
  p.log.message(pc.dim(`Home: ${paths.homeDir}`));
  p.log.message(pc.dim(`Instance: ${paths.instanceId}`));
  p.log.message(pc.dim(`Config: ${configPath}`));

  if (!configExists(configPath)) {
    if (!process.stdin.isTTY || !process.stdout.isTTY) {
      p.log.error("No config found and terminal is non-interactive.");
      p.log.message(`Run ${pc.cyan("crixlyai onboard")} once, then retry ${pc.cyan("crixlyai run")}.`);
      process.exit(1);
    }

    p.log.step("No config found. Starting onboarding...");
    await onboard({ config: configPath, invokedByRun: true });
  }

  p.log.step("Running doctor checks...");
  const summary = await doctor({
    config: configPath,
    repair: opts.repair ?? true,
    yes: opts.yes ?? true,
  });

  if (summary.failed > 0) {
    p.log.error("Doctor found blocking issues. Not starting server.");
    process.exit(1);
  }

  const config = readConfig(configPath);
  if (!config) {
    p.log.error(`No config found at ${configPath}.`);
    process.exit(1);
  }
  sanitizeRuntimeEnvFromConfig(config);

  p.log.step("Starting Crixly server...");
  let startedServer: StartedServer | null = null;
  const useEmbeddedDatabase = config.database.mode === "embedded-postgres";

  try {
    startedServer = await importServerEntry();
  } catch (err) {
    p.log.warn(
      [
        "Direct in-process startup failed; falling back to server subprocess.",
        formatError(err),
      ].join("\n"),
    );
    await startServerSubprocess({ useEmbeddedDatabase });
    return;
  }

  if (startedServer && shouldGenerateBootstrapInviteAfterStart(config)) {
    p.log.step("Generating bootstrap CEO invite");
    await bootstrapCeoInvite({
      config: configPath,
      dbUrl: startedServer.databaseUrl,
      baseUrl: resolveBootstrapInviteBaseUrl(config, startedServer),
    });
  }
}

async function startServerSubprocess(options: { useEmbeddedDatabase: boolean }): Promise<void> {
  const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
  const isWindows = process.platform === "win32";
  const command = isWindows ? "cmd.exe" : "pnpm";
  const args = isWindows
    ? ["/c", "pnpm", "--filter", "@crixlyai/server", "start"]
    : ["--filter", "@crixlyai/server", "start"];

  await new Promise<void>((resolve, reject) => {
    const childEnv = { ...process.env };
    if (options.useEmbeddedDatabase) {
      // Force embedded mode even when .env contains DATABASE_URL defaults.
      childEnv.DATABASE_URL = "";
    }

    const child = spawn(command, args, {
      cwd: projectRoot,
      stdio: "inherit",
      env: childEnv,
      shell: false,
    });

    child.on("error", (err) => {
      reject(new Error(`Failed to launch server subprocess via ${command}: ${formatError(err)}`));
    });

    child.on("exit", (code, signal) => {
      if (signal) {
        reject(new Error(`Server subprocess exited due to signal ${signal}.`));
        return;
      }
      if ((code ?? 1) !== 0) {
        reject(new Error(`Server subprocess exited with code ${code ?? 1}.`));
        return;
      }
      resolve();
    });
  });
}

function resolveBootstrapInviteBaseUrl(
  config: CrixlyConfig,
  startedServer: StartedServer,
): string {
  const explicitBaseUrl =
    process.env.CRIXLY_PUBLIC_URL ??
    process.env.CRIXLY_AUTH_PUBLIC_BASE_URL ??
    process.env.BETTER_AUTH_URL ??
    process.env.BETTER_AUTH_BASE_URL ??
    (config.auth.baseUrlMode === "explicit" ? config.auth.publicBaseUrl : undefined);

  if (typeof explicitBaseUrl === "string" && explicitBaseUrl.trim().length > 0) {
    return explicitBaseUrl.trim().replace(/\/+$/, "");
  }

  return startedServer.apiUrl.replace(/\/api$/, "");
}

function formatError(err: unknown): string {
  if (err instanceof Error) {
    if (err.message && err.message.trim().length > 0) return err.message;
    return err.name;
  }
  if (typeof err === "string") return err;
  try {
    return JSON.stringify(err);
  } catch {
    return String(err);
  }
}

function isModuleNotFoundError(err: unknown): boolean {
  if (!(err instanceof Error)) return false;
  const code = (err as { code?: unknown }).code;
  if (code === "ERR_MODULE_NOT_FOUND") return true;
  return err.message.includes("Cannot find module");
}

function getMissingModuleSpecifier(err: unknown): string | null {
  if (!(err instanceof Error)) return null;
  const packageMatch = err.message.match(/Cannot find package '([^']+)' imported from/);
  if (packageMatch?.[1]) return packageMatch[1];
  const moduleMatch = err.message.match(/Cannot find module '([^']+)'/);
  if (moduleMatch?.[1]) return moduleMatch[1];
  return null;
}

function maybeEnableUiDevMiddleware(entrypoint: string): void {
  if (process.env.CRIXLY_UI_DEV_MIDDLEWARE !== undefined) return;
  const normalized = entrypoint.replaceAll("\\", "/");
  if (normalized.endsWith("/server/src/index.ts") || normalized.endsWith("@crixlyai/server/src/index.ts")) {
    process.env.CRIXLY_UI_DEV_MIDDLEWARE = "true";
  }
}

async function importServerEntry(): Promise<StartedServer> {
  // Dev mode: try local workspace path (monorepo with tsx)
  const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
  const devEntry = path.resolve(projectRoot, "server/src/index.ts");
  if (fs.existsSync(devEntry)) {
    maybeEnableUiDevMiddleware(devEntry);
    const mod = await import(pathToFileURL(devEntry).href);
    return await startServerFromModule(mod, devEntry);
  }

  // Production mode: import the published @crixlyai/server package
  try {
    const mod = await import("@crixlyai/server");
    return await startServerFromModule(mod, "@crixlyai/server");
  } catch (err) {
    const missingSpecifier = getMissingModuleSpecifier(err);
    const missingServerEntrypoint = !missingSpecifier || missingSpecifier === "@crixlyai/server";
    if (isModuleNotFoundError(err) && missingServerEntrypoint) {
      throw new Error(
        `Could not locate a Crixly server entrypoint.\n` +
          `Tried: ${devEntry}, @crixlyai/server\n` +
          `${formatError(err)}`,
      );
    }
    throw new Error(
      `Crixly server failed to start.\n` +
        `${formatError(err)}`,
    );
  }
}

function shouldGenerateBootstrapInviteAfterStart(config: CrixlyConfig): boolean {
  return config.server.deploymentMode === "authenticated" && config.database.mode === "embedded-postgres";
}

function sanitizeRuntimeEnvFromConfig(config: CrixlyConfig): void {
  // Honor config-selected embedded mode even when the host shell exports DATABASE_URL.
  if (config.database.mode === "embedded-postgres" && process.env.DATABASE_URL) {
    delete process.env.DATABASE_URL;
    p.log.warn("Ignoring DATABASE_URL because config uses embedded-postgres.");
  }
}

async function startServerFromModule(mod: unknown, label: string): Promise<StartedServer> {
  const startServer = (mod as { startServer?: () => Promise<StartedServer> }).startServer;
  if (typeof startServer !== "function") {
    throw new Error(`Crixly server entrypoint did not export startServer(): ${label}`);
  }
  return await startServer();
}
