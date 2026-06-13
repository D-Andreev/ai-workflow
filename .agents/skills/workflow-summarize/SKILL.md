---
name: workflow-summarize
description: >-
  Final dev-pipeline phase after retro approval. Consolidates learnings into
  gotchas.md, updates PROJECT.md only for major features, deletes workflow
  artifacts, and closes the pipeline. Use when dev-pipeline phase is summarize.
disable-model-invocation: true
---

# Workflow: Summarize

Terminal cleanup phase. Runs **automatically** after retro is approved — no human gate. Reads all workflow artifacts one last time, updates durable project docs, deletes ephemeral artifacts, closes the pipeline.

## Preconditions

- `state.phase` was `retro` and human approved (or continue routed here)
- `.cursor/workflows/artifacts/retro.md` exists

## Inputs

1. All files in `.cursor/workflows/artifacts/` (especially `retro.md`, `requirements.md`, `implement-handoff.md`)
2. `.cursor/workflows/PROJECT.md`
3. `.cursor/workflows/learnings/gotchas.md`
4. `.cursor/workflows/state.json`

## Process

### 1. Extract learnings from this workflow

From `retro.md` and other artifacts, identify:

- **What didn't go well** — mistakes, surprises, rework (highest priority for gotchas)
- **Reusable process fixes** — only if they apply beyond this task
- **Project facts** — only if agents need to know something new about the system

Ignore task-specific trivia, one-off decisions, and things already obvious from the code.

### 2. Update PROJECT.md (major features only)

**Default: do not change PROJECT.md.**

Update only when this workflow delivered a **major** new capability or materially changed how the system works (new user-facing feature, new batch job, new service boundary, new data model pattern).

**Do not update** for:

- Bug fixes, validation tweaks, refactors
- Small enhancements to existing features
- Internal-only changes
- Test or workflow tooling changes

If an update is warranted:

- Edit the relevant section (`Main Features`, `Pipeline`, etc.) — **one short bullet or sentence**
- Keep total PROJECT.md under ~50 lines; do not bloat
- Match existing tone and structure

If no major feature: skip PROJECT.md entirely.

### 3. Consolidate gotchas.md (rewrite, not append)

**Replace** the entire contents of `.cursor/workflows/learnings/gotchas.md` with a consolidated summary.

Rules:

- **Not a per-workflow log** — no `{pipeline-id} — {date}` sections
- Merge new learnings from this retro with existing gotchas
- **Deduplicate** — same lesson stated once
- **Prioritize what didn't go well** — pitfalls and surprises over "what went well"
- Drop stale, resolved, or overly specific items
- Keep the whole file **short** — aim for ≤15 bullets total across all sections
- Group by theme, not by date

Template:

```markdown
# Gotchas & Learnings

Curated pitfalls from dev pipelines. Consolidated after each workflow — not a per-run log.

## {Theme, e.g. Requirements & clarify}
- ...

## {Theme, e.g. Data & API contracts}
- ...
```

Remove empty sections. If nothing worth keeping, leave a minimal file with the header and one line: `No outstanding gotchas yet.`

### 4. Delete workflow artifacts

Delete **all** files in `.cursor/workflows/artifacts/`:

- `task.md`
- `requirements.md`
- `implement-handoff.md`
- `verify-report.md`
- `ai-review.md`
- `comprehension-test.md`
- `retro.md`

Do **not** delete `PROJECT.md` or `gotchas.md`.

### 5. Delete workflow state files

Delete these workflow-specific files (they belong to the finished run only):

- `.cursor/workflows/state.json`
- `.cursor/workflows/STATUS.md`

There is **no idle state file** between pipelines. The next `/dev-pipeline start` recreates both.

### 6. Present completion summary

Tell the human:

1. Pipeline closed
2. Whether PROJECT.md changed (and what, if so)
3. Gotchas themes updated (bullet list, not full file dump)
4. Deleted: all artifacts, `state.json`, `STATUS.md`
5. Start next pipeline: `/dev-pipeline start "<task>"`

**Stop.** No further approve needed.

## Rules

- **Never** modify application source code in this phase
- **Never** append to gotchas.md — always rewrite consolidated
- **Never** leave artifact files, `state.json`, or `STATUS.md` after this phase completes
- PROJECT.md changes must be minimal and rare
- If deletion fails partially, list remaining files and still report pipeline closed
