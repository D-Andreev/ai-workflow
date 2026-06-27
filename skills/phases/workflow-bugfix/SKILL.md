---
name: workflow-bugfix
description: >-
  Bug-fix phase of the dev pipeline (bugfix mode). Reproduces the defect, finds
  root cause, and fixes it with a TDD red-green regression test. Use when
  dev-pipeline phase is bugfix.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Bug Fix

Diagnose and fix the defect per approved `requirements.md`. Replaces the **implement** phase when the pipeline runs in `bugfix` mode.

## Preconditions

- `state.mode` is `bugfix`
- `state.requirements_approved` must be true
- Read `.cursor/workflows/artifacts/requirements.md`
- Read `.cursor/workflows/PROJECT.md`
- Skim `.cursor/workflows/learnings/gotchas.md` for related past defects
- Use `git diff {state.base_branch}...HEAD` when documenting changes

## Process

1. **Reproduce** — confirm the bug with a failing test or clear repro steps. If you cannot reproduce, stop and report what's needed before fixing.
2. **Root cause** — trace to the actual cause, not the symptom. Note where the defect was introduced if discoverable.
3. **TDD red-green cycle** for the regression:
   - **Red** — add or adjust a test that fails because of the bug. Run it using commands from PROJECT.md and confirm it **fails for the right reason** (the defect, not a typo or setup error).
   - **Green** — apply the smallest change that addresses the root cause and makes the test pass. Run it again and confirm **pass**. No drive-by refactors.
4. **Run tests** using commands from PROJECT.md:
   - Unit tests (required)
   - Lint/format checks if you touched many files or modules
   - Integration or end-to-end tests only if the defect needs that coverage
5. Fix failures before completing.
6. Write `.cursor/workflows/artifacts/implement-handoff.md` (template below — same artifact path the rest of the pipeline reads).
7. Update state: `status` → `awaiting_human`, history `phase_completed`.

## implement-handoff.md template (bugfix)

```markdown
# Bug Fix Handoff

## Summary
{1-2 sentences: what was broken and the fix}

## Reproduction
- Steps / failing test that demonstrated the bug

## Root cause
{what actually caused the defect; where it was introduced if known}

## Fix
{the minimal change and why it resolves the root cause}

## Changes
| File | What changed |
|------|--------------|
| ... | ... |

## TDD red-green cycle
- **Red:** {path} — {why it failed before the fix}
- **Green:** same test passes after minimal fix

## Test results
- {command from PROJECT.md}: PASS/FAIL — {details if fail}
- Lint/format: PASS/SKIP/FAIL — {command if run}
- Other: ...

## Acceptance criteria status
- [x] or [ ] each criterion from requirements.md

## Open questions / risks
- ... (e.g. other call sites with the same bug)

## Suggested review scenarios
1. The original repro no longer fails
2. Related edge cases / no regressions in ...
```

## Human gate

Present the handoff summary and **name the next step (review)**. Then offer both options:

- **Approve here:** reply `approve`, or
- **Open a new agent and run `/dev-pipeline continue`** — approve is assumed and review is triggered automatically.

Use `refine: <feedback>` to iterate on the fix instead.

## Rules

- Fix the root cause, not just the symptom.
- Always complete a TDD red-green cycle: run the regression test red (fail on the bug), fix, then run green (pass).
- Do not expand scope beyond the defect described in requirements.md.
- Prefer focused diffs; no drive-by refactors.
- Follow project conventions.
