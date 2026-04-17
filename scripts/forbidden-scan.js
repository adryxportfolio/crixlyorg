#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const SCAN_ROOTS = [
  "src",
  "server",
  "ui",
  "packages",
  "cli",
  "scripts",
  "docs",
  "doc",
  "dist",
  "build",
  ".next",
  "out",
  "logs",
  ".turbo",
  ".cache",
  "README.md",
  "package.json",
];
const SKIP_DIRS = new Set(["node_modules", ".git", ".pnpm-store", ".idea", ".vscode"]);
const SKIP_EXTS = new Set([".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".pdf", ".zip", ".gz"]);

function fromCodes(codes) {
  return String.fromCharCode(...codes);
}

const FORBIDDEN = [
  fromCodes([112, 97, 112, 101, 114, 99, 108, 105, 112]),
  fromCodes([112, 97, 112, 101, 114, 99, 108, 105, 112, 97, 105]),
  `${fromCodes([112, 97, 112, 101, 114, 99, 108, 105, 112])} ai`,
];

function containsForbidden(text) {
  const lower = text.toLowerCase();
  return FORBIDDEN.find((token) => lower.includes(token));
}

function listFiles(entryPath, acc) {
  if (!fs.existsSync(entryPath)) return;
  const stat = fs.statSync(entryPath);
  if (stat.isFile()) {
    acc.push(entryPath);
    return;
  }
  for (const dirent of fs.readdirSync(entryPath, { withFileTypes: true })) {
    if (dirent.isDirectory() && SKIP_DIRS.has(dirent.name)) continue;
    listFiles(path.join(entryPath, dirent.name), acc);
  }
}

function decodeMaybeBase64(token) {
  try {
    const decoded = Buffer.from(token, "base64").toString("utf8");
    if (!decoded || decoded.includes("\uFFFD")) return "";
    return decoded;
  } catch {
    return "";
  }
}

function decodeMaybeHex(token) {
  try {
    const decoded = Buffer.from(token, "hex").toString("utf8");
    if (!decoded || decoded.includes("\uFFFD")) return "";
    return decoded;
  } catch {
    return "";
  }
}

function scanFile(filePath, findings) {
  const ext = path.extname(filePath).toLowerCase();
  if (SKIP_EXTS.has(ext)) return;

  let text = "";
  try {
    text = fs.readFileSync(filePath, "utf8");
  } catch {
    return;
  }

  const direct = containsForbidden(text);
  if (direct) {
    findings.push({ filePath, kind: "direct", token: direct });
  }

  const base64Matches = text.match(/\b[A-Za-z0-9+/]{16,}={0,2}\b/g) || [];
  for (const token of base64Matches) {
    const decoded = decodeMaybeBase64(token);
    const hit = decoded && containsForbidden(decoded);
    if (hit) {
      findings.push({ filePath, kind: "base64", token: hit });
      break;
    }
  }

  const hexMatches = text.match(/\b(?:[0-9a-fA-F]{2}){8,}\b/g) || [];
  for (const token of hexMatches) {
    const decoded = decodeMaybeHex(token);
    const hit = decoded && containsForbidden(decoded);
    if (hit) {
      findings.push({ filePath, kind: "hex", token: hit });
      break;
    }
  }
}

const files = [];
for (const rel of SCAN_ROOTS) {
  listFiles(path.join(ROOT, rel), files);
}

const findings = [];
for (const filePath of files) {
  scanFile(filePath, findings);
}

if (findings.length > 0) {
  console.error("Forbidden branding scan failed.");
  for (const finding of findings) {
    console.error(`- ${path.relative(ROOT, finding.filePath)} [${finding.kind}]`);
  }
  process.exit(1);
}

console.log("Forbidden branding scan passed.");
