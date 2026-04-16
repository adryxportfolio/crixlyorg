import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  describeLocalInstancePaths,
  expandHomePrefix,
  resolveCrixlyHomeDir,
  resolveCrixlyInstanceId,
} from "../config/home.js";

const ORIGINAL_ENV = { ...process.env };

describe("home path resolution", () => {
  afterEach(() => {
    process.env = { ...ORIGINAL_ENV };
  });

  it("defaults to ~/.crixly and default instance", () => {
    delete process.env.CRIXLY_HOME;
    delete process.env.CRIXLY_INSTANCE_ID;

    const paths = describeLocalInstancePaths();
    expect(paths.homeDir).toBe(path.resolve(os.homedir(), ".crixly"));
    expect(paths.instanceId).toBe("default");
    expect(paths.configPath).toBe(path.resolve(os.homedir(), ".crixly", "instances", "default", "config.json"));
  });

  it("supports CRIXLY_HOME and explicit instance ids", () => {
    process.env.CRIXLY_HOME = "~/crixly-home";

    const home = resolveCrixlyHomeDir();
    expect(home).toBe(path.resolve(os.homedir(), "crixly-home"));
    expect(resolveCrixlyInstanceId("dev_1")).toBe("dev_1");
  });

  it("rejects invalid instance ids", () => {
    expect(() => resolveCrixlyInstanceId("bad/id")).toThrow(/Invalid instance id/);
  });

  it("expands ~ prefixes", () => {
    expect(expandHomePrefix("~")).toBe(os.homedir());
    expect(expandHomePrefix("~/x/y")).toBe(path.resolve(os.homedir(), "x/y"));
  });
});
