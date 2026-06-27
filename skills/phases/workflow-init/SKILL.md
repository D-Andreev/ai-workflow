---
name: workflow-init
description: >-
  Initialize the dev pipeline for a project — scaffold workflow directories,
  seed gotchas.md, and generate PROJECT.md. Use when setting up a new repo,
  when PROJECT.md is missing, or when the user runs /dev-pipeline init.
disable-model-invocation: true
metadata:
  internal: true
---

# Workflow: Init

One-time (or refresh) setup for a repo. Run via `/dev-pipeline init`.

Scaffolds workflow directories, seeds durable files, and writes `.cursor/workflows/PROJECT.md` — the **single shared context** (project facts plus domain glossary from clarify). Do not create a separate `CONTEXT.md`.

**No application code changes.**

## When to use

| Situation | Action |
|-----------|--------|
| New repo, first-time setup | Full init: dirs + gotchas + PROJECT.md |
| `PROJECT.md` exists, user sent `init refresh` | Regenerate PROJECT.md only (ask before overwriting) |
| `PROJECT.md` exists, user sent plain `init` | Show current setup; offer `init refresh` if stack changed |
| Stack/features changed significantly | `/dev-pipeline init refresh` |

## Process

### 1. Explore

Check what already exists:

- `.cursor/workflows/PROJECT.md`
- `.cursor/workflows/learnings/gotchas.md`
- `.cursor/workflows/artifacts/` directory
- Active pipeline in `.cursor/workflows/state.json`

If the user sent **`init refresh`**, skip scaffolding — regenerate PROJECT.md only (step 4).

### 2. Scaffold directories (full init only)

Create any missing directories:

```
.cursor/workflows/artifacts/
.cursor/workflows/learnings/
```

Add an empty `.gitkeep` in `artifacts/` if the directory is new and empty.

### 3. Seed gotchas.md (full init only)

If `.cursor/workflows/learnings/gotchas.md` is missing, write:

```markdown
# Gotchas & Learnings

Curated pitfalls from dev pipelines. Consolidated after each workflow — not a per-run log.

No outstanding gotchas yet.
```

If it already exists, do not overwrite.

### 4. Generate PROJECT.md

**Gather facts** from the repo (read only what exists):

- Package/manifest: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, etc.
- `README.md` and existing top-level docs
- Build/config files — `vite.config.*`, `tsconfig.json`, `Makefile`, `docker-compose.yml`, CI files
- Source layout — top-level folders under the main source dir

**Infer essentials only**: what the project *is*, main features, stack, dev commands, where code lives.

**Write** `.cursor/workflows/PROJECT.md` using the template below. Keep it short — aim for under ~50 lines.

If PROJECT.md exists and this is **not** `init refresh`, show it and stop — do not overwrite without explicit refresh.

### 5. Confirm

Tell the user:

1. What was created or refreshed
2. Start a pipeline: `/dev-pipeline start "<task>"` or `/dev-pipeline start-bugfix "<task>"`

## PROJECT.md template

```markdown
# {Project Name}

{1-2 sentence description of what the project is and its role.}

## Overview

{Short paragraph: who uses it, the entry point / primary responsibility, and how it fits the wider system.}

## Main Features

- **{Feature}** — {one line}.
- ... (5-8 max; only the essential ones)

## Stack

{Core technologies as a compact list, e.g. language · framework · state · auth · key infra}

## Development

\`\`\`bash
{cmd}            # what it does (dev server, build, test, lint, format)
...
\`\`\`

Source layout: {top-level folders and what they hold}. Config in {key config files}.

## Language

_(Domain terms are added during clarify — one canonical term at a time.)_
```

## Writable files

Full init: `.cursor/workflows/artifacts/.gitkeep`, `.cursor/workflows/learnings/gotchas.md`, `.cursor/workflows/PROJECT.md`

Init refresh: `.cursor/workflows/PROJECT.md` only

## Rules

- **Essentials only** — capture what an agent needs to make good changes, not a full manual.
- **`## Language` starts empty** — clarify fills it during grilling; do not invent domain terms at init.
- Never invent features, commands, or dependencies. Only state what the repo evidences.
- Do not write or modify application source code.
