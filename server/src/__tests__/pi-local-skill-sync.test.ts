import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  listPiSkills,
  syncPiSkills,
} from "@crixlyai/adapter-pi-local/server";

async function makeTempDir(prefix: string): Promise<string> {
  return fs.mkdtemp(path.join(os.tmpdir(), prefix));
}

describe("pi local skill sync", () => {
  const crixlyKey = "crixlyai/crixly/crixly";
  const cleanupDirs = new Set<string>();

  afterEach(async () => {
    await Promise.all(Array.from(cleanupDirs).map((dir) => fs.rm(dir, { recursive: true, force: true })));
    cleanupDirs.clear();
  });

  it("reports configured Crixly skills and installs them into the Pi skills home", async () => {
    const home = await makeTempDir("crixly-pi-skill-sync-");
    cleanupDirs.add(home);

    const ctx = {
      agentId: "agent-1",
      companyId: "company-1",
      adapterType: "pi_local",
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    const before = await listPiSkills(ctx);
    expect(before.mode).toBe("persistent");
    expect(before.desiredSkills).toContain(crixlyKey);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.required).toBe(true);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("missing");

    const after = await syncPiSkills(ctx, [crixlyKey]);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".pi", "agent", "skills", "crixly"))).isSymbolicLink()).toBe(true);
  });

  it("keeps required bundled Crixly skills installed even when the desired set is emptied", async () => {
    const home = await makeTempDir("crixly-pi-skill-prune-");
    cleanupDirs.add(home);

    const configuredCtx = {
      agentId: "agent-2",
      companyId: "company-1",
      adapterType: "pi_local",
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    await syncPiSkills(configuredCtx, [crixlyKey]);

    const clearedCtx = {
      ...configuredCtx,
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [],
        },
      },
    } as const;

    const after = await syncPiSkills(clearedCtx, []);
    expect(after.desiredSkills).toContain(crixlyKey);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".pi", "agent", "skills", "crixly"))).isSymbolicLink()).toBe(true);
  });
});
