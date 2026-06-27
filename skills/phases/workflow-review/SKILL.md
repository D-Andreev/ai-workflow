---
name: workflow-review
description: >-
  Review phase of the dev pipeline. Fresh-eyes scenario verification plus
  principles-based code review in one pass. Use when dev-pipeline phase is review.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Review

Independent review with fresh eyes, then principles-based code review on the same pass. Assume you have **not** seen the implementation conversation.

## Fresh-eyes rule

**Ignore prior chat history.** Base all judgments only on:

- `.cursor/workflows/artifacts/requirements.md`
- `.cursor/workflows/artifacts/implement-handoff.md`
- `.cursor/workflows/PROJECT.md`
- `.cursor/workflows/learnings/gotchas.md`
- `git diff {state.base_branch}...HEAD` (read `base_branch` from `state.json`)
- The actual code and tests

At the start of the artifact header, state: **"Fresh-eyes: judgments based on artifacts and diff only."** If you reference implementation-chat reasoning, the report is invalid — rewrite.

## Process

### 1. Scenario verification

1. Read artifacts and diff — understand what was built vs what was required.
2. Derive **scenario tests** from requirements and the handoff's "Suggested review scenarios":
   - Happy path
   - Edge cases named in requirements
   - Error / failure paths
   - Regression risks relevant to this project's domain (from requirements and PROJECT.md)
3. Execute verification:
   - Run unit tests using commands from PROJECT.md
   - Run targeted tests for changed areas (narrow scope to what the change touched)
   - Run integration or end-to-end tests if the change touches API contracts, shared interfaces, or cross-module flows
   - Manually trace critical paths in code if automated tests are insufficient
4. Record scenario results, requirements coverage, and test-found issues.

### 2. Principles review (same pass)

After scenario verification, review **only**:

1. Open 🔴/🟡 issues from scenario testing (confirm severity, suggest fix approach — do not fix)
2. Areas scenario tests cannot fully judge (design fit, security boundaries, maintainability)
3. Checklist categories:
   - **Security** — auth, secrets, injection, sensitive data
   - **Design / maintainability** — separation of concerns, API surface, over-abstraction
   - **Conventions** — error handling, naming, style vs project norms

Identify the project's stack from manifests and PROJECT.md. Apply idiomatic best practices for that stack.

**Do not** re-run scenario tests you already passed. **Do not** re-litigate areas cleared with PASS on scenarios — reference them briefly under "Scenario overlap avoided".

### 3. Write artifact and stop

Write `.cursor/workflows/artifacts/review-report.md` (template below).
Update state: `status` → `awaiting_human`, history `phase_completed`.

## review-report.md template

```markdown
# Review Report

**Fresh-eyes:** judgments based on artifacts and diff only (`{base_branch}...HEAD`).

## Verdict
APPROVE | APPROVE WITH NOTES | REQUEST CHANGES

## Scenario verification

### Scenarios tested

| # | Scenario | Method | Result | Notes |
|---|----------|--------|--------|-------|
| 1 | ... | test/manual | pass/fail | ... |

### Requirements coverage
- [ ] Each acceptance criterion verified or explicitly gap-noted

### Issues found (from testing)
- 🔴 Critical: ...
- 🟡 Minor: ...

### Gaps in test coverage
- ...

## Principles review

### Summary
{2-3 sentences — design, security, maintainability; not a duplicate of scenario tables}

### Critical (must fix)
- {file:line — tied to test findings or security/design checklist}

### Suggestions (should consider)
- ...

### Nice to have
- ...

### Scenario overlap avoided
- {what scenario testing already covered — do not re-litigate}

### Principles applied
- {which project patterns were checked}

## Recommendation
approve | refine | reject — {one line why}
```

## Human gate

Present verdict, top scenario findings, and critical/suggestion counts. Wait for `approve`, `refine:`, or `reject:`.

`reject:` sends the pipeline back to the **build phase** for a full rebuild (per state-schema routing table).

## Rules

- Be skeptical — look for missing edge cases, auth boundaries, state transitions, validation limits, and error paths.
- Do not fix code in review — report issues; refine/implement handles fixes.
- Do not modify application code — review only.
- Distinguish must-fix from nice-to-have.
- Reference specific files and lines where possible.
- If verdict is REQUEST CHANGES, set recommendation to `refine` or `reject` clearly.
