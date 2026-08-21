#!/usr/bin/env bash
# Make every supported host (opencode, Claude Code, Grok) able to run Orca orchestration:
#
#   1. Install the worker + orchestrator agent pairs. Each is composed from a host header
#      (frontmatter + host-specific permission notes) plus the shared behaviour contract. The
#      contract lives in exactly one file per role, so a rule fixed once is fixed for every host —
#      the previous copy-per-host layout drifted silently.
#   2. Link this suite's skills into opencode's skills directory. `skills add` installs into the
#      universal root (~/.agents/skills) and symlinks it for Claude Code and Grok automatically,
#      but not for opencode, which reads ~/.config/opencode/skills. Without the link, an opencode
#      session has the agents but none of the /orca-* commands.
#
# Usage: skills/orca-setup/install-agents.sh [--dry-run]

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HERE/agents"
# Where `skills add` puts installed skills. Override for a non-standard install root.
SKILLS_ROOT="${ORCA_SKILLS_ROOT:-$HOME/.agents/skills}"
OPENCODE_SKILLS="$HOME/.config/opencode/skills"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

installed=()
skipped=()
linked=()
missing_skills=()
opencode_absent=0

# compose <host-header> <shared-contract> <destination>
compose() {
  local header="$1" contract="$2" dest="$3"
  local dir
  dir="$(dirname "$dest")"

  for source in "$header" "$contract"; do
    if [[ ! -f "$source" ]]; then
      echo "error: missing source file $source" >&2
      exit 1
    fi
  done

  if (( DRY_RUN )); then
    echo "would install $dest"
    return
  fi

  if ! mkdir -p "$dir" 2>/dev/null; then
    # A pre-existing agents directory owned by another account is the known failure here.
    skipped+=("$dest (cannot create $dir — check ownership)")
    return
  fi

  if ! { cat "$header"; echo; cat "$contract"; } > "$dest" 2>/dev/null; then
    skipped+=("$dest (not writable — check ownership of $dir)")
    return
  fi
  installed+=("$dest")
}

# host -> destination directory for agent definitions
host_dest() {
  case "$1" in
    opencode) echo "$HOME/.config/opencode/agents" ;;
    claude)   echo "$HOME/.claude/agents" ;;
    grok)     echo "$HOME/.grok/agents" ;;
    *)        return 1 ;;
  esac
}

for role in worker orchestrator; do
  contract="$AGENTS/_shared/${role}-contract.md"
  for host in opencode claude grok; do
    compose "$AGENTS/${host}/${role}.md" "$contract" "$(host_dest "$host")/${role}.md"
  done
done

# Link this suite's skills into opencode's skills directory.
#
# The skill names come from this repo's skills/ directory — the parent of this script — so a skill
# added or retired upstream is picked up without editing a list here. A name that is not present in
# SKILLS_ROOT is reported, not linked: it means `skills add` has not run (or ran before that skill
# existed), and a dangling symlink would be worse than an honest gap.
link_opencode_skills() {
  local suite_dir="$(dirname "$HERE")"

  # Nothing to do on a machine without opencode — do not demand skills for a host that is absent.
  if ! command -v opencode >/dev/null 2>&1 && [[ ! -d "$HOME/.config/opencode" ]]; then
    opencode_absent=1
    return
  fi

  if [[ ! -d "$SKILLS_ROOT" ]]; then
    missing_skills+=("$SKILLS_ROOT does not exist — no skills are installed yet")
    return
  fi

  for skill_path in "$suite_dir"/*/; do
    local skill="$(basename "$skill_path")"
    [[ -f "$skill_path/SKILL.md" ]] || continue

    if [[ ! -e "$SKILLS_ROOT/$skill" ]]; then
      missing_skills+=("$skill (not in $SKILLS_ROOT)")
      continue
    fi

    if (( DRY_RUN )); then
      echo "would link $OPENCODE_SKILLS/$skill"
      continue
    fi

    if ! mkdir -p "$OPENCODE_SKILLS" 2>/dev/null; then
      skipped+=("$OPENCODE_SKILLS/$skill (cannot create $OPENCODE_SKILLS)")
      return
    fi
    if ln -sfn "$SKILLS_ROOT/$skill" "$OPENCODE_SKILLS/$skill" 2>/dev/null; then
      linked+=("$OPENCODE_SKILLS/$skill")
    else
      skipped+=("$OPENCODE_SKILLS/$skill (symlink failed)")
    fi
  done
}

link_opencode_skills

# Reported in dry-run too: a preview that hides what it cannot do is worse than no preview.
report_missing_skills() {
  (( ${#missing_skills[@]} )) || return 0
  echo >&2
  echo "Skills not linked for opencode:" >&2
  for entry in "${missing_skills[@]}"; do echo "  $entry" >&2; done
  echo >&2
  echo "opencode would have the agents but none of the /orca-* commands. Install them, then" >&2
  echo "re-run this script:" >&2
  echo "  cd ~ && npx -y skills add adamelhirch/orca-skills --global --skill '*' -y" >&2
  echo >&2
  echo "(Run it from outside a project directory, or with --global: skills add auto-detects scope" >&2
  echo " and installs project-locally when run inside a repo.)" >&2
}

if (( DRY_RUN )); then
  (( opencode_absent )) && echo "opencode not found — its skill links would be skipped"
  report_missing_skills
  exit 0
fi

for path in "${installed[@]}"; do echo "installed $path"; done
for path in "${linked[@]}"; do echo "linked    $path"; done
(( opencode_absent )) && echo "skipped opencode skill links (opencode not installed on this host)"
if (( ${#skipped[@]} )); then
  echo
  echo "NOT installed:" >&2
  for entry in "${skipped[@]}"; do echo "  $entry" >&2; done
  echo >&2
  echo "Setup is incomplete: an agent pair that is half-installed will stall a run on the host" >&2
  echo "that is missing it. Fix the directory ownership and re-run before continuing." >&2
  exit 1
fi

if (( ${#missing_skills[@]} )); then
  report_missing_skills
  exit 1
fi

echo
echo "Restart any agent session that was already running: agents and skills are read at startup,"
echo "so a live session still holds the previous definitions."
