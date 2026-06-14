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

**Routing:** Apply transitions only from [state-schema.md](state-schema.md) — the **single source of truth**. Do not duplicate the routing table here.

## Paths

| File | Purpose |
|------|---------|
| `.cursor/workflows/state.json` | Machine state — **created on start, deleted on summarize/abort/cleanup** |
| `.cursor/workflows/STATUS.md` | Human-readable progress — **created on start, deleted on summarize/abort/cleanup** |
| `.cursor/workflows/PROJECT.md` | Project context (read every phase) |
| `.cursor/workflows/artifacts/` | Handoff documents |
| `.cursor/workflows/learnings/gotchas.md` | Consolidated pitfalls (rewritten each workflow) |

Full state schema: [state-schema.md](state-schema.md) · JSON Schema: [state.schema.json](state.schema.json)

## Commands

Parse the user's message:

| Input | Action |
|-------|--------|
| `/dev-pipeline init` | Generate project-specific `PROJECT.md` (see **workflow-init** skill). Run once per repo before first start |
| `/dev-pipeline init refresh` | Regenerate `PROJECT.md` even if it exists |
| `/dev-pipeline start "<task>"` | New **feature** pipeline (uses implement phase) from task string |
| `/dev-pipeline start "<task>" --base <branch>` | Same, with explicit diff base branch |
| `/dev-pipeline start` | New feature pipeline from `artifacts/task.md` |
| `/dev-pipeline start-bugfix "<task>"` | New **bug-fix** pipeline (uses bugfix phase instead of implement) from task string |
| `/dev-pipeline start-bugfix` | New bug-fix pipeline from `artifacts/task.md` |
| `/dev-pipeline status` | Show STATUS.md if present; else report no active pipeline |
| `/dev-pipeline show artifacts` | List artifact files and last modified |
| `/dev-pipeline cleanup` | Delete ephemeral pipeline files (artifacts, state.json, STATUS.md) |
| `/dev-pipeline continue` | Alias for `/continue-workflow` (see **continue-workflow** skill) |
| `/dev-pipeline continue approve` | Alias for `/continue-workflow approve` |
| `approve requirements` | Advance clarify → build (see routing table) |
| `approve` | Advance past current human gate |
| `refine: <text>` | Set feedback, go to refine phase |
| `re-clarify: <text>` | Append note, go to clarify, reset requirements approval |
| `reject: <text>` | Back to build from verify or ai_review gate |
| `abort` | Cancel pipeline and **delete ephemeral files** (see state-schema cleanup) |

If the user answers numbered clarify questions without a command, treat as clarify-phase input (append to requirements draft).

## Start workflow

Both `start` (feature) and `start-bugfix` (bug fix) share the same steps; they differ only in the `mode` field and which phase replaces `implement`.

1. Read `state.json` if it exists. If missing, no active pipeline — proceed. If present and `status` is not `idle`, `cancelled`, or `done`, warn and ask to `abort` or `/dev-pipeline cleanup` first.
1a. If `.cursor/workflows/PROJECT.md` is missing, run **workflow-init** first (or tell the user to run `/dev-pipeline init`) — every phase depends on it.
2. Generate id: `kebab-task-name-YYYY-MM-DD` from task text.
3. Resolve `base_branch` per [state-schema.md](state-schema.md) (honor `--base` if provided).
4. Write `artifacts/task.md` with the task description.
5. Create `state.json` using the full shape from [fixtures/state-example-start.json](../../fixtures/state-example-start.json):
   - All required fields including `base_branch`, `clarify_rounds: 0`, `quiz_mode: "standard"`, `comprehension_skipped: false`
   - Populate `artifacts` with all canonical paths (see state-schema)
   - `mode`: `feature` for `start`, `bugfix` for `start-bugfix`
   - `phase`: `clarify`, `status`: `ai_running`, `requirements_approved`: false
   - `history`: `[{ "phase": "clarify", "event": "started", "at": "<ISO>", "note": "base_branch=<branch>" }]`
6. Update `STATUS.md` (include `Base branch: {base_branch}`).
7. Read `.cursor/workflows/PROJECT.md`.
8. Follow **workflow-clarify** skill instructions. Do not skip to the build phase.

The build phase after `approve requirements` depends on `mode`: `feature` → **workflow-implement**; `bugfix` → **workflow-bugfix**. Both build phases use **TDD red-green cycles** — failing test first (red), minimal fix or implementation (green), run tests at each step.

## Phase routing

After reading `state.json`, match the user's command to a row in the **Routing table** in [state-schema.md](state-schema.md). Apply state changes and launch the listed skill.

When entering an AI phase: set `status` to `ai_running`, append history event `phase_started`, update `STATUS.md`, then follow that phase's skill.

When completing an AI phase: write the phase artifact, set `status` to `awaiting_human`, append history event `phase_completed`, update `STATUS.md`, present human gate summary, **stop**.

## Abort and cleanup

On `abort` or `/dev-pipeline cleanup`:

1. Set `status: cancelled`, `phase: done`, append history `cancelled` (if state.json exists).
2. Delete all files listed under **Abort and cleanup** in state-schema.md.
3. Confirm what was deleted; durable docs (`PROJECT.md`, `gotchas.md`) remain.

## Human gate presentation

At each `awaiting_human` stop, show:

1. **Phase completed** and what's in the artifact
2. **Test/lint status** if applicable
3. **Files changed** — `git diff --stat {base_branch}...HEAD` (use `state.base_branch`)
4. **Specific questions** (max 3) if something needs a decision
5. **Next step** — always name the phase that runs after approval (e.g. "Next step: verify")
6. **How to proceed** — always present both options:
   - **Approve here:** send `approve` (or `approve requirements` at the clarify gate) in this chat, or
   - **Open a new agent and run `/continue-workflow`** — this **assumes approve** on advance gates and triggers the next state automatically.

Do not start the next phase in the same turn unless the user explicitly sent an advance command. Gates that need real input (clarify requirements, comprehension quiz, retro questions) are never auto-approved — see **continue-workflow** skill.

## STATUS.md template

Rewrite on every state change:

```markdown
# Pipeline: {id}

**Mode:** {mode} · **Phase:** {phase} · **Status:** {status} · **Base:** {base_branch}

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

- Always read `state.json` first; validate shape against state-schema if fields look wrong.
- Always read `PROJECT.md` before starting a phase.
- Never write application code in orchestrator turns — delegate to phase skills.
- Never skip clarify or requirements approval.
- Build phases (implement, bugfix, refine when tests change) must follow TDD red-green cycles — do not ship behavior without a failing test first.
- Apply routing only from state-schema.md.
- Verify phase: enforce fresh-eyes (workflow-verify skill).
- Comprehension: pass (>60%, critical questions) or explicit `skip-comprehension` before retro.
- Summarize: consolidates gotchas, deletes ephemeral files.
- Between pipelines: no `state.json` or `STATUS.md` — only durable docs persist.

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
| continue / human gate | continue-workflow |

## Multi-chat pattern (recommended)

Run each **phase skill** in its own chat. When it finishes (`status: awaiting_human`), open a **new chat** and invoke **`/continue-workflow`**. Opening a new agent and running continue **assumes approve** on advance gates — it launches the next phase skill in that turn, then stops. To take a different action, use `/continue-workflow refine:` / `reject:` / `re-clarify:` instead.

Example:

1. Chat A — `workflow-implement` → stops at gate, names next step (verify)
2. Chat B — `/continue-workflow` → approve assumed → runs verify → stops at gate, names next step (ai_review)
3. Chat C — `/continue-workflow` → approve assumed → runs ai_review → stops at gate

Gates needing input (clarify, comprehension quiz, retro questions) still wait for your answer instead of auto-advancing.
