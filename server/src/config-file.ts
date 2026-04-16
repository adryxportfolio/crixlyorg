import fs from "node:fs";
import { crixlyConfigSchema, type CrixlyConfig } from "@crixlyai/shared";
import { resolveCrixlyConfigPath } from "./paths.js";

export function readConfigFile(): CrixlyConfig | null {
  const configPath = resolveCrixlyConfigPath();

  if (!fs.existsSync(configPath)) return null;

  try {
    const raw = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    return crixlyConfigSchema.parse(raw);
  } catch {
    return null;
  }
}
