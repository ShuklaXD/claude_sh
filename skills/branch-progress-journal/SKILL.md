---
name: branch-progress-journal
description: >-
  Use when doing multi-step development work on a `dev/*` branch in a git repo —
  implementing a feature, fixing a bug, or any task that spans several commits
  or could be paused and resumed later. Keeps a `PROGRESS.md` at the repo root
  so a future session (or teammate) can pick up cleanly from any point. Triggers
  alongside ongoing dev-branch work, especially before committing or ending a
  session. Complements claude-branch-flow.
metadata:
  author: shubham
  version: "1.0.0"
---

# Branch Progress Journal

Keep a single **`PROGRESS.md` at the repo root** on every `dev/*` branch so work
can be **resumed cleanly from any point**. The journal is temporary scratch that
lives only on the dev branch; `main` keeps only a short final summary.

## When this applies

Apply on any `dev/*` branch doing work that spans **multiple commits or
sessions** — features, multi-step fixes, refactors, migrations.

**Skip it** for: read-only work (questions, search, review), trivial one-commit
changes that ship in the same session, or work outside a git repo. If the user
says not to bother, honor that.

This pairs with `claude-branch-flow`: that skill keeps work off `main`; this one
keeps the work *resumable* while it lives on the dev branch.

## The core rule

**Before you commit, and before you end a session, `PROGRESS.md` must reflect
reality.** Anyone reading it cold should know: what we're building, what's done,
what's verified, and exactly what to do next.

## PROGRESS.md structure

```markdown
# <branch-name> — <one-line goal>

## Goal
What this branch delivers and why. The definition of done.

## Plan
- [x] Step that's complete
- [ ] Step still pending
- [ ] ...

## Work done
### <commit sha or "uncommitted"> — <short summary>
- What changed, in which files, and any decisions made.
### <earlier commit> — ...

## Current state
What works and is verified right now (tests/build/manual checks). Be honest
about what's NOT yet verified.

## Next steps
The very next concrete actions to resume — file paths, commands, the failing
test to make pass. Specific enough to start without re-deriving context.

## Open questions / blockers
Decisions awaiting the user, unknowns, or external blockers.
```

## Lifecycle

1. **Task start** — create or refresh `PROGRESS.md` with Goal + Plan before
   writing code.
2. **As you work** — tick off Plan items; append to **Work done** when you
   commit (record what that commit did); keep **Next steps** pointing at the
   true resume point.
3. **Before ending a session or committing** — sync Current state + Next steps
   so a cold start is possible.
4. **Before raising the PR / merge** — collapse `PROGRESS.md` into a short
   **final summary** (what shipped + final state) and **delete the verbose
   plan / work-log / next-steps scratch**. Only the clean final state reaches
   `main`. (See `claude-branch-flow` for the merge handoff itself.)

## Quick reference

| Moment | Update |
|---|---|
| Start task | Goal + Plan |
| Each commit | Append Work done entry; tick Plan |
| Before stopping | Current state + Next steps must be accurate |
| Before PR | Collapse to final summary; delete scratch |

## Common mistakes

- **Stale Next steps** — the #1 failure. If it doesn't say what to do next, the
  journal is useless. Update it last, every time.
- **Claiming done without verification** — Current state must distinguish
  *verified* from *written but untested*.
- **Letting scratch reach main** — trim before the PR, not after merge.
- **Vague entries** — "fixed stuff" helps no one; name files and decisions.
