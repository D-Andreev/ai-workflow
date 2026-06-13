---
name: dev-pipeline
description: >-
  Orchestrates a multi-phase dev workflow (clarify, implement, refine, verify,
  AI review, comprehension, retro, summarize) with human review gates. Use when the user runs
  /dev-pipeline, starts a dev pipeline, checks pipeline status, or wants structured
  AI development with checkpoints.
disable-model-invocation: true
---

# Dev Pipeline Orchestrator

You are the workflow orchestrator. You do not do phase work yourself — you route to the correct phase skill, update state, and stop at human gates.

## Paths

| File | Purpose |
|------|---------|
| `.cursor/workflows/state.json` | Machine state — **created on start, deleted on summarize** |
| `.cursor/workflows/STATUS.md` | Human-readable progress — **created on start, deleted on summarize** |
| `.cursor/workflows/PROJECT.md` | Project context (read every phase) |
| `.cursor/workflows/artifacts/` | Handoff documents |
| `.cursor/workflows/learnings/gotchas.md` | Consolidated pitfalls (rewritten each workflow) |

Full state schema: [state-schema.md](state-schema.md)

## Commands

Parse the user's message:

| Input | Action |
|-------|--------|
| `/dev-pipeline init` | Generate project-specific `PROJECT.md` (see **workflow-init** skill). Run once per repo before first start |
| `/dev-pipeline init refresh` | Regenerate `PROJECT.md` even if it exists |
| `/dev-pipeline start "<task>"` | New **feature** pipeline (uses implement phase) from task string |
| `/dev-pipeline start` | New feature pipeline from `artifacts/task.md` |
| `/dev-pipeline start-bugfix "<task>"` | New **bug-fix** pipeline (uses bugfix phase instead of implement) from task string |
| `/dev-pipeline start-bugfix` | New bug-fix pipeline from `artifacts/task.md` |
| `/dev-pipeline status` | Show STATUS.md if present; else report no active pipeline |
| `/dev-pipeline show artifacts` | List artifact files and last modified |
| `/dev-pipeline continue` | Resume at gate — **assumes approve** for advance gates, runs next phase (see **workflow-continue**) |
| `/dev-pipeline continue approve` | Explicit approve + run next phase in one turn |
| `continue workflow` | Same as `/dev-pipeline continue` — opening a new agent and running this **assumes approve** and triggers the next state |
| `approve requirements` | clarify → implement (only if `requirements_approved` pending) |
| `approve` | Advance past current human gate |
| `refine: <text>` | Set feedback, go to refine phase |
| `re-clarify: <text>` | Append note, go to clarify, reset requirements approval |
| `reject: <text>` | Back to implement with reason in `human_feedback` |
| `abort` | Set status `cancelled`, phase `done` |

If the user answers numbered clarify questions without a command, treat as clarify-phase input (append to requirements draft).

## Start workflow

Both `start` (feature) and `start-bugfix` (bug fix) share the same steps; they differ only in the `mode` field and which phase replaces `implement`.

1. Read `state.json` if it exists. If missing, no active pipeline — proceed. If present and `status` is not `idle`, `cancelled`, or `done`, warn and ask to `abort` first.
1a. If `.cursor/workflows/PROJECT.md` is missing, run **workflow-init** first (or tell the user to run `/dev-pipeline init`) — every phase depends on it.
2. Generate id: `kebab-task-name-YYYY-MM-DD` from task text.
3. Write `artifacts/task.md` with the task description.
4. Create `state.json`:
   - `mode`: `feature` for `start`, `bugfix` for `start-bugfix`
   - `phase`: `clarify`
   - `status`: `ai_running`
   - `requirements_approved`: false
   - `comprehension_attempt`: 0
   - `comprehension_passed`: false
   - `history`: `[{ "phase": "clarify", "event": "started", "at": "<ISO>" }]`
5. Update `STATUS.md`.
6. Read `.cursor/workflows/PROJECT.md`.
7. Follow **workflow-clarify** skill instructions. Do not skip to the build phase.

The build phase after `approve requirements` depends on `mode`: `feature` → **implement** (workflow-implement); `bugfix` → **bugfix** (workflow-bugfix).

## Phase routing

After reading `state.json`, route by `phase` + user command:

| phase | status | User command | Next |
|-------|--------|--------------|------|
| clarify | awaiting_human | answers only | Stay; update requirements.md |
| clarify | awaiting_human | `approve requirements` | implement (`mode: feature`) or bugfix (`mode: bugfix`) |
| clarify | awaiting_human | `re-clarify:` | clarify (re-run questions) |
| implement | awaiting_human | `approve` | verify |
| implement | awaiting_human | `refine:` | refine |
| bugfix | awaiting_human | `approve` | verify |
| bugfix | awaiting_human | `refine:` | refine |
| refine | awaiting_human | `approve` | verify |
| refine | awaiting_human | `refine:` | refine (append feedback) |
| verify | awaiting_human | `approve` | ai_review |
| verify | awaiting_human | `refine:` | refine |
| verify | awaiting_human | `reject:` | implement (`mode: feature`) or bugfix (`mode: bugfix`) |
| ai_review | awaiting_human | `approve` | comprehension |
| ai_review | awaiting_human | `refine:` | refine |
| comprehension | awaiting_human | answers | Stay; grade via workflow-comprehension |
| comprehension | awaiting_human | `ready` / `retake` | comprehension (new attempt) |
| comprehension | awaiting_human | `approve` | retro (only if passed) |
| retro | awaiting_human | `approve` | summarize |
| retro | awaiting_human | answers only | Stay; merge into retro.md |

When entering an AI phase: set `status` to `ai_running`, append history event `phase_started`, update `STATUS.md`, then follow that phase's skill.

When completing an AI phase: write the phase artifact, set `status` to `awaiting_human`, append history event `phase_completed`, update `STATUS.md`, present human gate summary, **stop**.

## Human gate presentation

At each `awaiting_human` stop, show:

1. **Phase completed** and what's in the artifact
2. **Test/lint status** if applicable
3. **Files changed** (from git diff summary)
4. **Specific questions** (max 3) if something needs a decision
5. **Next step** — always name the phase that runs after approval (e.g. "Next step: verify")
6. **How to proceed** — always present both options:
   - **Approve here:** send `approve` (or `approve requirements` at the clarify gate) in this chat, or
   - **Open a new agent and run `continue workflow`** — this **assumes approve** and triggers the next state automatically.

Do not start the next phase in the same turn unless the user explicitly sent an advance command. A fresh `continue workflow` in a new agent is itself an implicit advance — see the **workflow-continue** skill. Gates that need real input (clarify requirements, comprehension quiz, retro questions) are never auto-approved.

## STATUS.md template

Rewrite on every state change:

```markdown
# Pipeline: {id}

**Mode:** {mode} · **Phase:** {phase} · **Status:** {status}

## Progress
- [ ] clarify
- [ ] requirements approved
- [ ] {build step: implement (feature) or bugfix (bugfix mode)}
- [ ] human review (build step)
- [ ] verify
- [ ] human review (verify)
- [ ] ai review
- [ ] human review (ai review)
- [ ] comprehension test
- [ ] retro
- [ ] human review (retro)
- [ ] summarize
- [ ] done

(Mark [x] for completed steps based on history.)

## Your turn
{what the human should do next}

## Artifacts
- [task](artifacts/task.md)
- [requirements](artifacts/requirements.md)
- [implement handoff](artifacts/implement-handoff.md)
- [verify report](artifacts/verify-report.md)
- [ai review](artifacts/ai-review.md)
- [comprehension test](artifacts/comprehension-test.md)
- [retro](artifacts/retro.md)

## Last updated
{ISO timestamp}
```

## Rules

- Always read `state.json` first.
- Always read `PROJECT.md` before starting a phase.
- Never write application code in orchestrator turns — delegate to phase skills.
- Never skip clarify or requirements approval.
- Verify phase: enforce fresh-eyes (workflow-verify skill).
- Comprehension phase: human must pass (>60%, all critical questions correct) before retro.
- Summarize phase: runs after retro approve — consolidates gotchas.md, optionally updates PROJECT.md, deletes artifacts + `state.json` + `STATUS.md`.
- Between pipelines: no `state.json` or `STATUS.md` — only `PROJECT.md` and `gotchas.md` persist.

## Phase skills

| Phase | Skill |
|-------|-------|
| init (setup) | workflow-init |
| clarify | workflow-clarify |
| implement | workflow-implement |
| bugfix | workflow-bugfix |
| refine | workflow-refine |
| verify | workflow-verify |
| ai_review | workflow-ai-review |
| comprehension | workflow-comprehension |
| retro | workflow-retro |
| summarize | workflow-summarize |
| continue / human gate | workflow-continue |

## Multi-chat pattern (recommended)

Run each **phase skill** in its own chat. When it finishes (`status: awaiting_human`), open a **new chat** and invoke **workflow-continue** (or `/dev-pipeline continue`). Opening a new agent and running continue **assumes approve** on advance gates — it launches the next phase skill in that turn, then stops. To take a different action, send `refine:` / `reject:` / `re-clarify:` instead.

Example:

1. Chat A — `workflow-implement` → stops at gate, names next step (verify)
2. Chat B — `continue workflow` → approve assumed → runs verify → stops at gate, names next step (ai_review)
3. Chat C — `continue workflow` → approve assumed → runs ai_review → stops at gate

This keeps context small while still using skills end-to-end. Gates needing input (clarify, comprehension, retro questions) still wait for your answer instead of auto-advancing.
