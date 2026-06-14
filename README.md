# Dev Pipeline

Multi-phase development workflow with human review gates. Orchestrated by the `dev-pipeline` and `continue-workflow` skills.

> **Note:** I'm using Cursor CLI, so all of these live inside the `.cursor/` folder in my projects. If you're using another agent harness you can use the content of these and adapt them for your AI tool.

## Skills

Copy `.agents/skills/` into `.cursor/skills/` in your project (and `workflows/` into `.cursor/workflows/`).

| Skill | Invoke | Purpose |
|-------|--------|---------|
| `dev-pipeline` | `/dev-pipeline` | Start, init, status, cleanup, and orchestrate the pipeline |
| `continue-workflow` | `/continue-workflow` | Resume at a human gate in a **new agent** (recommended multi-agent flow) |
| `workflow-*` | (internal) | Phase work — launched by the orchestrator skills above |

**Validate** (this repo): `./scripts/validate-workflow.sh`

## First-time setup (per repo)

When dropping these skills into a new repo, generate a project-specific `PROJECT.md` first:

```
/dev-pipeline init
```

This inspects the repo and writes `.cursor/workflows/PROJECT.md`. Every pipeline phase reads it.

## Which command to use?

```mermaid
flowchart TD
    q{What are you doing?}
    q -->|New user-facing capability| feature["/dev-pipeline start \"...\""]
    q -->|Defect / regression| bugfix["/dev-pipeline start-bugfix \"...\""]
    q -->|First time in repo| init["/dev-pipeline init"]
    q -->|Resume after a gate| cont["/continue-workflow"]
    q -->|Cancel or remove orphan files| clean["abort or /dev-pipeline cleanup"]

    feature --> mode_feature[mode: feature → implement phase]
    bugfix --> mode_bug[mode: bugfix → bugfix phase]
```

| Situation | Command |
|-----------|---------|
| New feature | `/dev-pipeline start "<task>"` |
| Bug fix | `/dev-pipeline start-bugfix "<task>"` |
| Explicit diff base | `/dev-pipeline start "<task>" --base develop` |
| Resume pipeline | `/continue-workflow` (new agent; approve assumed on advance gates) |
| Cancel + delete ephemeral files | `abort` or `/dev-pipeline cleanup` |

Both **feature** and **bugfix** run the same phases after clarify; only the build step differs.

## Quick start

```
/dev-pipeline start "Add retry logic to notification emails"
```

```
/dev-pipeline start-bugfix "Fix duplicate notification emails on retry"
```

## Monitor progress

| What | Where |
|------|-------|
| Human-readable status | `.cursor/workflows/STATUS.md` (active pipeline only) |
| Machine state | `.cursor/workflows/state.json` (JSON Schema in skill bundle) |
| Routing rules | `.cursor/skills/dev-pipeline/state-schema.md` (single source of truth) |
| In chat | `/dev-pipeline status` or `/continue-workflow` |

Open `STATUS.md` in your editor and refresh after each agent turn.

### Multi-agent flow with `/continue-workflow` (recommended)

1. **Start** — `/dev-pipeline start "<task>"` in one agent
2. **Continue** — open a **new agent** and run `/continue-workflow`

At each gate, send the command for that step — usually `approve` to advance, or `refine:` (and at verify/ai_review, `reject:`) to iterate. **Recommended:** open a new agent for each phase; fresh context per step usually works better than running the whole pipeline in one chat. On advance gates, bare `/continue-workflow` assumes approve and runs the next phase. Gates that need your input (**clarify**, **comprehension quiz**, **retro questions**) wait for answers — no auto-advance. To stay in the same agent, send the gate command directly.

## Phases

```mermaid
flowchart TD
    start([/dev-pipeline start]) --> clarify
    startbug([/dev-pipeline start-bugfix]) --> clarify

    clarify["<b>clarify</b><br/><i>Ask questions; max 3 rounds.<br/>Build requirements.md</i>"]
    clarify -->|approve requirements| build

    subgraph build_phase [build phase - depends on mode]
        build{{mode?}}
        build -->|feature| implement["<b>implement</b>"]
        build -->|bugfix| bugfix["<b>bugfix</b>"]
    end

    implement --> gate1
    bugfix --> gate1
    gate1{{human gate}}
    gate1 -->|refine:| refine
    refine["<b>refine</b>"]
    refine --> gate1r{{human gate}}
    gate1r -->|refine:| refine
    gate1 -->|approve| verify
    gate1r -->|approve| verify

    verify["<b>verify</b><br/><i>Fresh-eyes scenarios</i>"] --> gate2{{human gate}}
    gate2 -->|refine:| refine
    gate2 -->|reject:| build
    gate2 -->|approve| ai_review

    ai_review["<b>ai_review</b><br/><i>Principles; builds on verify report</i>"] --> gate3{{human gate}}
    gate3 -->|refine:| refine
    gate3 -->|reject:| build
    gate3 -->|approve| comprehension

    comprehension["<b>comprehension</b>"] -->|fail / retake| comprehension
    comprehension -->|skip-comprehension| retro
    comprehension -->|pass + approve| retro

    retro["<b>retro</b><br/><i>Questions, then retro.md</i>"] --> gate4{{human gate}}
    gate4 -->|approve| summarize

    summarize["<b>summarize</b>"] --> done([done])

    classDef human fill:#fde68a,stroke:#b45309,color:#000;
    classDef ai fill:#bfdbfe,stroke:#1d4ed8,color:#000;
    classDef terminal fill:#d1fae5,stroke:#047857,color:#000;
    class gate1,gate1r,gate2,gate3,gate4 human;
    class clarify,implement,bugfix,refine,verify,ai_review,comprehension,retro,summarize ai;
    class start,startbug,done terminal;
```

| Phase | Who | What happens |
|-------|-----|--------------|
| **clarify** | AI | Numbered questions (max **3 rounds**); builds `requirements.md`. No code. |
| **implement** | AI | (feature) Code + tests per requirements. Reads `gotchas.md`. |
| **bugfix** | AI | (bugfix) Reproduce → regression test → minimal fix. |
| **refine** | AI | Addresses review feedback. |
| **verify** | AI | Fresh-eyes scenario tests; populates **For AI review** section. |
| **ai_review** | AI | Principles/security/design — **does not re-run verify scenarios**. |
| **comprehension** | AI + you | Quiz (**light** 4–5 Q for small diffs, **standard** 8–10 otherwise). Pass >60% or `skip-comprehension`. |
| **retro** | AI + you | **Two turns:** reflective questions → your answers → `retro.md` → `approve`. |
| **summarize** | AI | Consolidate `gotchas.md`, optional `PROJECT.md` update, delete ephemeral files. |

## Commands (at human gates)

| You type | Effect |
|----------|--------|
| `approve requirements` | clarify → build phase |
| `approve` | Advance to next phase |
| `refine: <feedback>` | Go to refine |
| `re-clarify: <note>` | Back to clarify |
| `reject: <reason>` | Back to build from **verify** or **ai_review** |
| `ready` / `retake` | After failed comprehension — new test |
| `skip-comprehension` | Skip quiz unpassed (recorded; alias: `take the shame`) |
| `abort` | Cancel and **delete ephemeral files** |
| `/dev-pipeline cleanup` | Delete orphaned artifacts/state/STATUS |
| `/continue-workflow` | New agent: resume — approve assumed on advance gates |

Full routing: `.cursor/skills/dev-pipeline/state-schema.md`

### Comprehension gate

1. Answer numbered questions in chat.
2. If you **pass** → `approve` → retro.
3. If you **fail** → review code → `ready` for retake **or** `skip-comprehension` to proceed (waives quality gate; score recorded).

### Retro gate (two turns)

1. **Turn 1:** Agent asks 3–5 reflective questions → **stop**. Reply with your answers (same or new chat with `/continue-workflow` + answers).
2. **Turn 2:** Agent writes `retro.md` → reply **`approve`** → summarize runs automatically.

## State and diffs

On start, the pipeline records `base_branch` in `state.json` (default: `origin/main`, else `main`, else current branch). All phases use:

```bash
git diff {base_branch}...HEAD
```

Override at start: `/dev-pipeline start "<task>" --base develop`

## Artifacts (ephemeral)

During a run, handoffs live in `.cursor/workflows/artifacts/`. **Deleted on summarize, abort, or cleanup:**

- `task.md`, `requirements.md`, `implement-handoff.md`, `verify-report.md`, `ai-review.md`, `comprehension-test.md`, `retro.md`

## Durable docs (persist)

| File | Purpose |
|------|---------|
| `PROJECT.md` | Project context — init-generated; updated only for major features |
| `learnings/gotchas.md` | Consolidated pitfalls (≤20 bullets; rewritten each run) |

## End-to-end walkthrough (example)

**Task:** `/dev-pipeline start "Add retry logic to notification emails"`

1. **clarify** — Agent asks scope/acceptance questions → you answer → `approve requirements`
2. **implement** — Code + tests → `implement-handoff.md` → you `approve` or `/continue-workflow`
3. **verify** — Fresh-eyes scenarios → `verify-report.md` with verdict + "For AI review" → `approve`
4. **ai_review** — Reviews verify deltas + security/design → `ai-review.md` → `approve`
5. **comprehension** — 8 questions (or 4 if small diff) → you pass → `approve`
6. **retro** — Agent asks "Did verify catch what you cared about?" → you answer → `retro.md` → `approve`
7. **summarize** — Updates gotchas, deletes artifacts

**Snippet — requirements.md (after clarify):**

```markdown
## Acceptance criteria
- [ ] Failed sends retry with exponential backoff (max 3)
- [ ] Idempotent — no duplicate emails on retry
```

**Snippet — verify-report.md:**

```markdown
## Verdict
PASS WITH NOTES
## For AI review (do not re-test these unless needed)
- Confirm backoff config matches existing job runner patterns
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Stuck `status: ai_running` | `/continue-workflow` — recovers if artifact complete; else re-run phase skill |
| Accidental implicit approve | Use `/continue-workflow refine:` instead; clarify/comprehension/retro never auto-approve |
| Partial summarize (files left behind) | `/dev-pipeline cleanup` |
| Active pipeline won't start | `abort` or cleanup first |
| Wrong diff base | Restart with `--base <branch>` |
| Comprehension too long for tiny change | Automatic **light** mode (≤3 files, ≤150 lines) |

## Development (this repo)

```bash
./scripts/validate-workflow.sh   # lint skills, fixtures, routing SSOT
```

Schema: `.agents/skills/dev-pipeline/state.schema.json`  
Example state: `.agents/fixtures/state-example-start.json`  
Golden transitions: `.agents/fixtures/transitions.json`
