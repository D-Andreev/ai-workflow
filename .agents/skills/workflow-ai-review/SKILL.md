---
name: workflow-ai-review
description: >-
  AI code review phase of the dev pipeline. Reviews code quality, principles,
  security, and maintainability. Use when dev-pipeline phase is ai_review.
disable-model-invocation: true
---

# Workflow: AI Review

Principles-based code review. Not a re-run of verify — focus on quality, design, and long-term maintainability.

## Inputs

- `.cursor/workflows/artifacts/requirements.md`
- `.cursor/workflows/artifacts/implement-handoff.md`
- `.cursor/workflows/artifacts/verify-report.md`
- `git diff` against base branch
- `.cursor/workflows/PROJECT.md`
- `.cursor/workflows/learnings/gotchas.md`

## Stack awareness

First, identify the project's stack (language, frameworks, libraries) from manifests
(e.g. `package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`), `.cursor/workflows/PROJECT.md`,
and existing code conventions. Apply the **idiomatic best practices for that stack** when
evaluating the checklist below. The categories are language-agnostic; the specific patterns
you check against come from the detected stack and the project's established conventions.

## Review checklist

### Correctness
- Logic matches requirements
- Edge cases handled (null/undefined, empty collections, boundary values, timezone/date boundaries)

### Language / project conventions
- Error and exception handling idiomatic for the stack
- Data-access and framework usage consistent with existing patterns
- Clear separation of concerns (entry points/handlers thin; logic in dedicated modules/services)
- No unnecessary public/exported API surface
- Follows the project's established style, lint, and formatting rules

### Security
- Auth checks on protected routes/operations
- No secrets in code
- Input validation and injection protection where user input is accepted
- Safe handling of sensitive data

### Tests
- Meaningful assertions, not trivial
- Parameterized/table or it-based tests where appropriate for the stack
- Critical paths covered

### Maintainability
- Functions/components focused, names clear
- No over-abstraction or premature generalization
- Comments only where non-obvious

## Output

Write `.cursor/workflows/artifacts/ai-review.md`:

```markdown
# AI Code Review

## Verdict
APPROVE | APPROVE WITH NOTES | REQUEST CHANGES

## Summary
{2-3 sentences}

## Findings

### Critical (must fix)
- ...

### Suggestions (should consider)
- ...

### Nice to have
- ...

## Principles applied
- {which project patterns were checked}

## Recommendation
approve | refine — {one line}
```

## Human gate

Present verdict and critical/suggestion counts. Wait for `approve` or `refine:`.

## Rules

- Do not modify application code — review only.
- Distinguish must-fix from nice-to-have.
- Reference specific files and lines where possible.
