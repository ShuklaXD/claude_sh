#!/usr/bin/env bash
# PreToolUse hook for Edit | Write | NotebookEdit.
# Denies the edit when the target file's git repo currently has its DEFAULT
# branch (main/master) checked out, enforcing the `claude-branch-flow` skill:
# Claude must do its work on a `claude` branch, never directly on main.
#
# Allows the edit when:
#   - the target isn't inside a git repo (e.g. ~/.claude config, /tmp),
#   - the current branch is anything other than the default branch, or
#   - the escape hatch CLAUDE_ALLOW_MAIN_EDITS=1 is set.
#
# Output contract: print nothing + exit 0 to allow; print a PreToolUse deny
# JSON object to block.

set -u

# --- escape hatch ----------------------------------------------------------
[ "${CLAUDE_ALLOW_MAIN_EDITS:-}" = "1" ] && exit 0

input=$(cat)

# --- extract the target file path (jq may be absent; use python3) ----------
fp=$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print((d.get("tool_input") or {}).get("file_path", "") or "")
except Exception:
    print("")
' 2>/dev/null)

if [ -n "$fp" ]; then
  dir=$(dirname "$fp")
else
  dir=$PWD
fi
[ -d "$dir" ] || dir=$PWD

# --- not a git repo? allow -------------------------------------------------
git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# --- resolve the default branch -------------------------------------------
def=$(git -C "$dir" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null \
        | sed 's@^refs/remotes/origin/@@')
if [ -z "$def" ]; then
  if git -C "$dir" rev-parse --verify --quiet refs/remotes/origin/main >/dev/null 2>&1; then
    def=main
  elif git -C "$dir" rev-parse --verify --quiet refs/remotes/origin/master >/dev/null 2>&1; then
    def=master
  else
    def=main
  fi
fi

cur=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- decide ----------------------------------------------------------------
# Protect the resolved default branch AND the conventional trunk names
# (main/master). The latter covers local-only repos with no remote and repos
# whose origin/HEAD isn't set, where $def can't be resolved reliably.
protected=0
[ -n "$cur" ] && [ "$cur" = "$def" ] && protected=1
case "$cur" in main|master) protected=1 ;; esac

if [ "$protected" = "1" ]; then
  reason="Blocked by claude-branch-flow: the repo is on its trunk branch '$cur'. Do not edit it directly. Switch to the 'claude' working branch first (e.g. \`git checkout -B claude\`), make changes there, deploy locally for the user to verify, and merge into '$cur' only after the user confirms. (Override for this session with CLAUDE_ALLOW_MAIN_EDITS=1.)"
  python3 -c '
import json, sys
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": sys.argv[1],
  }
}))
' "$reason"
fi
exit 0
