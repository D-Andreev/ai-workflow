---
name: workflow-continue
description: >-
  Resume the dev pipeline at a human gate or after a phase finished in another
  chat. Processes approve/refine/reject, updates state, and runs the next phase
  skill. Use when the user says continue workflow, /dev-pipeline continue, or
  opens a new chat after a phase skill completed.
disable-model-invocation: true
---

# Workflow: Continue

Bridge between **isolated phase chats**. Use this when a phase skill (implement, verify, etc.) finished in another session and you need to review the gate or advance the pipeline.

Phase skills do the work. **This skill orchestrates** — it does not replace them.

## When to use

| Situation | Action |
|-----------|--------|
| Phase skill finished; `status` is `awaiting_human` | Run continue — **approve is assumed** on advance gates, runs the next phase |
| New chat; you already know you approve | `continue workflow` (approve assumed) or `continue workflow approve` |
| You want a different action | Send `refine:` / `reject:` / `re-clarify:` / `abort` with continue |
| Gate needs input (clarify, comprehension, retro questions) | Continue presents the gate and waits — no auto-approve |
| Stuck on `ai_running` from a crashed session | Continue with recovery (see below) |
| No active pipeline (`status: idle`) | Tell user to `/dev-pipeline start` |

## Inputs (always read first)

1. `.cursor/workflows/state.json`
2. `.cursor/workflows/STATUS.md`
3. Relevant artifact for current phase (see gate table below)
4. `.cursor/skills/dev-pipeline/SKILL.md` — routing rules
5. `.cursor/skills/dev-pipeline/state-schema.md` — transitions

## Process

### Step 1 — Assess state

Read `state.json`. Handle:

**`status: awaiting_human`** — Normal. Go to Step 2.

**`status: ai_running`** — Likely a stuck prior session. Check whether the phase artifact for current `phase` looks complete (e.g. `implement-handoff.md` updated recently). If complete, set `status` → `awaiting_human`, note recovery in history, update STATUS.md, then Step 2. If incomplete, tell user to re-run the phase skill for that phase in a new chat.

**`status: idle` or missing `state.json`** — No active pipeline. Suggest `/dev-pipeline start "<task>"`.

**`status: done` with `phase: done`** — Pipeline finished. Suggest starting a new pipeline.

### Step 2 — Implicit approve vs. present gate

A fresh `continue workflow` (or `/dev-pipeline continue`) with **no explicit command** means **approve is assumed**: advance the gate and run the next phase. This is the normal multi-agent flow — each step ends, the user opens a new agent, runs continue, and the next state triggers.

**Apply implicit approve** when the current gate is a simple advance gate. Treat it exactly like an explicit `approve` — go to Step 3 with command `approve`, then Step 4 (run next phase):

| phase at gate | implicit approve → |
|---------------|--------------------|
| implement | verify |
| bugfix | verify |
| refine | verify |
| verify | ai_review |
| ai_review | comprehension |
| retro (retro.md written) | summarize |

**Do NOT auto-approve these — they need real input.** Instead show the gate (id, phase, status; 2–5 bullet artifact summary; test/lint status; `git diff --stat` if code changed; **next step**; exact commands), then **stop**:

- **clarify** — requirements need explicit `approve requirements`.
- **comprehension** — human must answer the quiz and pass first.
- **retro (questions pending, no retro.md yet)** — present questions and wait for answers.

If the user message **includes** an explicit command (`approve`, `refine:`, `reject:`, `re-clarify:`, `abort`, or numbered quiz/retro answers), skip implicit approve and process it directly in Step 3.

### Step 3 — Process gate command

If the user message includes a command, apply it:

| Command | Preconditions | State changes | Next phase skill |
|---------|---------------|---------------|------------------|
| `approve requirements` | `phase: clarify`, requirements.md exists | `requirements_approved: true`, history `human_approved` | **workflow-implement** (`mode: feature`) or **workflow-bugfix** (`mode: bugfix`) |
| `approve` | `awaiting_human`, phase not summarize; comprehension requires `comprehension_passed: true` | history `human_approved` | See routing table |
| `refine: <text>` | implement, bugfix, refine, verify, or ai_review gate | append `human_feedback`, history `human_refine`, `phase: refine` | **workflow-refine** |
| `reject: <text>` | verify gate only | append `human_feedback`, history `human_reject`, `phase: implement`/`bugfix` per `mode` | **workflow-implement** (`mode: feature`) or **workflow-bugfix** (`mode: bugfix`) |
| `re-clarify: <text>` | any gate | reset `requirements_approved: false`, `phase: clarify` | **workflow-clarify** |
| `abort` | any | `status: cancelled`, `phase: done` | none |

**Routing after `approve`:**

| Current phase at gate | Next phase | Skill to run |
|----------------------|------------|--------------|
| clarify (`mode: feature`) | implement | workflow-implement |
| clarify (`mode: bugfix`) | bugfix | workflow-bugfix |
| implement | verify | workflow-verify |
| bugfix | verify | workflow-verify |
| refine | verify | workflow-verify |
| verify | ai_review | workflow-ai-review |
| ai_review | comprehension | workflow-comprehension |
| comprehension (passed) | retro | workflow-retro |
| retro (retro.md written) | summarize | workflow-summarize |

**After summarize:** Deletes artifacts, `state.json`, and `STATUS.md`. Present completion summary only — no state files remain.

### Step 4 — Run next phase (same turn)

After processing an advance command:

1. Update `state.json` (`phase`, `status: ai_running`, `updated_at`, history)
2. Rewrite `STATUS.md`
3. **Immediately follow the next phase skill** (read its SKILL.md and execute)
4. When that phase completes:
   - **Normal phases:** set `status: awaiting_human`, append `phase_completed`, update STATUS.md, present the human gate — always **name the next step** and offer both options (`approve` here, or open a new agent and `continue workflow` to assume approve) — **stop**
   - **Summarize phase:** follows workflow-summarize close steps (delete artifacts, state.json, STATUS.md) — **stop**

Do **not** chain multiple phases in one turn. One gate command → one phase execution → stop.

### Step 5 — Comprehension special case

Comprehension has multiple human interactions:

1. **Questions turn** — comprehension skill generates questions; user answers by number.
2. **Grade turn** — user sends answers (via continue or same chat). Run **workflow-comprehension** in **grade** mode. If FAIL, stop and ask user to review changes, then reply **`ready`** for a new test.
3. **Pass turn** — `comprehension_passed: true`. User sends **`approve`**. Continue runs **workflow-retro**.

If user message at comprehension gate contains numbered answers (not `approve`/`ready`), route to comprehension **grade** mode.

If user sends `approve` but `comprehension_passed` is not true, reject and explain they must pass the test first.

If user sends `ready` or `retake` after a fail, run comprehension **generate** mode (new questions).

### Step 6 — Retro special case

Retro has two human interactions:

1. **Questions turn** — retro skill asks questions; user answers in a follow-up message. Use continue with their answers: run **workflow-retro** "on human answers" path, stop at `approve`.
2. **Approve turn** — user sends `approve`. Continue runs **workflow-summarize**. Summarize closes the pipeline automatically.

If user opens continue after retro questions but before retro.md exists, and their message contains answers (not just `approve`), treat as retro continuation — run retro skill's "on human answers" section.

## Gate artifact map

| Phase at gate | Read this artifact |
|---------------|-------------------|
| clarify | `artifacts/requirements.md` |
| implement | `artifacts/implement-handoff.md` |
| bugfix | `artifacts/implement-handoff.md` (bug-fix handoff) |
| refine | `artifacts/implement-handoff.md` (refinement log) |
| verify | `artifacts/verify-report.md` |
| ai_review | `artifacts/ai-review.md` |
| comprehension | `artifacts/comprehension-test.md` (questions pending or pass/fail result) |
| retro | `artifacts/retro.md` (if exists) or note questions pending |

## Invocation examples

User opens a **new agent** after implement finished elsewhere:

```
continue workflow
```

Approve is assumed: continue summarizes the implement handoff, advances the gate, runs verify, then stops at the verify gate (naming the next step).

Explicit one-shot is equivalent:

```
/dev-pipeline continue approve
```

User wants refine instead:

```
refine: remove unused field from DTO
```

Continue records feedback, runs refine phase, stops at new gate.

## Run a single phase in isolation (no continue)

To run **only** one phase in a fresh chat without orchestration:

```
Run dev-pipeline implement phase only. Follow .cursor/skills/workflow-implement/SKILL.md.
```

When it stops at `awaiting_human`, **open a new chat** and run continue.

Same pattern for bugfix, verify, ai_review, comprehension, clarify, refine, retro — use the matching `workflow-*` skill.

## Rules

- **Never** do phase work without reading that phase's skill.
- **Never** skip `requirements_approved` before implement.
- **Never** modify application code in continue-only turns (gate presentation / state updates only). Code changes happen inside phase skills.
- Verify and ai_review phase skills must still run in fresh chats when possible — continue launches them, but the verify skill enforces fresh-eyes from artifacts.
- Always update both `state.json` and `STATUS.md` on every transition.
- One gate command → one phase → stop. Prevents CLI stalls from long chains.
