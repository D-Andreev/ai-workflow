---
name: workflow-summarize
description: >-
  Final dev-pipeline phase after retro approval. Consolidates learnings into
  gotchas.md, updates PROJECT.md only for major features, deletes workflow
  artifacts, and closes the pipeline. Use when dev-pipeline phase is summarize.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Summarize

Terminal cleanup phase. Runs **automatically** after retro is approved — no human gate. Reads all workflow artifacts one last time, updates durable project docs, deletes ephemeral artifacts, closes the pipeline.

## Preconditions

- `state.phase` was `retro` and human approved (or continue routed here)
- `.cursor/workflows/artifacts/retro.md` exists

## Inputs

1. All files in `.cursor/workflows/artifacts/`
2. `.cursor/workflows/PROJECT.md`
3. `.cursor/workflows/learnings/gotchas.md`
4. `.cursor/workflows/state.json`

## Process

### 1. Extract learnings from this workflow

From `retro.md` and other artifacts, identify:

- **What didn't go well** — mistakes, surprises, rework (highest priority for gotchas)
- **Reusable process fixes** — only if they apply beyond this task
- **Project facts** — only if agents need to know something new about the system

Ignore task-specific trivia and things already obvious from the code.

### 2. Update PROJECT.md (major features only)

**Default: do not change PROJECT.md.** Domain language (`## Language`) is updated during **clarify**, not here.

Update **Overview** or **Main Features** only when this workflow delivered a **major** new capability or materially changed how the system works.

**Do not update** for bug fixes, small enhancements, refactors, or workflow tooling changes. **Do not rewrite `## Language`** — clarify owns the glossary.

If warranted: one short bullet in the relevant section; keep PROJECT.md concise.

### 3. Consolidate gotchas.md (rewrite, not append)

**Replace** `.cursor/workflows/learnings/gotchas.md` with a consolidated summary.

Rules:

- **Not a per-run log** — one consolidated list of reusable pitfalls
- Merge new learnings from this retro with existing gotchas
- **Deduplicate** — same lesson stated once
- **Prioritize pitfalls** over successes
- Keep ≤**20** bullets total
- Group by theme

Remove empty sections. If nothing worth keeping: `No outstanding gotchas yet.`

### 4. Delete workflow artifacts

Delete **all** files in `.cursor/workflows/artifacts/`.

Do **not** delete `PROJECT.md` or `gotchas.md`.

### 5. Delete workflow state files

Delete `.cursor/workflows/state.json` and `.cursor/workflows/STATUS.md`.

### 6. Present completion summary

Tell the human:

1. Pipeline closed
2. Whether PROJECT.md changed
3. Gotchas themes updated (bullet list)
4. Deleted: artifacts, `state.json`, `STATUS.md`
5. Start next: `/dev-pipeline start "<task>"`

**Stop.** No further approve needed.

## Rules

- **Never** modify application source code in this phase
- **Never** append to gotchas.md — always rewrite consolidated
- **Never** leave artifact files, `state.json`, or `STATUS.md` after this phase completes
- If deletion fails partially, list remaining files and suggest `/dev-pipeline cleanup`
