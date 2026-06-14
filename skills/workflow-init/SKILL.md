---
name: workflow-init
description: >-
  Initialize the AI dev pipeline for a project by generating a concise,
  project-specific PROJECT.md. Use when setting up the workflow in a new repo,
  when PROJECT.md is missing, or when the user runs /dev-pipeline init.
disable-model-invocation: true
---

# Workflow: Init

One-time (or refresh) setup for a repo. Inspects the project and writes a concise `.cursor/workflows/PROJECT.md` that every pipeline phase reads. Run this first when dropping these skills into a new project.

**Output only `PROJECT.md`. No application code changes.**

## When to use

| Situation | Action |
|-----------|--------|
| New repo, no `.cursor/workflows/PROJECT.md` | Generate it |
| `PROJECT.md` exists | Show it; ask before overwriting (offer `init refresh` to regenerate) |
| Stack/features changed significantly | Regenerate with `init refresh` |

## Process

1. **Gather facts** from the repo (read only what exists):
   - Package/manifest: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, etc. — name, scripts/commands, key dependencies.
   - `README.md` and any existing top-level docs — purpose, features, setup.
   - Build/config files — `vite.config.*`, `tsconfig.json`, `Makefile`, `docker-compose.yml`, CI files — for commands and architecture hints.
   - Source layout — top-level folders under the main source dir (e.g. `src/`).
2. **Infer essentials only**: what the project *is*, its main user-facing features, the core tech stack, the commands a contributor runs, and where code lives. Skip exhaustive dependency lists and history.
3. **Write** `.cursor/workflows/PROJECT.md` using the template below. Keep it short — aim for under ~50 lines.
4. **Confirm**: print the generated `PROJECT.md` path and a one-line summary. Note that `/dev-pipeline start` or `start-bugfix` can now be run.

## PROJECT.md template

Mirror this structure. Adapt section content to the actual project; omit a section only if it genuinely doesn't apply.

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
```

## Rules

- **Essentials only** — capture what an agent needs to make good changes, not a full manual. Prefer brevity over completeness.
- Never invent features, commands, or dependencies. Only state what the repo evidences.
- Do not write or modify application source code.
- Only write `.cursor/workflows/PROJECT.md`.
- If a project type isn't covered above (e.g. a CLI, library, or service), adapt the template sensibly while keeping the same section shape.
