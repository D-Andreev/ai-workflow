---
name: workflow-bugfix
description: >-
  Bug-fix phase of the dev pipeline (bugfix mode). Reproduces the defect, finds
  root cause, applies the minimal fix, and adds a regression test. Use when
  dev-pipeline phase is bugfix.
disable-model-invocation: true
---

# Workflow: Bug Fix

Diagnose and fix the defect per approved `requirements.md`. Replaces the **implement** phase when the pipeline runs in `bugfix` mode.

## Preconditions

- `state.mode` is `bugfix`
- `state.requirements_approved` must be true
- Read `.cursor/workflows/artifacts/requirements.md`
- Read `.cursor/workflows/PROJECT.md`
- Skim `.cursor/workflows/learnings/gotchas.md` for related past defects

## Process

1. **Reproduce** — confirm the bug with a failing test or clear repro steps. If you cannot reproduce, stop and report what's needed before fixing.
2. **Root cause** — trace to the actual cause, not the symptom. Note where the defect was introduced if discoverable.
3. **Regression test first** — add/adjust a test that fails because of the bug (red).
4. **Minimal fix** — apply the smallest change that addresses the root cause and makes the test pass (green). No drive-by refactors.
5. **Run tests:**
   - `make test-unit` (required)
   - `make lint` if you touched multiple packages
   - `make test-e2e` only if the defect needs integration coverage
6. Fix failures before completing.
7. Write `.cursor/workflows/artifacts/implement-handoff.md` (template below — same artifact path the rest of the pipeline reads).
8. Update state: `status` → `awaiting_human`, history `phase_completed`.

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

## Regression test
- Test added/updated: {path} — fails before fix, passes after

## Test results
- `make test-unit`: PASS/FAIL — {details if fail}
- `make lint`: PASS/SKIP/FAIL
- Other: ...

## Acceptance criteria status
- [x] or [ ] each criterion from requirements.md

## Open questions / risks
- ... (e.g. other call sites with the same bug)

## Suggested verify scenarios
1. The original repro no longer fails
2. Related edge cases / no regressions in ...
```

## Human gate

Present the handoff summary and **name the next step (verify)**. Then offer both options:

- **Approve here:** reply `approve`, or
- **Open a new agent and run `continue workflow`** — approve is assumed and verify is triggered automatically.

Use `refine: <feedback>` to iterate on the fix instead.

## Rules

- Fix the root cause, not just the symptom.
- Always land a regression test that fails before the fix and passes after.
- Do not expand scope beyond the defect described in requirements.md.
- Prefer focused diffs; no drive-by refactors.
- Follow project conventions.
