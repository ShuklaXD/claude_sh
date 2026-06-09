# claude_sh

A portable snapshot of my **global Claude Code setup** — settings, hook,
personal skills, and plugins — plus a prompt + installer to reproduce it
**identically on a fresh machine**.

Run the installer, or paste the prompt in [`SETUP.md`](SETUP.md) into a `claude`
session started inside this repo. Both do the same thing.

## Quick start

```bash
git clone <this-repo-url> claude_sh
cd claude_sh
./install.sh          # copies settings/hook/skills, registers marketplaces, installs plugins
claude login          # authenticate once (interactive — not stored in this repo)
# restart claude, then confirm:
claude plugin list
```

Prefer to drive it through Claude itself? Open `claude` in this folder and paste
the **"Prompt to paste into Claude"** block from [`SETUP.md`](SETUP.md).

## What's in here

```
claude_sh/
├── README.md                     # this file
├── SETUP.md                      # full inventory + the prompt to paste into Claude
├── install.sh                    # idempotent non-interactive installer
├── files/
│   ├── settings.json             # exact copy of ~/.claude/settings.json (reference)
│   ├── settings.template.json    # same, but hook path is __CLAUDE_DIR__ (portable)
│   ├── settings.local.json       # ~/.claude/settings.local.json
│   └── hooks/
│       └── block-default-branch-edits.sh   # PreToolUse git-branch guard
└── skills/
    ├── branch-progress-journal/  # personal skill
    └── claude-branch-flow/       # personal skill
```

## What it sets up

- **Global settings** → `~/.claude/settings.json`: auto permission mode + an
  allow-list, 6 GB Node heap, auto-compact, dark-daltonized theme, normal
  editor mode, agent push notifications, both plugins enabled, marketplaces
  registered, and the branch-guard hook wired in.
- **Local settings** → `~/.claude/settings.local.json`: allows `claude plugin *`.
- **Hook** → `~/.claude/hooks/block-default-branch-edits.sh`: blocks
  `Edit`/`Write`/`NotebookEdit` when a repo is on `main`/`master`, enforcing the
  branch-flow discipline. Override per-session with `CLAUDE_ALLOW_MAIN_EDITS=1`.
- **Personal skills** → `~/.claude/skills/`: `branch-progress-journal`,
  `claude-branch-flow`.
- **Plugins** (via marketplaces): `superpowers` (obra/superpowers-marketplace)
  and `ui-ux-pro-max` (nextlevelbuilder/ui-ux-pro-max-skill); the official
  `anthropics/claude-plugins-official` marketplace is registered too.

See [`SETUP.md`](SETUP.md) for the exact, per-key inventory and verification
steps.

## Not included (by design)

Credentials, session history, caches, and project-specific memory are **not**
captured. Authenticate on each machine with `claude login`. Re-run `install.sh`
any time — it's idempotent and backs up an existing `settings.json` before
overwriting.

## Keeping this in sync

When you change your global setup, refresh the snapshot:

```bash
cp ~/.claude/settings.json        files/settings.json
cp ~/.claude/settings.local.json  files/settings.local.json
cp ~/.claude/hooks/block-default-branch-edits.sh files/hooks/
cp -r ~/.claude/skills/*          skills/
# regenerate the portable template (rewrite your home path back to the placeholder):
sed "s#$HOME/.claude/hooks/#__CLAUDE_DIR__/hooks/#" files/settings.json > files/settings.template.json
git add -A && git commit -m "sync global claude setup"
```
