#!/usr/bin/env bash
# Install the Orca worker + orchestrator agent pairs for every supported host (opencode, Claude
# Code, Grok).
#
# Each installed agent is composed: a host header (frontmatter + host-specific permission notes)
# followed by the shared behaviour contract. The contract lives in exactly one file per role, so
# a rule fixed once is fixed for every host — the previous copy-per-host layout drifted silently.
#
# Usage: skills/orca-setup/install-agents.sh [--dry-run]

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HERE/agents"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

installed=()
skipped=()

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

(( DRY_RUN )) && exit 0

for path in "${installed[@]}"; do echo "installed $path"; done
if (( ${#skipped[@]} )); then
  echo
  echo "NOT installed:" >&2
  for entry in "${skipped[@]}"; do echo "  $entry" >&2; done
  echo >&2
  echo "Setup is incomplete: an agent pair that is half-installed will stall a run on the host" >&2
  echo "that is missing it. Fix the directory ownership and re-run before continuing." >&2
  exit 1
fi

echo
echo "If a target agents directory did not exist when the agent session started, restart that"
echo "agent once so the definitions are picked up."
