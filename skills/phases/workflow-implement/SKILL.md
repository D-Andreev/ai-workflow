---
name: workflow-implement
description: >-
  Implementation phase of the dev pipeline. Uses TDD red-green cycles to write
  failing tests first, then minimal code, per approved requirements. Use when
  dev-pipeline phase is implement.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Implement

Build the feature per approved `requirements.md`.

## Preconditions

- `state.requirements_approved` must be true
- Read `.cursor/workflows/artifacts/requirements.md`
- Read `.cursor/workflows/PROJECT.md`
- Skim `.cursor/workflows/learnings/gotchas.md` for relevant past pitfalls

## Process

1. Plan approach — match existing patterns in the codebase (use PROJECT.md source layout and nearby code as guides). If the repo has no test infrastructure, skip the TDD cycle (step 2): implement without tests and record "no test infrastructure" in the handoff's red-green table.
2. **TDD red-green cycle** — for each acceptance criterion or behavior slice (work in small steps):
   - **Red** — write a failing test that expresses the expected behavior. Run it using commands from PROJECT.md and confirm it **fails for the right reason** (missing behavior, not a typo or setup error).
   - **Green** — implement the smallest change that makes that test pass. Run it again and confirm **pass**.
   - **Refactor** (optional) — clean up while keeping tests green.
   Repeat until requirements are covered.
3. Run the full test suite using commands documented in PROJECT.md (skip if no test infrastructure):
   - Unit tests (required)
   - Lint/format checks if you touched many files or modules
   - Integration or end-to-end tests only if requirements call for that coverage
4. Fix failures before completing.
5. Write `.cursor/workflows/artifacts/implement-handoff.md` (template below).
6. Update state: `status` → `awaiting_human`, history `phase_completed`.

## implement-handoff.md template

```markdown
# Implement Handoff

## Summary
{1-2 sentences}

## Changes
| File | What changed |
|------|--------------|
| ... | ... |

## TDD red-green cycles
| Behavior / criterion | Test(s) | Red (fail reason) | Green |
|----------------------|---------|-------------------|-------|
| ... | {path} | confirmed fail | pass |

## Test results
- {command from PROJECT.md}: PASS/FAIL — {details if fail}
- Lint/format: PASS/SKIP/FAIL — {command if run}
- Other: ...

## Acceptance criteria status
- [x] or [ ] each criterion from requirements.md

## Open questions / risks
- ...

## Suggested review scenarios
1. ...
2. ...
```

## Human gate

Present the handoff summary per dev-pipeline **Human gate presentation**. Wait for `approve` or `refine: <feedback>`.

## Rules

- When the repo has test infrastructure, use TDD red-green cycles — do not implement behavior before a failing test proves it was missing.
- Do not expand scope beyond requirements.md.
- Follow project conventions from PROJECT.md and existing code (naming, patterns, tooling).
- Prefer focused diffs; no drive-by refactors.
- Use `git diff {state.base_branch}...HEAD` when summarizing changes in the handoff.
