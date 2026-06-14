---
name: workflow-ai-review
description: >-
  AI code review phase of the dev pipeline. Reviews code quality, principles,
  security, and maintainability. Use when dev-pipeline phase is ai_review.
disable-model-invocation: true
---

# Workflow: AI Review

Principles-based code review. **Not a re-run of verify** — build on the verify report instead of repeating it.

## Preconditions

- `.cursor/workflows/artifacts/verify-report.md` **must exist** with a **Verdict** line.
- If missing or incomplete, stop and ask orchestrator to re-run verify.

## Inputs (read in this order)

1. `.cursor/workflows/artifacts/verify-report.md` — **verdict, issues, and "For AI review" section**
2. `.cursor/workflows/artifacts/requirements.md` — only for requirements ai_review must judge (design fit)
3. `git diff {state.base_branch}...HEAD` — only files/lines tied to verify findings or checklist below
4. `.cursor/workflows/PROJECT.md` and `.cursor/workflows/learnings/gotchas.md`

Do **not** re-run scenario tests verify already passed unless verify flagged a gap. Do **not** re-read implement-handoff for test results — use verify-report.

## Stack awareness

Identify the project's stack from manifests and PROJECT.md. Apply idiomatic best practices for that stack.

## Review scope

Review **only**:

1. Items listed under **For AI review** in verify-report.md
2. Open 🔴/🟡 issues from verify (confirm severity, suggest fix approach — do not fix)
3. Checklist categories verify cannot cover:
   - **Security** — auth, secrets, injection, sensitive data
   - **Design / maintainability** — separation of concerns, API surface, over-abstraction
   - **Conventions** — error handling, naming, style vs project norms

Skip files and concerns verify already cleared with PASS on scenarios.

## Review checklist

### Correctness (delta only)
- Logic matches requirements for areas verify flagged or listed under "For AI review"

### Language / project conventions
- Error handling idiomatic for the stack
- Framework usage consistent with existing patterns
- Handlers thin; logic in dedicated modules
- No unnecessary public API surface

### Security
- Auth on protected routes/operations
- No secrets in code
- Input validation where user input is accepted

### Maintainability
- Focused functions, clear names
- No over-abstraction
- Comments only where non-obvious

## Output

Write `.cursor/workflows/artifacts/ai-review.md`:

```markdown
# AI Code Review

**Based on verify verdict:** {PASS | PASS WITH NOTES | FAIL from verify-report}

## Verdict
APPROVE | APPROVE WITH NOTES | REQUEST CHANGES

## Summary
{2-3 sentences — principles and design, not duplicate of verify scenarios}

## Findings

### Critical (must fix)
- {file:line — tied to verify delta or security/design checklist}

### Suggestions (should consider)
- ...

### Nice to have
- ...

## Verify overlap avoided
- {what verify already covered — do not re-litigate}

## Principles applied
- {which project patterns were checked}

## Recommendation
approve | refine | reject — {one line}
```

## Human gate

Present verdict and critical/suggestion counts. Wait for `approve`, `refine:`, or `reject:`.

`reject:` sends the pipeline back to the **build phase** for a full rebuild (per state-schema routing table).

## Rules

- Do not modify application code — review only.
- Do not duplicate verify scenario results — reference verify-report.
- Distinguish must-fix from nice-to-have.
- Reference specific files and lines where possible.
