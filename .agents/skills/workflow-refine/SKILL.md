---
name: workflow-refine
description: >-
  Refine phase of the dev pipeline. Addresses human feedback on implementation
  or tests. Use when dev-pipeline phase is refine.
disable-model-invocation: true
---

# Workflow: Refine

Address human feedback from an implement or verify review gate.

## Inputs

1. `.cursor/workflows/artifacts/requirements.md`
2. `.cursor/workflows/artifacts/implement-handoff.md` (if exists)
3. `.cursor/workflows/state.json` → `human_feedback` (latest entries)
4. Latest human message if it contains `refine:` feedback
5. `.cursor/workflows/PROJECT.md`

## Process

1. Read feedback — only change what was requested.
2. Implement fixes.
3. Re-run `make test-unit` (and `make lint` if needed).
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
- Do not start verify or ai_review — orchestrator handles transitions.
