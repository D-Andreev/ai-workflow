# State Schema

File: `.cursor/workflows/state.json`

Machine-readable schema: [state.schema.json](state.schema.json)  
Example at pipeline start: [../../fixtures/state-example-start.json](../../fixtures/state-example-start.json)

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string \| null | Pipeline run id, e.g. `notification-retry-2026-06-13` |
| `mode` | string | `feature` (implement phase) or `bugfix` (bugfix phase). Set at start |
| `task` | string \| null | Short task summary |
| `phase` | string \| null | Current phase (see below) |
| `status` | string | `idle`, `ai_running`, `awaiting_human`, `done`, `cancelled` |
| `base_branch` | string | Git branch for `git diff` / `git diff --stat` (set at start; see **Base branch**) |
| `requirements_approved` | boolean | Must be true before build phase |
| `clarify_rounds` | number | Clarify Q&A rounds completed (default 0; max 3 — see **Clarify limits**) |
| `created_at` | ISO string \| null | Pipeline start time |
| `updated_at` | ISO string \| null | Last state change |
| `history` | array | `{ phase, event, at, note? }` |
| `human_feedback` | array | `{ phase, text, at }` |
| `comprehension_attempt` | number | Test attempts (default 0) |
| `comprehension_passed` | boolean | true after passing grade (default false) |
| `comprehension_skipped` | boolean | true if human used `skip-comprehension` (default false) |
| `quiz_mode` | string | `standard` (8–10 questions) or `light` (4–5 questions); set at comprehension entry |
| `artifacts` | object | Paths to handoff files — **populate on start; do not rename keys** |

### `artifacts` keys (required on start)

| Key | Path |
|-----|------|
| `task` | `.cursor/workflows/artifacts/task.md` |
| `requirements` | `.cursor/workflows/artifacts/requirements.md` |
| `implement_handoff` | `.cursor/workflows/artifacts/implement-handoff.md` |
| `verify_report` | `.cursor/workflows/artifacts/verify-report.md` |
| `ai_review` | `.cursor/workflows/artifacts/ai-review.md` |
| `comprehension_test` | `.cursor/workflows/artifacts/comprehension-test.md` |
| `retro` | `.cursor/workflows/artifacts/retro.md` |

Phase skills write to the paths in `artifacts`. Orchestrators read paths from `state.artifacts`, not hard-coded strings.

## Base branch

Set `base_branch` when creating `state.json` on pipeline start:

1. If the user passed `--base <branch>`, use that.
2. Else if `git rev-parse --verify origin/main` succeeds, use `origin/main`.
3. Else if `git rev-parse --verify main` succeeds, use `main`.
4. Else use the current branch from `git branch --show-current`.

All phases that diff code use:

```bash
git diff {base_branch}...HEAD
git diff --stat {base_branch}...HEAD
```

Record the chosen branch in `history` with event `started` and `note: base_branch=...`.

## Phases

**Feature mode (`mode: feature`):**
`clarify` → `implement` → `refine` → `verify` → `ai_review` → `comprehension` → `retro` → `summarize` → `done`

**Bug-fix mode (`mode: bugfix`):**
`clarify` → `bugfix` → `refine` → `verify` → `ai_review` → `comprehension` → `retro` → `summarize` → `done`

`bugfix` replaces `implement` in the build slot and writes the same `implement-handoff.md` artifact.

`refine` is re-entered from human gates; not always sequential.

Build phase name: `implement` when `mode: feature`, `bugfix` when `mode: bugfix`.

## History events

- `started` — pipeline created
- `phase_started` — AI work began on phase
- `phase_completed` — AI work finished, artifact written (or summarize cleanup done)
- `human_approved` — human advanced
- `human_refine` — human sent refine feedback
- `human_reject` — human sent reject (verify or ai_review gate)
- `comprehension_skipped` — human skipped quiz via `skip-comprehension`
- `cancelled` — aborted or cleaned up
- `recovered` — stuck `ai_running` repaired (note explains how)

## Clarify limits

- Increment `clarify_rounds` each time the clarify skill completes a Q&A round (questions asked + answers merged).
- **Maximum 3 rounds.** After round 3, produce the best `requirements.md` possible, list remaining assumptions explicitly, and ask for `approve requirements` — do not ask more questions unless the human sends `re-clarify:`.

## Routing table (single source of truth)

Orchestrator (`dev-pipeline`) **must not duplicate** this table elsewhere. Apply rows by matching `phase`, `status: awaiting_human`, and user command.

| phase | user command | preconditions | state changes | next phase | skill |
|-------|--------------|---------------|---------------|------------|-------|
| clarify | answers only | — | merge requirements | clarify | workflow-clarify |
| clarify | `approve requirements` | requirements.md exists | `requirements_approved: true`, history `human_approved` | build | workflow-implement or workflow-bugfix |
| clarify | `re-clarify:` | — | `requirements_approved: false`, append note | clarify | workflow-clarify |
| implement | `approve` | — | history `human_approved` | verify | workflow-verify |
| implement | `refine:` | — | append feedback, history `human_refine` | refine | workflow-refine |
| bugfix | `approve` | — | history `human_approved` | verify | workflow-verify |
| bugfix | `refine:` | — | append feedback, history `human_refine` | refine | workflow-refine |
| refine | `approve` | — | history `human_approved` | verify | workflow-verify |
| refine | `refine:` | — | append feedback, history `human_refine` | refine | workflow-refine |
| verify | `approve` | — | history `human_approved` | ai_review | workflow-ai-review |
| verify | `refine:` | — | append feedback, history `human_refine` | refine | workflow-refine |
| verify | `reject:` | — | append feedback, history `human_reject` | build | workflow-implement or workflow-bugfix |
| ai_review | `approve` | — | history `human_approved` | comprehension | workflow-comprehension |
| ai_review | `refine:` | — | append feedback, history `human_refine` | refine | workflow-refine |
| ai_review | `reject:` | — | append feedback, history `human_reject` | build | workflow-implement or workflow-bugfix |
| comprehension | numbered answers | questions pending | grade via skill | comprehension | workflow-comprehension (grade) |
| comprehension | `ready` / `retake` | last attempt failed | — | comprehension | workflow-comprehension (generate) |
| comprehension | `skip-comprehension` | — | `comprehension_skipped: true`, history `comprehension_skipped` | comprehension | workflow-comprehension (shame) |
| comprehension | `approve` | `comprehension_passed: true` OR `comprehension_skipped: true` | history `human_approved` | retro | workflow-retro |
| retro | answers only | retro.md not final | merge retro | retro | workflow-retro |
| retro | `approve` | retro.md exists | history `human_approved` | summarize | workflow-summarize |
| any | `abort` | — | `status: cancelled`, `phase: done`, history `cancelled` | — | then **cleanup** (below) |
| any | `/dev-pipeline cleanup` | cancelled or done, or orphaned files | history `cancelled` if needed | — | delete ephemeral files |

**Implicit approve** (`/dev-pipeline continue` with no command): treat as `approve` only for phases **not** listed under “no auto-approve” in dev-pipeline **Continue workflow** section.

### Lifecycle transitions (non-gate)

```
idle + start           → clarify (ai_running, mode=feature, populate all fields)
idle + start-bugfix    → clarify (ai_running, mode=bugfix, populate all fields)
AI phase entered       → status ai_running, history phase_started
AI phase completed     → status awaiting_human, history phase_completed
summarize completed    → delete ephemeral files (no state file remains)
abort or cleanup       → delete ephemeral files
```

## Invalid state recovery

| Problem | Action |
|---------|--------|
| `status: ai_running` stuck | If current phase artifact looks complete → `status: awaiting_human`, history `recovered`. Else re-run phase skill. |
| Missing `artifacts` keys | Repopulate from table above; paths must match. |
| Missing `base_branch` | Infer using Base branch rules; set field. |
| `requirements_approved: true` but empty requirements.md | Reset approval; return to clarify. |
| Partial summarize (some artifacts remain) | Run `/dev-pipeline cleanup` |

## Abort and cleanup

**`abort`** and **`/dev-pipeline cleanup`** delete all ephemeral pipeline files:

- Every file under `.cursor/workflows/artifacts/`
- `.cursor/workflows/state.json`
- `.cursor/workflows/STATUS.md`

Do **not** delete `PROJECT.md` or `learnings/gotchas.md`.

After abort/cleanup, report what was deleted. Durable docs remain.

## Ephemeral files (deleted on summarize, abort, or cleanup)

- `.cursor/workflows/artifacts/*`
- `.cursor/workflows/state.json`
- `.cursor/workflows/STATUS.md`

## Durable files (persist)

- `.cursor/workflows/PROJECT.md` — project context
- `.cursor/workflows/learnings/gotchas.md` — consolidated pitfalls (rewritten each workflow)
