#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const envPath = path.join(root, ".env");
const envExamplePath = path.join(root, ".env.example");

if (!fs.existsSync(envPath)) {
  if (fs.existsSync(envExamplePath)) {
    fs.copyFileSync(envExamplePath, envPath);
  } else {
    fs.writeFileSync(envPath, "PORT=3100\nSERVE_UI=true\n", "utf8");
  }
}

let envText = fs.readFileSync(envPath, "utf8");
const lines = envText.split(/\r?\n/);
const keys = new Set(lines.map((line) => line.split("=")[0]?.trim()).filter(Boolean));

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

