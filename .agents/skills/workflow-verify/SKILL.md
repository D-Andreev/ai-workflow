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
- `git diff` against the base branch
- The actual code and tests

## Process

1. Read artifacts and diff — understand what was built vs what was required.
2. Derive **scenario tests** from requirements and the handoff's "Suggested verify scenarios":
   - Happy path
   - Edge cases named in requirements
   - Error / failure paths
   - Regression risks (ingest, analytics, auth, notifications as relevant)
3. Execute verification:
   - Run `make test-unit`
   - Run targeted tests: `go test ./path/to/pkg -run TestName -v`
   - Run `make test-e2e` if the change touches API contracts or cross-service flows
   - Manually trace critical paths in code if tests are insufficient
4. Write `.cursor/workflows/artifacts/verify-report.md` (template below).
5. Update state: `status` → `awaiting_human`, history `phase_completed`.

## verify-report.md template

```markdown
# Verify Report

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

## Recommendation
approve | refine | reject — {one line why}
```

## Human gate

Present verdict and top findings. Wait for `approve`, `refine:`, or `reject:`.

## Rules

- Be skeptical — look for missing edge cases, especially around daily snapshots, job active/inactive logic, and JWT-protected paths.
- Do not fix code in verify — report issues; refine/implement handles fixes.
- If verdict is FAIL, set recommendation to `refine` or `reject` clearly.
