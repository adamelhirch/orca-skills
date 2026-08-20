#!/usr/bin/env node
// Validate the skill suite's own invariants. No dependencies — `node scripts/validate-skills.mjs`.
//
// This repo distributes prose, not code, so its defects are structural: a skill that exists on
// disk but is missing from the manifest never ships; a skill missing from the README table is
// invisible; a broken relative link silently drops a reader. Those are exactly the failures this
// checks for, so the CI-green gate the suite preaches applies to the suite itself.

import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, dirname, resolve, relative } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];
const fail = (file, message) => errors.push({ file, message });

const read = (p) => readFileSync(join(ROOT, p), "utf8");

/** Parse the top-level keys of a `---` frontmatter block. Values may be YAML folded scalars. */
function frontmatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) return null;
  const keys = {};
  let current = null;
  for (const line of match[1].split("\n")) {
    const top = line.match(/^([A-Za-z][A-Za-z0-9_-]*):\s?(.*)$/);
    if (top) {
      current = top[1];
      keys[current] = top[2].trim();
    } else if (current && line.trim()) {
      keys[current] = `${keys[current]} ${line.trim()}`.trim();
    }
  }
  return keys;
}

// --- discover the skills on disk -------------------------------------------------------------
const skillsDir = join(ROOT, "skills");
const skills = readdirSync(skillsDir)
  .filter((entry) => statSync(join(skillsDir, entry)).isDirectory())
  .sort();

if (skills.length === 0) fail("skills/", "no skill directories found");

// --- 1. every skill has well-formed frontmatter ----------------------------------------------
for (const skill of skills) {
  const path = `skills/${skill}/SKILL.md`;
  if (!existsSync(join(ROOT, path))) {
    fail(path, "missing SKILL.md");
    continue;
  }
  const keys = frontmatter(read(path));
  if (!keys) {
    fail(path, "missing or malformed `---` frontmatter block");
    continue;
  }
  if (keys.name !== skill) {
    fail(path, `frontmatter name "${keys.name ?? "(absent)"}" must equal the directory name "${skill}"`);
  }
  if (!keys.description || keys.description.replace(/^>-?\s*/, "").length < 40) {
    fail(path, "frontmatter description is absent or too short to route on");
  }
  // Every skill in this suite is orchestrator-invoked: it must never fire on its own inside a
  // worker session, which is what disable-model-invocation guarantees.
  if (keys["disable-model-invocation"] !== "true") {
    fail(path, "frontmatter must set `disable-model-invocation: true` (orchestrator-invoked only)");
  }
}

// --- 2. the manifest ships every skill --------------------------------------------------------
const manifestPath = "skills.sh.json";
let manifest;
try {
  manifest = JSON.parse(read(manifestPath));
} catch (error) {
  fail(manifestPath, `unreadable JSON: ${error.message}`);
}
if (manifest) {
  const listed = new Set((manifest.groupings ?? []).flatMap((group) => group.skills ?? []));
  for (const skill of skills) {
    if (!listed.has(skill)) fail(manifestPath, `skill "${skill}" exists on disk but is not listed in any grouping`);
  }
  for (const entry of listed) {
    if (!skills.includes(entry)) fail(manifestPath, `grouping lists "${entry}", which has no skills/${entry}/ directory`);
  }
}

// --- 3. the README documents every skill ------------------------------------------------------
const readme = read("README.md");
for (const skill of skills) {
  if (!readme.includes(`\`/${skill}\``)) {
    fail("README.md", `skill "${skill}" has no \`/${skill}\` entry in the skills table`);
  }
}

// --- 4. the agent contract stays single-sourced -----------------------------------------------
// Installed agents are composed from a host header + one shared contract per role. The failure
// this guards against is the one the layout replaced: a rule fixed in one host file and forgotten
// in the other. If a contract heading reappears in a host header, the split has started to rot.
const AGENTS = "skills/orca-setup/agents";
const CONTRACT_HEADINGS = [
  "## Mandatory lifecycle rules",
  "## TDD discipline",
  "## The merge gate",
  "## Mandatory worktree guardrail",
  "## Your lifecycle",
  "## Rules",
];

for (const role of ["worker", "orchestrator"]) {
  const contract = `${AGENTS}/_shared/${role}-contract.md`;
  if (!existsSync(join(ROOT, contract))) {
    fail(contract, `missing shared ${role} contract — installed agents would carry no behaviour rules`);
    continue;
  }
  for (const host of ["claude", "opencode"]) {
    const header = `${AGENTS}/${host}/${role}.md`;
    if (!existsSync(join(ROOT, header))) {
      fail(header, `missing ${host} host header for the ${role} agent`);
      continue;
    }
    const source = read(header);
    if (!frontmatter(source)) fail(header, "host header must open with a frontmatter block");
    for (const heading of CONTRACT_HEADINGS) {
      if (source.includes(heading)) {
        fail(header, `"${heading}" belongs in _shared/${role}-contract.md — a host header must not restate the contract`);
      }
    }
  }
}

const installer = "skills/orca-setup/install-agents.sh";
if (!existsSync(join(ROOT, installer))) {
  fail(installer, "missing agent composer — /orca-setup step 5 calls it");
} else if (!(statSync(join(ROOT, installer)).mode & 0o111)) {
  fail(installer, "agent composer is not executable");
}

// --- 5. relative links resolve ----------------------------------------------------------------
function markdownFiles(dir) {
  const found = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === ".git" || entry.name === "node_modules") continue;
    const path = join(dir, entry.name);
    if (entry.isDirectory()) found.push(...markdownFiles(path));
    else if (entry.name.endsWith(".md")) found.push(path);
  }
  return found;
}

for (const file of markdownFiles(ROOT)) {
  const source = readFileSync(file, "utf8");
  for (const [, target] of source.matchAll(/\]\(([^)\s]+)\)/g)) {
    if (/^(https?:|mailto:|#)/.test(target)) continue;
    const path = target.split("#")[0];
    if (!path) continue;
    if (!existsSync(resolve(dirname(file), decodeURIComponent(path)))) {
      fail(relative(ROOT, file), `relative link does not resolve: ${target}`);
    }
  }
}

// --- report -----------------------------------------------------------------------------------
if (errors.length) {
  console.error(`✗ ${errors.length} problem(s):\n`);
  for (const { file, message } of errors) console.error(`  ${file}: ${message}`);
  process.exit(1);
}
console.log(`✓ ${skills.length} skills valid: ${skills.join(", ")}`);
