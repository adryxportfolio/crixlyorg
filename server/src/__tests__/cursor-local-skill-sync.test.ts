import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  listCursorSkills,
  syncCursorSkills,
} from "@crixlyai/adapter-cursor-local/server";

async function makeTempDir(prefix: string): Promise<string> {
  return fs.mkdtemp(path.join(os.tmpdir(), prefix));
}

async function createSkillDir(root: string, name: string) {
  const skillDir = path.join(root, name);
  await fs.mkdir(skillDir, { recursive: true });
  await fs.writeFile(path.join(skillDir, "SKILL.md"), `---\nname: ${name}\n---\n`, "utf8");
  return skillDir;
}

describe("cursor local skill sync", () => {
  const crixlyKey = "crixlyai/crixly/crixly";
  const cleanupDirs = new Set<string>();

  afterEach(async () => {
    await Promise.all(Array.from(cleanupDirs).map((dir) => fs.rm(dir, { recursive: true, force: true })));
    cleanupDirs.clear();
  });

  it("reports configured Crixly skills and installs them into the Cursor skills home", async () => {
    const home = await makeTempDir("crixly-cursor-skill-sync-");
    cleanupDirs.add(home);

    const ctx = {
      agentId: "agent-1",
      companyId: "company-1",
      adapterType: "cursor",
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    const before = await listCursorSkills(ctx);
    expect(before.mode).toBe("persistent");
    expect(before.desiredSkills).toContain(crixlyKey);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.required).toBe(true);
    expect(before.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("missing");

    const after = await syncCursorSkills(ctx, [crixlyKey]);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".cursor", "skills", "crixly"))).isSymbolicLink()).toBe(true);
  });

  it("recognizes company-library runtime skills supplied outside the bundled Crixly directory", async () => {
    const home = await makeTempDir("crixly-cursor-runtime-skills-home-");
    const runtimeSkills = await makeTempDir("crixly-cursor-runtime-skills-src-");
    cleanupDirs.add(home);
    cleanupDirs.add(runtimeSkills);

    const crixlyDir = await createSkillDir(runtimeSkills, "crixly");
    const asciiHeartDir = await createSkillDir(runtimeSkills, "ascii-heart");

    const ctx = {
      agentId: "agent-3",
      companyId: "company-1",
      adapterType: "cursor",
      config: {
        env: {
          HOME: home,
        },
        crixlyRuntimeSkills: [
          {
            key: "crixly",
            runtimeName: "crixly",
            source: crixlyDir,
            required: true,
            requiredReason: "Bundled Crixly skills are always available for local adapters.",
          },
          {
            key: "ascii-heart",
            runtimeName: "ascii-heart",
            source: asciiHeartDir,
          },
        ],
        crixlySkillSync: {
          desiredSkills: ["ascii-heart"],
        },
      },
    } as const;

    const before = await listCursorSkills(ctx);
    expect(before.warnings).toEqual([]);
    expect(before.desiredSkills).toEqual(["crixly", "ascii-heart"]);
    expect(before.entries.find((entry) => entry.key === "ascii-heart")?.state).toBe("missing");

    const after = await syncCursorSkills(ctx, ["ascii-heart"]);
    expect(after.warnings).toEqual([]);
    expect(after.entries.find((entry) => entry.key === "ascii-heart")?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".cursor", "skills", "ascii-heart"))).isSymbolicLink()).toBe(true);
  });

  it("keeps required bundled Crixly skills installed even when the desired set is emptied", async () => {
    const home = await makeTempDir("crixly-cursor-skill-prune-");
    cleanupDirs.add(home);

    const configuredCtx = {
      agentId: "agent-2",
      companyId: "company-1",
      adapterType: "cursor",
      config: {
        env: {
          HOME: home,
        },
        crixlySkillSync: {
          desiredSkills: [crixlyKey],
        },
      },
    } as const;

    await syncCursorSkills(configuredCtx, [crixlyKey]);

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

    const after = await syncCursorSkills(clearedCtx, []);
    expect(after.desiredSkills).toContain(crixlyKey);
    expect(after.entries.find((entry) => entry.key === crixlyKey)?.state).toBe("installed");
    expect((await fs.lstat(path.join(home, ".cursor", "skills", "crixly"))).isSymbolicLink()).toBe(true);
  });
});
