# Dev Pipeline (ai-workflow)

Cursor skill bundle for a multi-phase AI development workflow with human review gates, ephemeral artifacts, and durable learnings.

## Overview

This repository **is** the workflow — not an application. Skills live in `.agents/skills/`; copy them to `.cursor/skills/` in target projects. Workflow docs and learnings use `.cursor/workflows/` (template copy in `workflows/`).

## Main Features

- **dev-pipeline** — start, init, status, cleanup, orchestrate phases
- **continue-workflow** — multi-chat resume with implicit approve on advance gates
- **workflow-*** — phase skills (clarify, implement, bugfix, refine, verify, ai_review, comprehension, retro, summarize)
- **State machine** — `state.json` with JSON Schema; routing SSOT in `state-schema.md`
- **Learnings** — consolidated `gotchas.md` (rewritten each run)

## Stack

Markdown skills · Cursor CLI · Git · JSON state · Shell validation

## Development

```bash
./scripts/validate-workflow.sh    # validate skills, fixtures, routing SSOT
cp -r .agents/skills .cursor/skills && cp -r workflows .cursor/workflows   # install locally
```

Source layout: `.agents/skills/` (skill definitions), `workflows/` (PROJECT.md + learnings templates), `scripts/` (validation), `.agents/fixtures/` (golden state/transitions). Config: skill frontmatter in each `SKILL.md`.
