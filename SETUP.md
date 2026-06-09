# SETUP PROMPT — Reproduce my global Claude Code configuration

> **How to use this file:** On a fresh machine, after installing Claude Code,
> clone this repo, start `claude` in the repo directory, and paste the whole
> **"Prompt to paste into Claude"** section below. Claude will execute every
> step. Alternatively run `./install.sh` for the non-interactive path — the
> prompt and the script do the same thing.

This repo captures, exactly, the *global* (user-level) Claude Code setup from
the source machine: settings, the git-branch-guard hook, two personal skills,
and two installed plugins (which themselves bundle many more skills). Nothing
here is project-specific.

---

## Inventory — what "identical setup" means

After setup, `~/.claude/` must contain all of the following.

### 1. Global settings — `~/.claude/settings.json`
Vendored verbatim as [`files/settings.json`](files/settings.json) (exact copy)
and [`files/settings.template.json`](files/settings.template.json) (the
`__CLAUDE_DIR__` hook path is rewritten to this machine's `~/.claude`). Keys:

| Key | Value | Meaning |
|---|---|---|
| `permissions.allow` | 8 Bash globs (`grep`, `git checkout *`, `git add *`, `gh auth *`, `tailscale *`, `cloudflared --version`) | auto-approved commands |
| `permissions.defaultMode` | `auto` | auto-approve mode |
| `env.NODE_OPTIONS` | `--max-old-space-size=6144` | 6 GB Node heap (OOM guardrail on long sessions/big builds) |
| `autoCompactEnabled` | `true` | auto context compaction |
| `hooks.PreToolUse` | matcher `Edit\|Write\|NotebookEdit` → `block-default-branch-edits.sh` | git branch guard (see §3) |
| `enabledPlugins` | `superpowers@…`, `ui-ux-pro-max@…` | both plugins enabled |
| `extraKnownMarketplaces` | `superpowers-marketplace`, `ui-ux-pro-max-skill` | github sources |
| `skipDangerousModePermissionPrompt` | `true` | |
| `theme` | `dark-daltonized` | |
| `editorMode` | `normal` | |
| `agentPushNotifEnabled` | `true` | push notifications on agent completion |

### 2. Local settings — `~/.claude/settings.local.json`
Vendored as [`files/settings.local.json`](files/settings.local.json). Adds the
permission `Bash(claude plugin *)`.

### 3. Hook — `~/.claude/hooks/block-default-branch-edits.sh`
Vendored as [`files/hooks/block-default-branch-edits.sh`](files/hooks/block-default-branch-edits.sh).
A `PreToolUse` hook on `Edit|Write|NotebookEdit` that **denies edits when the
target file's repo is on its default branch** (`main`/`master`), enforcing the
`claude-branch-flow` skill. Escape hatch: `CLAUDE_ALLOW_MAIN_EDITS=1`. Must be
executable (`chmod +x`).

### 4. Personal skills — `~/.claude/skills/`
Vendored under [`skills/`](skills/). Copied verbatim:
- `branch-progress-journal/` — keeps a `PROGRESS.md` on `dev/*` branches.
- `claude-branch-flow/` — never edit the default branch; work on a `claude`/`dev` branch, verify, then merge.

### 5. Plugins (installed via marketplaces)
| Plugin | Marketplace | GitHub repo |
|---|---|---|
| `superpowers` | `superpowers-marketplace` | `obra/superpowers-marketplace` |
| `ui-ux-pro-max` | `ui-ux-pro-max-skill` | `nextlevelbuilder/ui-ux-pro-max-skill` |

Also register the official marketplace `anthropics/claude-plugins-official`
(known on the source machine; no plugins installed from it yet).

`superpowers` provides the `superpowers:*` skill family (brainstorming, TDD,
systematic-debugging, writing-plans, using-git-worktrees, verification, etc.).
`ui-ux-pro-max` provides the `ui-ux-pro-max` design skill.

> **Not in scope (intentionally):** auth credentials (`~/.claude/.credentials.json`),
> history, caches, sessions, project-specific memory. You authenticate once with
> `claude login`. Don't copy credentials between machines.

---

## Prompt to paste into Claude

```
You are setting up this machine to match a saved global Claude Code
configuration. The repo you are running inside contains the source of truth.
Do every step, then verify. Use $HOME/.claude as the target (call it CLAUDE_DIR).

STEP 0 — Locate. Confirm you are inside this repo (it has files/, skills/,
install.sh, SETUP.md). Set CLAUDE_DIR="$HOME/.claude". `mkdir -p
"$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills"`.

STEP 1 — Personal skills. Copy every directory under ./skills/ into
"$CLAUDE_DIR/skills/", replacing any existing copy:
    for d in ./skills/*/; do
      n=$(basename "$d"); rm -rf "$CLAUDE_DIR/skills/$n"; cp -r "$d" "$CLAUDE_DIR/skills/$n";
    done
Expect: branch-progress-journal, claude-branch-flow.

STEP 2 — Hook. Copy ./files/hooks/block-default-branch-edits.sh into
"$CLAUDE_DIR/hooks/" and `chmod +x` it.

STEP 3 — settings.json. If "$CLAUDE_DIR/settings.json" already exists, back it
up first. Then render the template, rewriting the hook path to this machine:
    sed "s#__CLAUDE_DIR__#$CLAUDE_DIR#g" ./files/settings.template.json > "$CLAUDE_DIR/settings.json"
Then copy ./files/settings.local.json to "$CLAUDE_DIR/settings.local.json".
Read back settings.json and confirm the hooks[].command path points at
"$CLAUDE_DIR/hooks/block-default-branch-edits.sh" (absolute, this machine's home).

STEP 4 — Marketplaces & plugins. Run (ignore "already added/installed"):
    claude plugin marketplace add anthropics/claude-plugins-official
    claude plugin marketplace add obra/superpowers-marketplace
    claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
    claude plugin install superpowers@superpowers-marketplace
    claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill
If the claude CLI is not on PATH, stop and tell me to install Claude Code first.

STEP 5 — Verify (show me the output of each):
  - `cat "$CLAUDE_DIR/settings.json"` matches files/settings.json except the hook
    path, which must be this machine's absolute "$CLAUDE_DIR/hooks/...".
  - `ls "$CLAUDE_DIR/skills/"` lists branch-progress-journal and claude-branch-flow.
  - `test -x "$CLAUDE_DIR/hooks/block-default-branch-edits.sh"` passes.
  - `claude plugin list` shows superpowers and ui-ux-pro-max as installed/enabled.
  - Print a final checklist of all five inventory sections (settings, local
    settings, hook, personal skills, plugins) marking each ✅ or ❌.

STEP 6 — Tell me what's left to do manually: run `claude login` to
authenticate, then restart Claude so the hook, skills, and plugins load. Do NOT
attempt to copy or fabricate credentials.
```

---

## Manual / one-line alternative

```bash
git clone git@github.com:ShuklaXD/claude_sh.git && cd claude_sh && ./install.sh
claude login      # authenticate (interactive, once)
# restart claude, then:
claude plugin list
```

## Verifying success

A correctly reproduced machine shows:

```
$ ls ~/.claude/skills
branch-progress-journal  claude-branch-flow

$ test -x ~/.claude/hooks/block-default-branch-edits.sh && echo ok
ok

$ grep -c '"command"' ~/.claude/settings.json     # the hook is wired
1

$ claude plugin list      # both plugins present & enabled
superpowers@superpowers-marketplace      ... enabled
ui-ux-pro-max@ui-ux-pro-max-skill        ... enabled
```

Open a new Claude session and run `/` — you should see the `superpowers:*`
skills and `ui-ux-pro-max` in the skill list, and editing a tracked file while
on `main`/`master` should be blocked by the branch-guard hook.
