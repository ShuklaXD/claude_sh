#!/usr/bin/env bash
#
# install.sh — Reproduce the global Claude Code setup captured in this repo
# onto a fresh machine. Idempotent: safe to re-run.
#
# What it does:
#   1. Installs personal skills into ~/.claude/skills/
#   2. Installs the PreToolUse git-branch-guard hook into ~/.claude/hooks/
#   3. Writes ~/.claude/settings.json (merged from settings.template.json,
#      with the hook path rewritten to this machine's home) and
#      ~/.claude/settings.local.json
#   4. Registers plugin marketplaces and installs the plugins
#
# It DOES NOT touch credentials — you still run `claude login` (or `claude`)
# once to authenticate.
#
# Usage:
#   ./install.sh            # do everything
#   CLAUDE_DIR=~/.claude ./install.sh   # override target dir
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$1"; }

mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills"

# ---------------------------------------------------------------------------
# 1. Personal skills
# ---------------------------------------------------------------------------
say "Installing personal skills -> $CLAUDE_DIR/skills/"
for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "$CLAUDE_DIR/skills/$name"
  cp -r "$skill" "$CLAUDE_DIR/skills/$name"
  echo "   - $name"
done

# ---------------------------------------------------------------------------
# 2. Hook script
# ---------------------------------------------------------------------------
say "Installing hooks -> $CLAUDE_DIR/hooks/"
cp "$REPO_DIR/files/hooks/block-default-branch-edits.sh" "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/block-default-branch-edits.sh"
echo "   - block-default-branch-edits.sh"

# ---------------------------------------------------------------------------
# 3. settings.json + settings.local.json
# ---------------------------------------------------------------------------
say "Writing settings.json (hook path -> $CLAUDE_DIR)"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$(date +%s 2>/dev/null || echo prev)" 2>/dev/null \
    && echo "   (backed up existing settings.json)" || true
fi
sed "s#__CLAUDE_DIR__#$CLAUDE_DIR#g" "$REPO_DIR/files/settings.template.json" > "$CLAUDE_DIR/settings.json"
cp "$REPO_DIR/files/settings.local.json" "$CLAUDE_DIR/settings.local.json"
echo "   - settings.json"
echo "   - settings.local.json"

# ---------------------------------------------------------------------------
# 4. Plugin marketplaces + plugins
# ---------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
  say "Registering marketplaces & installing plugins via the claude CLI"
  # marketplace add is idempotent; ignore 'already added' errors
  claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
  claude plugin marketplace add obra/superpowers-marketplace        2>/dev/null || true
  claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill 2>/dev/null || true

  claude plugin install superpowers@superpowers-marketplace --yes 2>/dev/null \
    || claude plugin install superpowers@superpowers-marketplace 2>/dev/null || warn "install superpowers manually"
  claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill --yes 2>/dev/null \
    || claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill 2>/dev/null || warn "install ui-ux-pro-max manually"
else
  warn "claude CLI not found on PATH. Install Claude Code first, then run:"
  warn "  claude plugin marketplace add obra/superpowers-marketplace"
  warn "  claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill"
  warn "  claude plugin install superpowers@superpowers-marketplace"
  warn "  claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill"
fi

say "Done. Start a new Claude session and verify with:  claude plugin list"
