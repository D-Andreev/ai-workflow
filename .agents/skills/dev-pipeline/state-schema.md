# State Schema

File: `.cursor/workflows/state.json`

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string \| null | Pipeline run id, e.g. `notification-retry-2026-06-13` |
| `mode` | string | `feature` (uses implement phase) or `bugfix` (uses bugfix phase). Set at start; default `feature` |
| `task` | string \| null | Short task summary |
| `phase` | string \| null | Current phase (see below) |
| `status` | string | `idle`, `ai_running`, `awaiting_human`, `done`, `cancelled` |
| `requirements_approved` | boolean | Must be true before implement |
| `created_at` | ISO string \| null | Pipeline start time |
| `updated_at` | ISO string \| null | Last state change |
| `history` | array | `{ phase, event, at, note? }` |
| `human_feedback` | array | `{ phase, text, at }` |
| `comprehension_attempt` | number | Test attempts in comprehension phase (optional, default 0) |
| `comprehension_passed` | boolean | Must be true before retro (optional, default false) |
| `artifacts` | object | Paths to handoff files (do not rename keys) |

## Phases

**Feature mode (`mode: feature`):**
`clarify` → `implement` → `refine` → `verify` → `ai_review` → `comprehension` → `retro` → `summarize` → `done`

**Bug-fix mode (`mode: bugfix`):**
`clarify` → `bugfix` → `refine` → `verify` → `ai_review` → `comprehension` → `retro` → `summarize` → `done`

`bugfix` is the build phase for bug-fix pipelines — it replaces `implement` but occupies the same position and writes the same `implement-handoff.md` artifact.

`refine` is re-entered from human gates; not always sequential.

## History events

- `started` — pipeline created
- `phase_started` — AI work began on phase
- `phase_completed` — AI work finished, artifact written (or summarize cleanup done)
- `human_approved` — human advanced
- `human_refine` — human sent refine feedback
- `human_reject` — human sent reject
- `cancelled` — aborted

## Transitions (orchestrator only)

Build phase = `implement` when `mode: feature`, `bugfix` when `mode: bugfix`.

```
idle + start           → clarify (ai_running, mode=feature)
idle + start-bugfix    → clarify (ai_running, mode=bugfix)
clarify complete       → awaiting_human
approve requirements   → build phase (requirements_approved=true)
build complete         → awaiting_human
approve (build)        → verify
refine: (build)          → refine
refine complete        → awaiting_human
approve (refine)       → verify
verify complete        → awaiting_human
approve (verify)       → ai_review
reject (verify)        → build phase
ai_review complete     → awaiting_human
approve (ai_review)    → comprehension (ai_running)
comprehension fail     → awaiting_human (review + retake with new questions)
comprehension pass     → awaiting_human (approve → retro)
approve (comprehension, passed) → retro
retro complete         → awaiting_human
approve (retro)        → summarize (ai_running)
summarize complete     → delete artifacts, state.json, STATUS.md (no active pipeline)
abort                  → cancelled (keeps state files until summarize or manual cleanup)
```

## Ephemeral files (deleted on summarize)

- `.cursor/workflows/artifacts/*`
- `.cursor/workflows/state.json`
- `.cursor/workflows/STATUS.md`

## Durable files (persist)

- `PROJECT.md` and `learnings/gotchas.md` persist; gotchas is rewritten (consolidated), not appended
