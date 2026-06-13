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

1. Plan approach — match existing patterns in the codebase (use PROJECT.md source layout and nearby code as guides).
2. Implement the smallest correct change.
3. Run tests using commands documented in PROJECT.md:
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

## Test results
- {command from PROJECT.md}: PASS/FAIL — {details if fail}
- Lint/format: PASS/SKIP/FAIL — {command if run}
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
- Follow project conventions from PROJECT.md and existing code (naming, patterns, tooling).
- Prefer focused diffs; no drive-by refactors.
