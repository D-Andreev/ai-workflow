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

1. Read all inputs.
2. If requirements are already complete in `requirements.md` with an approval checkbox unchecked, summarize and ask if anything changed — do not re-ask answered questions.
3. Ask **5–8 numbered questions** covering:
   - **Scope** — what's in / out
   - **Behavior** — edge cases, error handling, backwards compatibility
   - **Acceptance criteria** — how we know it's done
   - **Tests** — unit vs e2e, scenarios to cover
   - **Constraints** — files/packages to touch or avoid, migrations, deploy impact
4. Stop and wait for human answers. Do not proceed in the same turn.

## On human answers

1. Merge answers into `.cursor/workflows/artifacts/requirements.md` using the template below.
2. Set `requirements_approved` checkbox to unchecked.
3. Update state: `status` → `awaiting_human`, append history `phase_completed`.
4. Present summary and ask for `approve requirements` or more answers.

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
- ...

## Files / areas likely involved
- ...

## Approved by human
- [ ] Pending — reply `approve requirements` when ready
```

## Hard rules

- Never write or modify application source code.
- Never run `make test`, migrations, or deploy commands.
- Only write to `.cursor/workflows/artifacts/requirements.md` and workflow state files.
- If the task is trivial and fully specified, state that explicitly, produce `requirements.md`, and ask for `approve requirements` with zero questions.
