---
name: continue-workflow
description: >-
  Resume the dev pipeline at a human gate after a phase finished in another chat.
  Processes approve/refine/reject, updates state, and runs the next phase skill.
  Use when the user runs /continue-workflow, /dev-pipeline continue, or opens a
  new chat to advance the pipeline.
disable-model-invocation: true
---

# Continue Workflow

Bridge between **isolated phase chats**. Invoke this skill in a **new agent** when a phase skill (implement, verify, etc.) finished in another session and you need to review the gate or advance the pipeline.

Phase skills do the work. **This skill orchestrates** — it does not replace them.

**Routing:** Apply transitions only from [state-schema.md](../dev-pipeline/state-schema.md) — the **single source of truth**. Do not duplicate the routing table here.

## Commands

Parse the user's message:

| Input | Action |
|-------|--------|
| `/continue-workflow` | Resume at gate — **assumes approve** on advance gates, runs next phase |
| `/continue-workflow approve` | Explicit approve + run next phase in one turn |
| `/continue-workflow refine: <text>` | Set feedback, go to refine phase |
| `/continue-workflow reject: <text>` | Back to build phase from verify or ai_review gate |
| `/continue-workflow re-clarify: <text>` | Back to clarify, reset requirements approval |
| `/continue-workflow abort` | Cancel pipeline and delete ephemeral files |
| `/dev-pipeline continue` | Alias for `/continue-workflow` |
| `/dev-pipeline continue approve` | Alias for `/continue-workflow approve` |
| `approve requirements` | At clarify gate only — advance to build phase |
| `approve` | Advance past current human gate (when invoked with continue) |
| `refine: <text>` | Same as `/continue-workflow refine:` |
| `reject: <text>` | Same as `/continue-workflow reject:` |
| `re-clarify: <text>` | Same as `/continue-workflow re-clarify:` |
| `skip-comprehension` | Skip failed comprehension quiz (see Step 5) |
| `abort` | Same as `/continue-workflow abort` |

If the user sends numbered comprehension or retro answers without a slash command, route to the appropriate phase handler (see Steps 5–6).

**Do not** treat bare `continue` as a command — it collides with `/continue-workflow`. Use `/continue-workflow` or `skip-comprehension` explicitly.

## When to use

| Situation | Action |
|-----------|--------|
| Phase skill finished; `status` is `awaiting_human` | Run `/continue-workflow` — **approve is assumed** on advance gates |
| New chat; you already know you approve | `/continue-workflow` or `/continue-workflow approve` |
| You want a different action | `/continue-workflow refine:` / `reject:` / `re-clarify:` / `abort` |
| Gate needs input (clarify, comprehension, retro questions) | Continue presents the gate and waits — no auto-approve |
| Stuck on `ai_running` from a crashed session | Continue with recovery (see Step 1) |
| Orphaned pipeline files after crash | `/dev-pipeline cleanup` |
| No active pipeline (`status: idle`) | Tell user to `/dev-pipeline start` |

## Inputs (always read first)

1. `.cursor/workflows/state.json`
2. `.cursor/workflows/STATUS.md`
3. Relevant artifact for current phase (use paths from `state.artifacts`)
4. `.cursor/skills/dev-pipeline/state-schema.md` — **routing table and recovery**

## Process

### Step 1 — Assess state

Read `state.json`. Handle invalid or stuck state per **Invalid state recovery** in state-schema.md.

**`status: awaiting_human`** — Normal. Go to Step 2.

**`status: ai_running`** — Likely a stuck prior session. If the phase artifact for current `phase` looks complete, set `status` → `awaiting_human`, history `recovered`, update STATUS.md, then Step 2. If incomplete, tell user to re-run the phase skill.

**`status: idle` or missing `state.json`** — No active pipeline. Suggest `/dev-pipeline start "<task>"`.

**`status: done` with `phase: done`** — Pipeline finished. Suggest starting a new pipeline or `/dev-pipeline cleanup` if orphaned files remain.

### Step 2 — Implicit approve vs. present gate

A fresh `/continue-workflow` (or `/dev-pipeline continue`) with **no explicit command** means **approve is assumed** on **advance gates only**. Match command `approve` in the routing table, then Step 4.

**Do NOT auto-approve — present gate and stop:**

- **clarify** — needs explicit `approve requirements`
- **comprehension** — needs quiz answers, pass, or `skip-comprehension`
- **retro (questions pending, no retro.md yet)** — needs answers first

If the user message includes an explicit command (`approve`, `refine:`, `reject:`, `re-clarify:`, `skip-comprehension`, `abort`, or numbered quiz/retro answers), skip implicit approve → Step 3.

### Step 3 — Process gate command

Match the command to a row in the **Routing table** in state-schema.md. Apply state changes, then Step 4 with the listed skill.

Special cases:

- **`reject:`** — allowed at **verify** and **ai_review** gates; routes to build phase per `mode`.
- **`abort`** — cancel and run cleanup (delete ephemeral files per state-schema).
- **`approve` at comprehension** — only if `comprehension_passed: true` OR `comprehension_skipped: true`.

**After summarize:** Deletes artifacts, `state.json`, and `STATUS.md`. Present completion summary only.

### Step 4 — Run next phase (same turn)

After processing an advance command:

1. Update `state.json` (`phase`, `status: ai_running`, `updated_at`, history)
2. Rewrite `STATUS.md`
3. **Immediately follow the next phase skill** (read its SKILL.md and execute)
4. When that phase completes:
   - **Normal phases:** set `status: awaiting_human`, append `phase_completed`, update STATUS.md, present human gate — **stop**
   - **Summarize phase:** follows workflow-summarize close steps — **stop**

Do **not** chain multiple phases in one turn. One gate command → one phase execution → stop.

### Step 5 — Comprehension special case

1. **Questions turn** — comprehension skill generates questions; user answers by number.
2. **Grade turn** — numbered answers → **workflow-comprehension** (grade). If FAIL, stop; offer `ready` / `retake` or **`skip-comprehension`**.
3. **Skip turn** — `skip-comprehension` → **workflow-comprehension** (shame mode); then ask for `approve`.
4. **Pass turn** — `comprehension_passed: true` → user sends `approve` → **workflow-retro**.

If user sends `approve` but neither passed nor skipped, reject and explain options.

If user sends `ready` or `retake` after fail, run comprehension **generate** mode.

### Step 6 — Retro special case

1. **Questions turn** — retro skill asks questions; user answers in follow-up → run **workflow-retro** "on human answers", stop at `approve`.
2. **Approve turn** — user sends `approve` → **workflow-summarize**.

If retro.md does not exist and message contains answers (not `approve`), treat as retro continuation.

## Gate artifact map

Read paths from `state.artifacts`:

| Phase at gate | Artifact key |
|---------------|----------------|
| clarify | `requirements` |
| implement / bugfix / refine | `implement_handoff` |
| verify | `verify_report` |
| ai_review | `ai_review` |
| comprehension | `comprehension_test` |
| retro | `retro` (if exists) or questions pending |

## Invocation examples

After implement finished elsewhere:

```
/continue-workflow
```

Approve is assumed → runs verify → stops at verify gate.

Reject critical ai_review findings:

```
/continue-workflow reject: auth bypass in middleware — rebuild with proper checks
```

Skip comprehension after failed quiz:

```
skip-comprehension
```

## Run a single phase in isolation (no continue)

```
Run dev-pipeline implement phase only. Follow .cursor/skills/workflow-implement/SKILL.md.
```

When it stops at `awaiting_human`, **open a new chat** and run `/continue-workflow`.

## Rules

- **Never** do phase work without reading that phase's skill.
- **Never** skip `requirements_approved` before build.
- **Never** modify application code in continue-only turns.
- Apply routing only from state-schema.md.
- Always update both `state.json` and `STATUS.md` on every transition.
- One gate command → one phase → stop.
