import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  listCodexSkills,
  syncCodexSkills,
} from "@crixlyai/adapter-codex-local/server";

async function makeTempDir(prefix: string): Promise<string> {
  return fs.mkdtemp(path.join(os.tmpdir(), prefix));
}

describe("codex local skill sync", () => {
  const crixlyKey = "crixlyai/crixly/crixly";
  const cleanupDirs = new Set<string>();

  afterEach(async () => {
    await Promise.all(Array.from(cleanupDirs).map((dir) => fs.rm(dir, { recursive: true, force: true })));
    cleanupDirs.clear();
  });

  it("reports configured Crixly skills for workspace injection on the next run", async () => {
    const codexHome = await makeTempDir("crixly-codex-skill-sync-");
    cleanupDirs.add(codexHome);

    const ctx = {
      agentId: "agent-1",
      companyId: "company-1",
      adapterType: "codex_local",
      config: {
        env: {
          CODEX_HOME: codexHome,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    const before = await listCodexSkills(ctx);
    expect(before.mode).toBe("ephemeral");
    expect(before.desiredSkills).toContain(crixlyKey);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.required).toBe(true);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("configured");
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.detail).toContain("CODEX_HOME/skills/");
  });

  it("does not persist Crixly skills into CODEX_HOME during sync", async () => {
    const codexHome = await makeTempDir("crixly-codex-skill-prune-");
    cleanupDirs.add(codexHome);

    const configuredCtx = {
      agentId: "agent-2",
      companyId: "company-1",
      adapterType: "codex_local",
      config: {
        env: {
          CODEX_HOME: codexHome,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    const after = await syncCodexSkills(configuredCtx, [crixlyKey]);
    expect(after.mode).toBe("ephemeral");
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("configured");
    await expect(fs.lstat(path.join(codexHome, "skills", "crixly"))).rejects.toMatchObject({
      code: "ENOENT",
    });
  });

  it("keeps required bundled Crixly skills configured even when the desired set is emptied", async () => {
    const codexHome = await makeTempDir("crixly-codex-skill-required-");
    cleanupDirs.add(codexHome);

    const configuredCtx = {
      agentId: "agent-2",
      companyId: "company-1",
      adapterType: "codex_local",
      config: {
        env: {
          CODEX_HOME: codexHome,
        },
        crixlySkillSync: {
          desiredSkills: [],
        },
      },
    } as const;

    const after = await syncCodexSkills(configuredCtx, []);
    expect(after.desiredSkills).toContain(crixlyKey);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("configured");
  });

  it("normalizes legacy flat Crixly skill refs before reporting configured state", async () => {
    const codexHome = await makeTempDir("crixly-codex-legacy-skill-sync-");
    cleanupDirs.add(codexHome);

    const snapshot = await listCodexSkills({
      agentId: "agent-3",
      companyId: "company-1",
      adapterType: "codex_local",
      config: {
        env: {
          CODEX_HOME: codexHome,
        },
        crixlySkillSync: {
          desiredSkills: ["crixly"],
        },
      },
    });

    expect(snapshot.warnings).toEqual([]);
    expect(snapshot.desiredSkills).toContain(crixlyKey);
    expect(snapshot.desiredSkills).not.toContain("crixly");
    expect(snapshot.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("configured");
    expect(snapshot.entries.find((entry) => entry.key === "crixly")).toBeUndefined();
  });
});
