---
name: workflow-clarify
description: >-
  Clarification phase of the dev pipeline. Grills the human one question at a
  time — requirements, behavior, and high-level implementation — against the
  project's domain language and existing code. Use when dev-pipeline phase is
  clarify or when gathering requirements for a new task.
disable-model-invocation: true
---

# Workflow: Clarify

Stress-test the task before implementation. Walk the design tree branch by branch, resolving dependencies between decisions one at a time. **No application code changes. No test runs.**

## Inputs

1. `.cursor/workflows/artifacts/task.md`
2. `.cursor/workflows/PROJECT.md`
3. `.cursor/workflows/learnings/gotchas.md` (skim for relevant past gotchas)

## Before asking anything

1. Read all inputs and explore relevant code — do not ask what the codebase already answers.
2. If `requirements.md` exists with pending approval and prior clarifications still apply, summarize what is resolved and ask whether anything changed — do not re-ask answered questions.
3. If the task is trivial and fully specified, state that explicitly, produce `requirements.md`, and ask for `approve requirements` with zero questions.

## Grilling session

Interview relentlessly until you and the human share a clear picture. For each unresolved decision:

1. **Ask one question** — never batch multiple questions in one turn.
2. **Provide your recommended answer** — state what you think is right and why.
3. **Stop and wait** for human feedback before continuing.

After asking a question, set `status` → `awaiting_human` and **stop** — do not increment `clarify_rounds` yet.

Walk down the design tree in dependency order — resolve foundational decisions before dependent ones (e.g. scope before behavior, behavior before implementation shape, implementation shape before test strategy).

### Question categories

Cover both **what** and **how** as the tree demands. Rotate through these as needed:

| Category | Probe |
|----------|-------|
| **Scope** | What's in / out; related work deferred |
| **Behavior** | Happy path, edge cases, error handling, backwards compatibility |
| **Domain language** | Precise terms; conflicts with `PROJECT.md` or existing code |
| **Scenarios** | Concrete examples that stress boundaries between concepts |
| **Acceptance criteria** | How we know it's done |
| **Implementation shape** | Likely modules, patterns, data flow, integration points — high level only |
| **Tests** | Unit vs integration vs e2e; scenarios implement/bugfix will drive with TDD |
| **Constraints** | Files/packages to touch or avoid, migrations, deploy impact |

Ask more questions for large features; fewer for small ones. Skip categories already settled by code exploration or prior answers.

### Domain awareness

While exploring and grilling:

- **Challenge against project context** — if the human uses a term that conflicts with `PROJECT.md` or the codebase, call it out immediately: *"PROJECT.md describes X as …, but you seem to mean Y — which is it?"*
- **Sharpen fuzzy language** — propose a precise canonical term when the human is vague: *"You said 'account' — do you mean Customer or User?"*
- **Stress-test with scenarios** — invent concrete edge-case scenarios that force precise boundaries.
- **Cross-reference with code** — if the human states how something works, verify in code. Surface contradictions: *"The code cancels entire Orders, but you said partial cancellation is possible — which is right?"*

### Update requirements inline

Do not batch clarifications until the end of a pass.

- **After each answered question**, merge the Q&A into `.cursor/workflows/artifacts/requirements.md` immediately.
- Do **not** write or update `PROJECT.md` during clarify — that happens in **summarize** for major features only.

## Clarify pass limits

- Read `state.clarify_rounds` (default 0).
- A **pass** ends when you present a summary and ask for `approve requirements` (or more answers).
- Increment `clarify_rounds` by 1 at the end of each pass.
- **Maximum 3 passes.** When `clarify_rounds` reaches 3:
  - Do not ask new questions.
  - Finalize `requirements.md` with explicit **Assumptions** for anything still open.
  - Tell the human to `approve requirements` or send `re-clarify:` to reset.

Within a pass, one-question-at-a-time turns do **not** increment `clarify_rounds`.

## On human answers

1. Merge the answer into `requirements.md` (that question's row — create the file from the template on first write).
2. If more decisions remain, ask the **next single question** with your recommended answer, set `status` → `awaiting_human`, and **stop** — never two new questions in one turn.
3. When the design tree for this pass is exhausted:
   - Set `requirements_approved` checkbox to unchecked.
   - Update state: increment `clarify_rounds`, `status` → `awaiting_human`, append history `phase_completed`.
   - Present summary and ask for `approve requirements` or more answers (unless max passes reached).

## requirements.md template

```markdown
# Requirements: {pipeline id}

## Original ask
{from task.md}

## Clarifications

| # | Question | Answer | Recommended |
|---|----------|--------|-------------|
| 1 | ... | ... | ... |

## Acceptance criteria
- [ ] ...

## Out of scope
- ...

## Implementation approach (high level)
- ... (modules, patterns, integration points — no code)

## Test expectations
- ... (scenarios that implement/bugfix will drive with TDD red-green cycles)

## Files / areas likely involved
- ...

## Assumptions
- ... (only when something remains unresolved)

## Approved by human
- [ ] Pending — reply `approve requirements` when ready
```

## Hard rules

- **One question per turn** when still gathering — never dump a numbered list of new questions.
- Always include a **recommended answer** with each question.
- Explore the codebase instead of asking when the answer is discoverable there.
- Never write or modify application source code.
- Never run test, lint, migration, or deploy commands.
- Only write to `.cursor/workflows/artifacts/requirements.md` and workflow state files.
- If the task is trivial and fully specified, produce `requirements.md` and ask for `approve requirements` with zero questions.
