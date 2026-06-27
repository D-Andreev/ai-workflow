---
name: workflow-clarify
description: >-
  Clarification phase of the dev pipeline. Grills requirements one question at
  a time, sharpens domain language, and updates PROJECT.md as terms crystallise.
  Use when dev-pipeline phase is clarify or when gathering requirements for a
  new task.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Clarify

Grill the plan before implementation — like a relentless interview that also builds shared language. **No application code changes. No test runs.**

`PROJECT.md` is the single durable context file: project facts from init **plus** the domain glossary (`## Language`). Do not create or reference a separate `CONTEXT.md`.

## Inputs

1. `.cursor/workflows/artifacts/task.md`
2. `.cursor/workflows/PROJECT.md` — read every turn; update `## Language` inline as terms resolve
3. `.cursor/workflows/learnings/gotchas.md` (skim for relevant past gotchas)
4. Relevant application code (read-only — cross-reference claims against the codebase)

## Grilling loop

Interview relentlessly until shared understanding. Walk each branch of the design tree, resolving dependencies between decisions one-by-one.

**One question at a time**, with a **recommended answer**. Asking multiple questions at once is bewildering. Stop and wait for the human after each question — do not proceed in the same turn.

If a question can be answered by exploring the codebase, explore instead of asking.

Cover:

- **Scope** — what's in / out
- **Behavior** — edge cases, error handling, backwards compatibility
- **Acceptance criteria** — how we know it's done
- **Implementation shape** — high-level approach, files/packages to touch or avoid
- **Tests** — scenarios implement/bugfix will drive with TDD red-green cycles
- **Constraints** — migrations, deploy impact, compatibility

## Domain modeling (during the session)

Actively sharpen the project's domain model as you grill. Use `PROJECT.md` — not a separate context file.

### Challenge against the glossary

When the user uses a term that conflicts with `## Language` in `PROJECT.md`, call it out. "Your glossary defines **cancellation** as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying **account** — do you mean the Customer or the User?"

### Stress-test with scenarios

Invent concrete scenarios that probe edge cases and force precision about boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. Surface contradictions: "The code cancels entire orders, but you said partial cancellation is possible — which is right?"

### Update PROJECT.md inline

When a term is resolved, update `## Language` in `.cursor/workflows/PROJECT.md` **immediately** — do not batch. Use this format:

```markdown
## Language

**Order**:
A customer request for goods or services, tracked from placement through fulfillment.
_Avoid_: Purchase, transaction

**Retry**:
A re-attempt to deliver a notification after a transient failure, bounded by a max count.
_Avoid_: Resend (too vague)
```

Rules for `## Language`:

- **Glossary only** — no implementation details, specs, or scratch notes
- **Be opinionated** — pick one canonical term; list alternatives under `_Avoid_`
- **Tight definitions** — one or two sentences; define what it IS
- **Project-specific terms only** — skip general programming concepts
- **Preserve other sections** — do not rewrite Overview, Stack, Development, etc. unless the user corrects a factual error

Create `## Language` lazily when the first term is resolved. If init left it empty, that's fine.

### Offer ADRs sparingly

Only offer `docs/adr/NNNN-slug.md` when **all three** are true:

1. **Hard to reverse** — meaningful cost to change later
2. **Surprising without context** — a future reader will wonder why
3. **Real trade-off** — genuine alternatives existed

If the user accepts, create the ADR in the same turn (before asking the next question). Use sequential numbering (`0001-`, `0002-`, …). Template:

```markdown
# {Short title}

{1-3 sentences: context, decision, and why.}
```

Create `docs/adr/` lazily when the first ADR is needed.

## Resume / round limits

- If `requirements.md` already has clarifications and approval is unchecked, summarize progress and ask if anything changed — do not re-ask answered questions.
- Read `state.clarify_rounds` (default 0). Increment by 1 each time you complete a Q&A round (questions asked + answers merged into artifacts).
- We don't have max questions specified, ask as much as you need to understand the requirements:
  - Do not ask new questions.
  - Finalize `requirements.md` with explicit **Assumptions** for anything still open.
  - Tell the human to `approve requirements` or send `re-clarify:` to reset.

## On human answers

Each turn after an answer:

1. Merge the answer into `.cursor/workflows/artifacts/requirements.md` (template below).
2. Update `## Language` in `PROJECT.md` if any terms were resolved this turn.
3. Set `requirements_approved` checkbox to unchecked.
4. Update state: increment `clarify_rounds` when a round completes, `status` → `awaiting_human`, append history `phase_completed`.
5. Ask the **next** grilling question (with recommended answer), **or** present a summary and ask for `approve requirements` if the design tree for this pass is exhausted.

If the task is trivial and fully specified, state that explicitly, produce `requirements.md`, and ask for `approve requirements` with zero questions.

## requirements.md template

Task-specific spec for this pipeline run. Domain vocabulary lives in `PROJECT.md`, not here — reference canonical terms from `## Language`.

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

## Test expectations
- ... (scenarios that implement/bugfix will drive with TDD red-green cycles)

## Implementation approach (high level)
- ... (use canonical terms from PROJECT.md ## Language)

## Files / areas likely involved
- ...

## Assumptions
- ... (only if rounds exhausted with open items)

## Approved by human
- [ ] Pending — reply `approve requirements` when ready
```

## Hard rules

- Never write or modify application source code (ADRs and `PROJECT.md` are allowed).
- Never run test, lint, migration, or deploy commands.
- Writable files: `.cursor/workflows/artifacts/requirements.md`, `.cursor/workflows/PROJECT.md` (`## Language` and factual corrections only), `docs/adr/*.md`, workflow state files.
- Never create `CONTEXT.md` — use `PROJECT.md` only.
