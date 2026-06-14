---
name: workflow-comprehension
description: >-
  Comprehension test phase after AI review. Quizzes the human on what changed,
  why, and maintenance implications. Pass or skip-comprehension required before retro. Use when
  dev-pipeline phase is comprehension.
disable-model-invocation: true
---

# Workflow: Comprehension Test

Verify the **human** understands the implementation — not the code. Goal: you can maintain the project confidently before retro and merge.

Runs after ai_review is approved. **Must pass or explicitly skip before retro.**

## Inputs

- `.cursor/workflows/artifacts/requirements.md`
- `.cursor/workflows/artifacts/implement-handoff.md`
- `.cursor/workflows/artifacts/verify-report.md`
- `.cursor/workflows/artifacts/ai-review.md`
- `git diff {state.base_branch}...HEAD`
- Key changed source files (read as needed to write good questions)
- `.cursor/workflows/state.json` — `comprehension_attempt`, `quiz_mode`
- `.cursor/workflows/artifacts/comprehension-test.md` (if exists — prior attempts)

## Quiz mode (standard vs light)

On first **generate**, set `quiz_mode` in `state.json`:

| Condition | `quiz_mode` | Question count |
|-----------|-------------|----------------|
| ≤3 files changed in `git diff --stat {base_branch}...HEAD` **and** ≤150 lines changed | `light` | **4–5** questions, 1–2 [critical] |
| Otherwise | `standard` | **8–10** questions, 2–3 [critical] |

State the chosen mode in `comprehension-test.md` header.

## Modes

Determine mode from state and user message:

| Situation | Mode |
|-----------|------|
| First entry (`comprehension_attempt` is 0 or missing) | **generate** |
| User message is answers to numbered questions (not `approve`) | **grade** |
| Failed last attempt; user says `ready` or `retake` | **generate** (new attempt) |
| User says `skip-comprehension` (aliases: `take the shame`) | **shame** (proceed unpassed) |
| Passed; user sends `approve` | Handled by **dev-pipeline continue** → retro |

**Never** use bare `continue` — use `/dev-pipeline continue` explicitly.

## Mode: generate

1. Set `quiz_mode` if not set (see table above).
2. Increment `comprehension_attempt` in `state.json`.
3. Write questions per `quiz_mode` testing:
   - **What changed** — behavior, API, data flow
   - **Why** — design choices tied to requirements
   - **Edge cases** — error paths, validation boundaries
   - **Maintenance** — where to change things later
4. **Mix formats** — open-ended plus roughly **1–2 multiple choice** in light mode, **2–4** in standard (options `A`/`B`/`C`/`D`).
5. Questions must differ from **all prior attempts** in `comprehension-test.md`.
6. Append to `comprehension-test.md` (see template below).
7. Set `status` → `awaiting_human`. Do **not** mark phase completed.
8. Tell the human: answer by number (letter for multiple choice). No `approve` until pass or skip.

**Stop.** Wait for answers.

## Mode: grade

1. Read the user's answers (match by question number).
2. Score each question: **correct**, **partial**, or **incorrect** with brief rationale.
3. **Pass threshold:** > **60%** correct (partial = half point), **and** no incorrect on `[critical]` questions.
4. Append results to current attempt in `comprehension-test.md`.
5. Update `state.json`: set `comprehension_passed`: true/false.

### If PASS

- Write final result: `PASS — {score}`.
- Set `status` → `awaiting_human`, append history `phase_completed`.
- Summarize what they demonstrated well.
- Ask for **`approve`** to continue to retro.

**Stop.**

### If FAIL

- Write result: `FAIL — {score}`. List gaps with file pointers.
- Set `comprehension_passed`: false, `status` → `awaiting_human`.
- Offer:
  - **`ready`** / **`retake`** — new test after review
  - **`skip-comprehension`** — proceed unpassed (recorded; quality gate waived)

**Stop.** Do not generate new questions in the same turn as grading.

## On `ready` / `retake` after fail

Run **generate** mode again (new attempt, new questions). Keep same `quiz_mode` unless diff size changed materially.

## Mode: shame

Triggered by **`skip-comprehension`** (alias: `take the shame`).

1. Set `comprehension_passed`: false, `comprehension_skipped`: true in `state.json`.
2. Append history event `comprehension_skipped`.
3. Append `**SKIPPED — continued without passing**` to the current attempt in `comprehension-test.md`, with last score if any.
4. Append history `phase_completed`, `status` → `awaiting_human`.
5. Brief, playful acknowledgment (1–2 emojis max) — recorded for posterity.
6. Ask for **`approve`** to continue to retro.

**Stop.**

## comprehension-test.md template

```markdown
# Comprehension Test: {pipeline id}

**Mode:** light | standard · Pass: > 60%, all [critical] correct/partial

## Attempt {n} — {ISO date}

### Questions
...
```

## Rules

- **Never** modify application source code.
- **Never** ask trivia (line numbers, exact variable names).
- **Never** reuse questions across attempts.
- **Never** advance to retro without `comprehension_passed: true` OR `comprehension_skipped: true`.
- Be fair but rigorous — partial credit for directionally right answers.

## State fields

| Field | Type | Description |
|-------|------|-------------|
| `comprehension_attempt` | number | Test attempts (increment each generate) |
| `comprehension_passed` | boolean | true only after passing grade |
| `comprehension_skipped` | boolean | true after `skip-comprehension` |
| `quiz_mode` | string | `standard` or `light` |
