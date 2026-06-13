---
name: workflow-retro
description: >-
  Retro phase of the dev pipeline. Analyzes what went well and poorly, asks the
  human reflective questions, and saves learnings. Use when dev-pipeline phase
  is retro.
disable-model-invocation: true
---

# Workflow: Retro

Reflect on the pipeline before durable docs are updated. **Gotchas and PROJECT.md are handled in the summarize phase** — retro only captures session reflection in `retro.md`.

## Inputs

- All artifacts in `.cursor/workflows/artifacts/`
- `state.json` history
- `.cursor/workflows/learnings/gotchas.md` (read for context — do not write)

## Process

1. Review the full pipeline history and artifacts.
2. Ask the human **3–5 reflective questions**, e.g.:
   - Were the clarify questions useful? What was missing?
   - Did verify catch anything you cared about?
   - What would you do differently next time?
   - What didn't go well that we should remember?
3. **Stop and wait** for answers — do not write final retro in the same turn as questions.

## On human answers

1. Write `.cursor/workflows/artifacts/retro.md`:

```markdown
# Retro: {pipeline id}

## What went well
- ...

## What didn't go well
- ...

## Human reflections
| Question | Answer |
|----------|--------|
| ... | ... |

## Gotchas for future work
- {pitfalls and surprises — summarize phase will consolidate into gotchas.md}

## Process improvements
- ...
```

2. Update state: `phase` stays `retro`, `status` → `awaiting_human`, append history `phase_completed`.
3. Ask for `approve` to run **summarize** (updates PROJECT.md/gotchas, deletes artifacts, closes pipeline).

Do **not** write to `gotchas.md` or `PROJECT.md` in this phase.

## Rules

- Focus retro.md on honest reflection — especially **what didn't go well**
- Keep gotcha candidates in retro.md; summarize phase deduplicates into gotchas.md
- Do not delete artifacts or close the pipeline — summarize handles that
