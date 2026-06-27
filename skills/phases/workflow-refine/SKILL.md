---
name: workflow-refine
description: >-
  Refine phase of the dev pipeline. Addresses human feedback on implementation
  or tests. Use when dev-pipeline phase is refine.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Refine

Address human feedback from an implement or review gate.

## Inputs

1. `.cursor/workflows/artifacts/requirements.md`
2. `.cursor/workflows/artifacts/implement-handoff.md` (if exists)
3. `.cursor/workflows/state.json` → `human_feedback` (latest entries)
4. Latest human message if it contains `refine:` feedback
5. `.cursor/workflows/PROJECT.md`

## Process

1. Read feedback — only change what was requested.
2. Apply fixes. When behavior or tests change, use a **TDD red-green cycle**: write or adjust a failing test (red, run and confirm fail), then minimal code to pass (green, run and confirm pass).
3. Re-run relevant test and lint/format commands from PROJECT.md.
4. Update `implement-handoff.md` with a **Refinement log** section:

```markdown
## Refinement log

### {timestamp}
**Feedback:** ...
**Changes:** ...
**Tests:** PASS/FAIL
```

5. Update state: `status` → `awaiting_human`, history `phase_completed`.

## Human gate

Summarize what changed vs feedback. Wait for `approve` or `refine: <more feedback>`.

## Rules

- Do not re-litigate requirements — if feedback conflicts with requirements.md, ask the human.
- Do not start review — orchestrator handles transitions.
