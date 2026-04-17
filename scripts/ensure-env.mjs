#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const envPath = path.join(root, ".env");
const envExamplePath = path.join(root, ".env.example");
const DEFAULT_DATABASE_URL = "postgres://crixly:crixly@localhost:5432/crixly";

if (!fs.existsSync(envPath)) {
  if (fs.existsSync(envExamplePath)) {
    fs.copyFileSync(envExamplePath, envPath);
  } else {
    fs.writeFileSync(envPath, "PORT=3100\nSERVE_UI=true\n", "utf8");
  }
}

let envText = fs.readFileSync(envPath, "utf8");
const rawLines = envText.split(/\r?\n/);
const lines = rawLines.filter((line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) return true;
  const separator = line.indexOf("=");
  if (separator === -1) return true;
  const key = line.slice(0, separator).trim();
  const value = line.slice(separator + 1).trim();
  if (key === "DATABASE_URL" && value === DEFAULT_DATABASE_URL) {
    return false;
  }
  return true;
});
const keys = new Set(
  lines
    .map((line) => line.split("=")[0]?.trim())
    .filter((key) => key && !key.startsWith("#")),
);

if (!keys.has("PORT")) {
  lines.push("PORT=3100");
}
if (!keys.has("SERVE_UI")) {
  lines.push("SERVE_UI=true");
}
if (!keys.has("TELEMETRY_DISABLED")) {
  lines.push("TELEMETRY_DISABLED=true");
}

envText = `${lines.filter((line, idx, arr) => !(idx === arr.length - 1 && line === "")).join("\n")}\n`;
fs.writeFileSync(envPath, envText, "utf8");

