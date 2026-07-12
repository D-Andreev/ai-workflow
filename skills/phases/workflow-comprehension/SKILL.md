---
name: workflow-comprehension
description: >-
  Comprehension test phase after review. Interviews the human one question at a
  time to confirm they understand the functionality, code changes, and how to
  maintain them. Pass or skip-comprehension required before retro. Use when
  dev-pipeline phase is comprehension.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Comprehension Test

Verify the **human** understands what was built — behavior, code structure, and how to maintain it. Goal: you can own this change confidently before retro and merge.

Runs after review is approved. **Must pass or explicitly skip before retro.**

## Inputs

- `.cursor/workflows/artifacts/requirements.md`
- `.cursor/workflows/artifacts/implement-handoff.md`
- `.cursor/workflows/artifacts/review-report.md`
- `git diff {state.base_branch}...HEAD`
- Key changed source files (read as needed to write good questions)
- `.cursor/workflows/state.json` — `comprehension_attempt`, `comprehension_passed`, `comprehension_skipped`
- `.cursor/workflows/artifacts/comprehension-test.md` (if exists — prior attempts and Q&A log)

## Interview style

Ask **one question at a time** — free text or multiple choice (`A`/`B`/`C`/`D`). Like clarify, but you **grade each answer** before asking the next.

**Cover these dimensions** across the interview (not necessarily one question each — adapt to the diff):

| Dimension | What to probe |
|-----------|---------------|
| **Functionality** | What changed for users/systems, edge cases, error behavior |
| **Code** | Where the change lives, how data/control flows through it, key design choices |
| **Maintenance** | Where to extend or fix later, what tests guard this, what to watch for |

**Question count is not fixed.** Decide how many questions are sufficient based on:

- Files and modules touched
- Behavioral complexity (new flows vs small tweak)
- Whether the human is demonstrating understanding or revealing gaps

A tiny one-file fix may need only 3–4 questions; a multi-module feature may need 8+. Stop early only when all three dimensions are adequately demonstrated — not after a quota.

## What NOT to ask

- Trivia: port numbers, exact env var names, line numbers, memorized identifiers
- Facts irrelevant to understanding the change
- Trick questions or framework minutiae unless central to the diff

## Modes

Determine mode from state, artifact, and user message:

| Situation | Mode |
|-----------|------|
| First entry, or `ready` / `retake` after fail | **start** |
| User message answers the pending question (not `approve`, `skip-comprehension`, `ready`, `retake`) | **continue** |
| User says `skip-comprehension` (aliases: `take the shame`) | **shame** |
| Passed; user sends `approve` | Handled by **dev-pipeline continue** → retro |

**Never** use bare `continue` — use `/dev-pipeline continue` explicitly.

## Mode: start

1. If new attempt (`comprehension_attempt` is 0, or user sent `ready` / `retake`): increment `comprehension_attempt` in `state.json`.
2. Read the diff and artifacts. Identify probe areas for this change.
3. Create or append to `comprehension-test.md` (see template). Record planned probe areas.
4. Ask **question 1** only — free text or multiple choice. For MC, include options and state which letter to reply with.
5. Set `status` → `awaiting_human`. Do **not** mark phase completed.

**Stop.** Wait for the answer.

## Mode: continue

1. Read the user's answer to the **last pending question** in `comprehension-test.md`.
2. Grade: **correct**, **partial**, or **incorrect** with brief rationale. Append to the artifact.
3. Decide next action:

### More probing needed

- Ask the **next question** (one only). Prefer areas not yet demonstrated or where the last answer was weak.
- Update `status` → `awaiting_human`.

**Stop.** Wait for the answer.

### Sufficient understanding demonstrated

- Write result: `PASS — demonstrated understanding of {areas}`.
- Set `comprehension_passed: true`, `status` → `awaiting_human`, append history `phase_completed`.
- Summarize what they demonstrated well.
- Ask for **`approve`** to continue to retro.

**Stop.**

### Critical gaps remain

Only fail after you have asked enough questions to fairly assess all three dimensions (functionality, code, maintenance). If gaps are critical:

- Write result: `FAIL — gaps: {list with file pointers}`.
- Set `comprehension_passed: false`, `status` → `awaiting_human`.
- Offer:
  - **`ready`** / **`retake`** — new attempt after reviewing the code
  - **`skip-comprehension`** — proceed unpassed (recorded; quality gate waived)

**Stop.** Do not ask a new question in the same turn as declaring FAIL.

## Mode: shame

Triggered by **`skip-comprehension`** (alias: `take the shame`).

1. Set `comprehension_passed`: false, `comprehension_skipped`: true in `state.json`.
2. Append history event `comprehension_skipped`.
3. Append `**SKIPPED — continued without passing**` to the current attempt in `comprehension-test.md`.
4. Append history `phase_completed`, `status` → `awaiting_human`.
5. Brief, playful acknowledgment (1–2 emojis max) — recorded for posterity.
6. Ask for **`approve`** to continue to retro.

**Stop.**

## comprehension-test.md template

```markdown
# Comprehension Test: {pipeline id}

**Style:** one question at a time · Pass: sufficient understanding across functionality, code, and maintenance

## Attempt {n} — {ISO date}

### Probe plan
- Functionality: ...
- Code: ...
- Maintenance: ...

### Q1 — {free text | multiple choice} [{dimension}]
{question text}
{If MC: A) ... B) ... C) ... D) ...}

**Answer:** (pending | user's answer)
**Grade:** (pending | correct | partial | incorrect)
**Rationale:** ...

### Q2 — ...
```

## Rules

- **Never** modify application source code.
- **Never** ask trivia (ports, line numbers, exact variable names, unrelated config).
- **Never** dump all questions at once — **one question per turn**.
- **Never** reuse the same questions across attempts.
- **Never** advance to retro without `comprehension_passed: true` OR `comprehension_skipped: true`.
- Be fair but rigorous — partial credit for directionally right answers; follow up when an answer is vague.

State fields (`comprehension_attempt`, `comprehension_passed`, `comprehension_skipped`) are defined in state-schema.md.
