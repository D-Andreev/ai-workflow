---
name: workflow-comprehension
description: >-
  Comprehension test phase after AI review. Quizzes the human on what changed,
  why, and maintenance implications. Pass required before retro. Use when
  dev-pipeline phase is comprehension.
disable-model-invocation: true
---

# Workflow: Comprehension Test

Verify the **human** understands the implementation — not the code. Goal: you can maintain the project confidently before retro and merge.

Runs after ai_review is approved. **Must pass before retro.**

## Inputs

- `.cursor/workflows/artifacts/requirements.md`
- `.cursor/workflows/artifacts/implement-handoff.md`
- `.cursor/workflows/artifacts/verify-report.md`
- `.cursor/workflows/artifacts/ai-review.md`
- `git diff` against base branch
- Key changed source files (read as needed to write good questions)
- `.cursor/workflows/state.json` — check `comprehension_attempt` (default 0)
- `.cursor/workflows/artifacts/comprehension-test.md` (if exists — prior attempts)

## Modes

Determine mode from state and user message:

| Situation | Mode |
|-----------|------|
| First entry (`comprehension_attempt` is 0 or missing) | **generate** |
| User message is answers to numbered questions (not `approve`) | **grade** |
| Failed last attempt; user says `ready` or `retake` | **generate** (new attempt) |
| Failed last attempt; user says `continue` or `take the shame` | **shame** (proceed unpassed) |
| Passed; user sends `approve` | Handled by **workflow-continue** → retro |

## Mode: generate

1. Increment `comprehension_attempt` in `state.json`.
2. Write **about 8–10 numbered questions** (aim for ~8–9, never more than 10) testing understanding of:
   - **What changed** — behavior, API, data flow
   - **Why** — design choices tied to requirements
   - **Edge cases** — deactivate paths, errors, validation boundaries
   - **Maintenance** — where to change things later, what breaks if removed
   - **Implications** — DB legacy data, HTTP codes, downstream effects
3. **Mix question formats** — some open-ended, and roughly **2–4 multiple choice** (label options `A`/`B`/`C`/`D`, exactly one correct unless stated otherwise). Multiple choice is great for edge cases and HTTP codes; keep the deeper "why" / "maintenance" questions open-ended.
4. Questions must differ from **all prior attempts** in `comprehension-test.md` — new angles, not paraphrases.
5. Append to `comprehension-test.md` (see template below).
6. Set `status` → `awaiting_human`. Do **not** mark phase completed.
7. Tell the human: answer all questions by number (give the letter for multiple choice), then send replies. No `approve` until they pass.

**Stop.** Wait for answers.

## Mode: grade

1. Read the user's answers (match by question number).
2. Score each question: **correct**, **partial**, or **incorrect** with brief rationale.
3. **Pass threshold:** > **60%** correct (partial counts as half a point), **and** no incorrect on questions tagged `[critical]` (mark 2–3 critical questions when generating).
4. Append results to current attempt in `comprehension-test.md`.
5. Update `state.json`: set `comprehension_passed`: true/false.

### If PASS

- Write final result: `PASS — {score}`.
- Set `status` → `awaiting_human`, append history `phase_completed`.
- Summarize what they demonstrated well.
- Ask for **`approve`** to continue to retro.

**Stop.**

### If FAIL

- Write result: `FAIL — {score}`. List gaps clearly (what to re-read).
- Set `comprehension_passed`: false, `status` → `awaiting_human`.
- Tell the human to review:
  - `implement-handoff.md`
  - `git diff` and key changed files
  - sections they got wrong (with file pointers)
- Offer them **two choices**:
  - Reply **`ready`** (or `retake`) when done reviewing — you will generate a **new** test (different questions).
  - Reply **`continue`** (or `take the shame`) to skip the test and proceed to retro **unpassed**.

**Stop.** Do not generate new questions in the same turn as grading.

## On `ready` / `retake` after fail

Run **generate** mode again (new attempt, new questions).

## Mode: shame

The human gave up on passing and chose to continue anyway. Let them — but make them feel it (lovingly).

1. Set `comprehension_passed`: false and add `comprehension_skipped`: true in `state.json`.
2. Append a `**SHAME — continued without passing**` note to the current attempt in `comprehension-test.md`, with the final score.
3. Append history `phase_completed` and set `status` → `awaiting_human`.
4. Roast them gently with a meme moment. Be funny, not mean. Examples to riff on:
   - The bell ringing 🔔 — *"Shame. Shame. Shame."* (Game of Thrones)
   - *"I'm not even mad, that's amazing."*
   - *"Bold strategy Cotton, let's see if it pays off."*
   - A `git blame` joke about future-you finding this code at 2am.
   - Pick or invent one; vary it across runs. Use 1–2 emojis max.
5. Remind them the score is recorded for posterity, then ask for **`approve`** to continue to retro.

**Stop.**

## comprehension-test.md template

```markdown
# Comprehension Test: {pipeline id}

Pass threshold: > 60%, all [critical] questions must be correct/partial.

## Attempt {n} — {ISO date}

### Questions

1. [critical] ...
2. (multiple choice) ...
   - A. ...
   - B. ...
   - C. ...
   - D. ...
3. ...
...

### Answers

| # | Your answer | Score | Notes |
|---|-------------|-------|-------|
| 1 | ... | correct/partial/incorrect | ... |

### Result

**FAIL — 4/9 (44%)**

Gaps to review:
- ...

---

## Final result

**PASS — 6/9 (67%)** — approved for retro
```

Or, if they chose to continue unpassed:

```markdown
## Final result

**SHAME — 4/9 (44%)** — continued without passing 🔔
```

## Rules

- **Never** modify application source code.
- **Never** ask trivia (line numbers, exact variable names) — test understanding and implications.
- **Never** reuse the same questions across attempts — check prior attempts in the artifact.
- **Never** advance to retro without either PASS recorded (`comprehension_passed: true`) **or** an explicit `continue` / `take the shame` from the human (`comprehension_skipped: true`).
- Be fair but rigorous — partial credit for directionally right answers missing detail.
- If the user asks for hints before answering, give a small nudge but do not give the full answer.

## State fields

Add/update in `state.json` during this phase:

| Field | Type | Description |
|-------|------|-------------|
| `comprehension_attempt` | number | Count of test attempts (increment each generate) |
| `comprehension_passed` | boolean | true only after passing grade |
| `comprehension_skipped` | boolean | true if human chose to continue unpassed (`take the shame`) |
