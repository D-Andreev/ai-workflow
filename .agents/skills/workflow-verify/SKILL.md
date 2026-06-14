---
name: workflow-verify
description: >-
  Verify phase of the dev pipeline. Fresh-eyes scenario and integration testing.
  Use when dev-pipeline phase is verify.
disable-model-invocation: true
---

# Workflow: Verify

Independent verification with fresh eyes. Assume you have **not** seen the implementation conversation.

## Fresh-eyes rule

**Ignore prior chat history.** Base all judgments only on:

- `.cursor/workflows/artifacts/requirements.md`
- `.cursor/workflows/artifacts/implement-handoff.md`
- `.cursor/workflows/PROJECT.md`
- `git diff {state.base_branch}...HEAD` (read `base_branch` from `state.json`)
- The actual code and tests

At the start of this phase, state in the artifact header: **"Fresh-eyes: judgments based on artifacts and diff only."** If you reference implementation-chat reasoning, the report is invalid — rewrite.

## Process

1. Read artifacts and diff — understand what was built vs what was required.
2. Derive **scenario tests** from requirements and the handoff's "Suggested verify scenarios":
   - Happy path
   - Edge cases named in requirements
   - Error / failure paths
   - Regression risks relevant to this project's domain (from requirements and PROJECT.md)
3. Execute verification:
   - Run unit tests using commands from PROJECT.md
   - Run targeted tests for changed areas (narrow scope to what the change touched)
   - Run integration or end-to-end tests if the change touches API contracts, shared interfaces, or cross-module flows
   - Manually trace critical paths in code if automated tests are insufficient
4. Write `.cursor/workflows/artifacts/verify-report.md` (template below).
5. Update state: `status` → `awaiting_human`, history `phase_completed`.

## verify-report.md template

```markdown
# Verify Report

**Fresh-eyes:** judgments based on artifacts and diff only (`{base_branch}...HEAD`).

## Verdict
PASS | PASS WITH NOTES | FAIL

## Scenarios tested

| # | Scenario | Method | Result | Notes |
|---|----------|--------|--------|-------|
| 1 | ... | test/manual | pass/fail | ... |

## Requirements coverage
- [ ] Each acceptance criterion verified or explicitly gap-noted

## Issues found
- 🔴 Critical: ...
- 🟡 Minor: ...

## Gaps in test coverage
- ...

## For AI review (do not re-test these unless needed)
List items ai_review should focus on — open issues, design/security concerns verify cannot judge from tests alone:
- ...

## Recommendation
approve | refine | reject — {one line why}
```

## Human gate

Present verdict and top findings. Wait for `approve`, `refine:`, or `reject:`.

## Rules

- Be skeptical — look for missing edge cases called out in requirements, plus auth boundaries, state transitions, validation limits, and error paths.
- Do not fix code in verify — report issues; refine/implement handles fixes.
- If verdict is FAIL, set recommendation to `refine` or `reject` clearly.
- Populate **For AI review** so the next phase does not duplicate scenario testing.
