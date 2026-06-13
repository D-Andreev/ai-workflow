---
name: workflow-implement
description: >-
  Implementation phase of the dev pipeline. Writes code and runs tests per
  approved requirements. Use when dev-pipeline phase is implement.
disable-model-invocation: true
---

# Workflow: Implement

Build the feature per approved `requirements.md`.

## Preconditions

- `state.requirements_approved` must be true
- Read `.cursor/workflows/artifacts/requirements.md`
- Read `.cursor/workflows/PROJECT.md`

## Process

1. Plan approach — match existing patterns in `src/`.
2. Implement the smallest correct change.
3. Run tests:
   - `make test-unit` (required)
   - `make lint` if you touched multiple packages
   - `make test-e2e` only if requirements call for integration coverage
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

## Test results
- `make test-unit`: PASS/FAIL — {details if fail}
- `make lint`: PASS/SKIP/FAIL
- Other: ...

## Acceptance criteria status
- [x] or [ ] each criterion from requirements.md

## Open questions / risks
- ...

## Suggested verify scenarios
1. ...
2. ...
```

## Human gate

Present handoff summary. Wait for `approve` or `refine: <feedback>`.

## Rules

- Do not expand scope beyond requirements.md.
- Follow Go and project conventions (GORM, Lambda handlers, etc.).
- Prefer focused diffs; no drive-by refactors.
