#!/usr/bin/env bash
# Make every supported host (opencode, Claude Code, Grok, Hermes) able to run Orca orchestration:
#
#   1. Install the worker + orchestrator agent pairs. Each is composed from a host header
#      (frontmatter + host-specific permission notes) plus the shared behaviour contract. The
#      contract lives in exactly one file per role, so a rule fixed once is fixed for every host —
#      the previous copy-per-host layout drifted silently.
#   2. Link this suite's skills into the hosts whose skills directory is NOT the universal root.
#      `skills add` installs into the universal root (~/.agents/skills) and symlinks it for Claude
#      Code and Grok automatically, but opencode reads ~/.config/opencode/skills and Hermes reads
#      ~/.hermes/skills. Without the link, such a host has the agents but none of the /orca-*
#      commands.
#
# Usage: skills/orca-setup/install-agents.sh [--dry-run]

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HERE/agents"
# Where `skills add` puts installed skills. Override for a non-standard install root.
SKILLS_ROOT="${ORCA_SKILLS_ROOT:-$HOME/.agents/skills}"
OPENCODE_SKILLS="$HOME/.config/opencode/skills"
HERMES_SKILLS="$HOME/.hermes/skills"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

installed=()
skipped=()
linked=()
missing_skills=()
absent_hosts=()

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
    # Hermes has no per-session agent directory: the pair installs as the skills
    # orca-worker / orca-orchestrator, selected at launch with `hermes --skills <name>`.
    hermes)   echo "$HERMES_SKILLS" ;;
    *)        return 1 ;;
  esac
}

# host role -> destination file. Hermes addresses a profile by skill name, so each role lands in
# its own skill directory with a SKILL.md; every other host keeps one flat file per role.
agent_file() {
  local host="$1" role="$2"
  case "$host" in
    hermes) echo "$(host_dest "$host")/orca-${role}/SKILL.md" ;;
    *)      echo "$(host_dest "$host")/${role}.md" ;;
  esac
}

for role in worker orchestrator; do
  contract="$AGENTS/_shared/${role}-contract.md"
  for host in opencode claude grok hermes; do
    compose "$AGENTS/${host}/${role}.md" "$contract" "$(agent_file "$host" "$role")"
  done
done

# Compose the pair onto Hermes profiles' SOUL.md (permanent identity slot).
#
# Only profiles in the suite's `orca-` namespace are touched — never a user's personal profile.
# A profile named orca-worker/orca-orchestrator IS the role: its SOUL.md carries the same
# header + shared contract composition as the installed skills, so the rules hold no matter how
# the session was launched (`orca-worker chat`, `hermes -p orca-worker …`, `--skills`, TUI).
compose_hermes_profiles() {
  local profiles_dir="$HOME/.hermes/profiles"
  # SOUL.md is an identity file, not a skill: strip the header's frontmatter block (--- … ---).
  body_of() { awk 'NR==1&&/^---[[:space:]]*$/{fm=1;next} fm&&/^---[[:space:]]*$/{fm=0;next} fm{next} {print}' "$1"; }
  for role in worker orchestrator; do
    local profile="orca-${role}"
    local dir="$profiles_dir/$profile"
    if [[ ! -d "$dir" ]]; then
      # Create the profile when the machine has hermes and it does not exist yet. The wrapper
      # (~/.local/bin/<profile>) makes the role launchable as a plain command.
      if (( DRY_RUN )); then
        echo "would create hermes profile $profile (--clone, wrapper alias)"
        continue
      fi
      if ! command -v hermes >/dev/null 2>&1; then
        skipped+=("hermes profile $profile (hermes CLI not found)")
        continue
      fi
      if ! hermes profile create "$profile" --clone >/dev/null 2>&1 \
        && ! hermes profile list 2>/dev/null | grep -q "^$profile"; then
        skipped+=("hermes profile $profile (creation failed — run 'hermes profile create $profile --clone' by hand)")
        continue
      fi
      # The role runs unattended: kill approval prompts at the profile level (the --yolo
      # equivalent, shipped in the profile's own config).
      hermes -p "$profile" config set approvals.mode off >/dev/null 2>&1 || true
    fi
    local dest="$dir/SOUL.md"
    if (( DRY_RUN )); then
      echo "would compose $dest"
      continue
    fi
    if ! { body_of "$AGENTS/hermes/${role}.md"; echo; cat "$AGENTS/_shared/${role}-contract.md"; } > "$dest" 2>/dev/null; then
      skipped+=("$dest (not writable — check ownership of $dir)")
      continue
    fi
    installed+=("$dest")
  done
}

compose_hermes_profiles

# Link this suite's skills into a host whose skills directory is not wired to SKILLS_ROOT.
#
# The skill names come from this repo's skills/ directory — the parent of this script — so a skill
# added or retired upstream is picked up without editing a list here. A name that is not present in
# SKILLS_ROOT is reported, not linked: it means `skills add` has not run (or ran before that skill
# existed), and a dangling symlink would be worse than an honest gap.
link_host_skills() {
  local link_dir="$1" host="$2"
  local suite_dir
  suite_dir="$(dirname "$HERE")"

  # Nothing to do on a machine without the host — do not demand skills for an absent runtime.
  case "$host" in
    opencode)
      if ! command -v opencode >/dev/null 2>&1 && [[ ! -d "$HOME/.config/opencode" ]]; then
        absent_hosts+=("$host")
        return
      fi
      ;;
    hermes)
      if ! command -v hermes >/dev/null 2>&1 && [[ ! -d "$HOME/.hermes" ]]; then
        absent_hosts+=("$host")
        return
      fi
      ;;
  esac

  if [[ ! -d "$SKILLS_ROOT" ]]; then
    missing_skills+=("$SKILLS_ROOT does not exist — no skills are installed yet (needed by $host)")
    return
  fi

  for skill_path in "$suite_dir"/*/; do
    local skill
    skill="$(basename "$skill_path")"
    [[ -f "$skill_path/SKILL.md" ]] || continue

    if [[ ! -e "$SKILLS_ROOT/$skill" ]]; then
      missing_skills+=("$skill (not in $SKILLS_ROOT — needed by $host)")
      continue
    fi

    if (( DRY_RUN )); then
      echo "would link $link_dir/$skill"
      continue
    fi

    if ! mkdir -p "$link_dir" 2>/dev/null; then
      skipped+=("$link_dir/$skill (cannot create $link_dir)")
      return
    fi
    if ln -sfn "$SKILLS_ROOT/$skill" "$link_dir/$skill" 2>/dev/null; then
      linked+=("$link_dir/$skill")
    else
      skipped+=("$link_dir/$skill (symlink failed)")
    fi
  done
}

link_host_skills "$OPENCODE_SKILLS" opencode
link_host_skills "$HERMES_SKILLS" hermes

# Reported in dry-run too: a preview that hides what it cannot do is worse than no preview.
report_missing_skills() {
  (( ${#missing_skills[@]} )) || return 0
  echo >&2
  echo "Skills not linked for the hosts that need explicit links:" >&2
  for entry in "${missing_skills[@]}"; do echo "  $entry" >&2; done
  echo >&2
  echo "Those hosts would have the agents but none of the /orca-* commands. Install them, then" >&2
  echo "re-run this script:" >&2
  echo "  cd ~ && npx -y skills add adamelhirch/orca-skills --global --skill '*' -y" >&2
  echo >&2
  echo "(Run it from outside a project directory, or with --global: skills add auto-detects scope" >&2
  echo " and installs project-locally when run inside a repo.)" >&2
}

if (( DRY_RUN )); then
  (( ${#absent_hosts[@]} )) && echo "skill links would be skipped (no ${absent_hosts[*]} install found)"
  report_missing_skills
  exit 0
fi

for path in "${installed[@]}"; do echo "installed $path"; done
for path in "${linked[@]}"; do echo "linked    $path"; done
if (( ${#absent_hosts[@]} )); then
  echo "skipped skill links for ${absent_hosts[*]} (host not installed on this machine)"
fi
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
