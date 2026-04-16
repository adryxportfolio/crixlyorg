import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  listOpenCodeSkills,
  syncOpenCodeSkills,
} from "@crixlyai/adapter-opencode-local/server";

async function makeTempDir(prefix: string): Promise<string> {
  return fs.mkdtemp(path.join(os.tmpdir(), prefix));
}

describe("opencode local skill sync", () => {
  const crixlyKey = "crixlyai/crixly/crixly";
  const cleanupDirs = new Set<string>();

  afterEach(async () => {
    await Promise.all(Array.from(cleanupDirs).map((dir) => fs.rm(dir, { recursive: true, force: true })));
    cleanupDirs.clear();
  });

  it("reports configured Crixly skills and installs them into the shared Claude/OpenCode skills home", async () => {
    const home = await makeTempDir("crixly-opencode-skill-sync-");
    cleanupDirs.add(home);

    const ctx = {
      agentId: "agent-1",
      companyId: "company-1",
      adapterType: "opencode_local",
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    const before = await listOpenCodeSkills(ctx);
    expect(before.mode).toBe("persistent");
    expect(before.warnings).toContain("OpenCode currently uses the shared Claude skills home (~/.claude/skills).");
    expect(before.desiredSkills).toContain(crixlyKey);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.required).toBe(true);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("missing");

    const after = await syncOpenCodeSkills(ctx, [crixlyKey]);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".claude", "skills", "crixly"))).isSymbolicLink()).toBe(true);
  });

  it("keeps required bundled Crixly skills installed even when the desired set is emptied", async () => {
    const home = await makeTempDir("crixly-opencode-skill-prune-");
    cleanupDirs.add(home);

    const configuredCtx = {
      agentId: "agent-2",
      companyId: "company-1",
      adapterType: "opencode_local",
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    await syncOpenCodeSkills(configuredCtx, [crixlyKey]);

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

    const after = await syncOpenCodeSkills(clearedCtx, []);
    expect(after.desiredSkills).toContain(crixlyKey);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".claude", "skills", "crixly"))).isSymbolicLink()).toBe(true);
  });
});
