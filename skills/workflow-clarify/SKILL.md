---
name: workflow-clarify
description: >-
  Clarification phase of the dev pipeline. Asks numbered questions about
  requirements before any code is written. Use when dev-pipeline phase is clarify
  or when gathering requirements for a new task.
disable-model-invocation: true
---

# Workflow: Clarify

Gather requirements before implementation. **No code changes. No test runs. No file edits outside workflow artifacts.**

## Inputs

1. `.cursor/workflows/artifacts/task.md`
2. `.cursor/workflows/PROJECT.md`
3. `.cursor/workflows/learnings/gotchas.md` (skim for relevant past gotchas)

## Process

1. Read all inputs and any releveant code in the project that might be related to the ask.
2. If requirements are already complete in `requirements.md` with an approval checkbox unchecked, summarize and ask if anything changed — do not re-ask answered questions.
3. Ask questions one at a time, either multiple choice or free text. Make sure the AI has the same understanding as the human about the task. Based on the answers if they don't continue asking more questions. Ask **10-20 numbered questions** covering :
   - **Scope** — what's in / out
   - **Behavior** — edge cases, error handling, backwards compatibility
   - **Acceptance criteria** — how we know it's done
   - **Implementation details** - how will the implementation look like at a high level
   - **Tests** — unit vs e2e, scenarios to cover (implement and bugfix phases will use TDD red-green cycles for these)
   - **Constraints** — files/packages to touch or avoid, migrations, deploy impact
4. Stop and wait for human answers. Do not proceed in the same turn.

## Clarify round limits

- Read `state.clarify_rounds` (default 0). Increment by 1 each time you complete a Q&A round (questions asked + answers merged).
- **Maximum 3 rounds.** When `clarify_rounds` reaches 3:
  - Do not ask new questions.
  - Finalize `requirements.md` with explicit **Assumptions** for anything still open.
  - Tell the human to `approve requirements` or send `re-clarify:` to reset.

## On human answers

1. Merge answers into `.cursor/workflows/artifacts/requirements.md` using the template below.
2. Set `requirements_approved` checkbox to unchecked.
3. Update state: increment `clarify_rounds`, `status` → `awaiting_human`, append history `phase_completed`.
4. Present summary and ask for `approve requirements` or more answers (unless max rounds reached).

## requirements.md template

```markdown
# Requirements: {pipeline id}

## Original ask
{from task.md}

## Clarifications

| # | Question | Answer |
|---|----------|--------|
| 1 | ... | ... |

## Acceptance criteria
- [ ] ...

## Out of scope
- ...

## Test expectations
- ... (scenarios that implement/bugfix will drive with TDD red-green cycles)

## Files / areas likely involved
- ...

## Approved by human
- [ ] Pending — reply `approve requirements` when ready
```

## Hard rules

- Never write or modify application source code.
- Never run test, lint, migration, or deploy commands.
- Only write to `.cursor/workflows/artifacts/requirements.md` and workflow state files.
- If the task is trivial and fully specified, state that explicitly, produce `requirements.md`, and ask for `approve requirements` with zero questions.
