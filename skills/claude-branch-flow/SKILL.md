---
name: claude-branch-flow
description: >-
  Use this whenever you are about to modify files in a git repository — writing
  code, editing config, refactoring, fixing bugs, or any change to tracked
  files. Enforces a safe flow: never edit on the default branch; do all work on
  a dedicated `claude` branch, commit there, deploy/run locally for the user to
  verify, and only merge into the main branch after the user explicitly
  confirms. Triggers on phrases like "make this change", "fix", "add", "build",
  "implement", "update", "refactor" inside a git repo.
metadata:
  author: shubham
  version: "1.0.0"
---

# Claude Branch Flow

A guardrail for changes: **the main branch only ever receives changes the user
has seen running and explicitly approved.** All of Claude's work happens on a
separate `claude` branch first, is deployed locally for verification, and is
merged to main only on confirmation.

## When this applies

Apply this flow for **any task that modifies tracked files** in a git
repository — features, fixes, refactors, config edits, content changes.

**Skip it** for: read-only work (answering questions, searching, reviewing),
changes outside a git repo, or when the user explicitly says to work directly on
the current branch ("just commit to main", "don't branch this"). Honor an
explicit override.

## The flow

### 1. Set up the working branch (before the first edit)

- Confirm you're in a git repo: `git rev-parse --is-inside-work-tree`. If not,
  tell the user and stop (or offer `git init`) — don't silently edit.
- Identify the default branch (usually `main`):
  `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` —
  fall back to `main`, then `master`.
- **Never make edits while checked out on the default branch.** Move to the
  `claude` branch first:
  - If the working tree is dirty, deal with it before switching (commit the
    relevant changes, or ask the user) — don't lose work.
  - Starting fresh work and `main` is the base of truth: create or reset the
    `claude` branch from the latest default branch:
    ```bash
    git checkout main && git pull --ff-only    # if a remote exists
    git checkout -B claude                      # create/reset claude from main
    ```
  - Continuing an in-progress, not-yet-merged task: just
    `git checkout claude` and keep going. Do **not** reset it — that would
    discard unmerged work.
- For parallel/unrelated tasks you may use `claude/<short-task-slug>` instead of
  a single `claude` branch; the rest of the flow is identical.

### 2. Do the work on the branch

- Make all edits on the `claude` branch.
- Commit in logical chunks with clear messages. End every commit message with:
  ```
  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  ```
- Keep `main` untouched the entire time.

### 3. Deploy / run locally for verification

- Start the project locally so the user can actually see the change — prefer a
  project-specific run command or the `run` skill; otherwise use the obvious
  default for the stack (e.g. a static site: `python3 -m http.server`, a Node
  app: its `dev` script, etc.). Run long-lived servers in the background.
- Tell the user **exactly how to verify**: the local URL, what changed, and what
  to look at. If you can capture a screenshot or run the tests, do so and report
  the result.
- Then **stop and explicitly ask for confirmation.** Do not proceed to merge on
  assumption. Wait for a clear approval ("looks good", "yes", "ship it",
  "confirmed").

### 4. On confirmation → merge to main

- Merge the `claude` branch into the default branch locally:
  ```bash
  git checkout main
  git merge --no-ff claude -m "Merge claude: <summary>"
  ```
  (`--no-ff` keeps a visible record of what was reviewed together.)
- **Pushing is a separate, explicit step.** Pushing `main` may trigger a
  production deploy (e.g. Cloudflare/Vercel Git builds), so **ask before
  pushing** unless the user has already said to push. Per the harness rule, only
  commit/push when the user asks.
- After a successful merge, you may reset `claude` onto the updated main for the
  next task (`git checkout -B claude main`) or delete it — keep the repo tidy.

### 5. On rejection → iterate, don't pollute main

- If the user isn't happy, **stay on the `claude` branch and iterate.** `main`
  never received the change, so there's nothing to roll back there.
- If the task is abandoned, discard the branch (`git checkout main &&
  git branch -D claude`) — main is already clean.

## Invariants (the point of this skill)

1. The default branch is **never edited directly** by Claude.
2. Every change is **deployed locally and seen by the user** before merge.
3. Merge to main happens **only after explicit user confirmation.**
4. **Pushing** the merged main is its own confirmed step (it may deploy to prod).

## Notes

- This is a model-invoked convention. For a hard, unbypassable guarantee on
  every edit, pair it with a `PreToolUse`/`PostToolUse` hook in `settings.json`
  that blocks edits on the default branch.
- If a previous run left an unmerged `claude` branch, surface that to the user
  before starting unrelated work rather than resetting over it.
