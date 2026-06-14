# Gotchas & Learnings

Curated pitfalls from dev pipelines. Consolidated after each workflow — not a per-run log.

## Workflow & state
- Routing lives only in `state-schema.md` — do not duplicate tables in orchestrator skills
- Always populate full `state.json` on start (including `artifacts` paths and `base_branch`)
- Use `/dev-pipeline cleanup` if summarize leaves orphaned ephemeral files

## Verify & review
- Verify owns scenario testing; ai_review builds on verify-report "For AI review" — avoid duplicate test runs
- Use `reject:` at ai_review for critical design/security issues that need a full rebuild

## Comprehension
- Use `skip-comprehension` (not bare `continue`) to waive the quiz — collides with `/continue-workflow`
- Small diffs auto-select **light** quiz mode (4–5 questions)
