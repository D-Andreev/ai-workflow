#!/usr/bin/env bash
# Lightweight validation for dev-pipeline skills and state fixtures.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$ROOT/.agents/skills"
FIXTURES_DIR="$ROOT/.agents/fixtures"
SCHEMA="$SKILLS_DIR/dev-pipeline/state.schema.json"
EXAMPLE="$FIXTURES_DIR/state-example-start.json"
TRANSITIONS="$FIXTURES_DIR/transitions.json"
ORCHESTRATOR="$SKILLS_DIR/dev-pipeline/SKILL.md"
SCHEMA_DOC="$SKILLS_DIR/dev-pipeline/state-schema.md"
ERR=0

log_ok() { printf 'OK  %s\n' "$1"; }
log_fail() { printf 'FAIL %s\n' "$1"; ERR=1; }

require_file() {
  if [[ ! -f "$1" ]]; then
    log_fail "missing file: $1"
  fi
}

# --- JSON syntax ---
for f in "$SCHEMA" "$EXAMPLE" "$TRANSITIONS"; do
  require_file "$f"
  if python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
    log_ok "valid JSON: ${f#$ROOT/}"
  else
    log_fail "invalid JSON: ${f#$ROOT/}"
  fi
done

# --- Example state matches schema keys ---
python3 <<PY
import json, sys
schema = json.load(open("$SCHEMA"))
example = json.load(open("$EXAMPLE"))
required = set(schema.get("required", []))
missing = required - set(example.keys())
extra = set(example.keys()) - set(schema.get("properties", {}).keys())
if missing:
    print("FAIL example state missing keys:", ", ".join(sorted(missing)))
    sys.exit(1)
if extra:
    print("FAIL example state unexpected keys:", ", ".join(sorted(extra)))
    sys.exit(1)
print("OK  example state has all required keys")
PY

# --- Artifact paths in example ---
python3 <<PY
import json, sys
example = json.load(open("$EXAMPLE"))
expected = {
    "task": ".cursor/workflows/artifacts/task.md",
    "requirements": ".cursor/workflows/artifacts/requirements.md",
    "implement_handoff": ".cursor/workflows/artifacts/implement-handoff.md",
    "verify_report": ".cursor/workflows/artifacts/verify-report.md",
    "ai_review": ".cursor/workflows/artifacts/ai-review.md",
    "comprehension_test": ".cursor/workflows/artifacts/comprehension-test.md",
    "retro": ".cursor/workflows/artifacts/retro.md",
}
if example.get("artifacts") != expected:
    print("FAIL artifact paths do not match canonical paths")
    sys.exit(1)
print("OK  artifact paths match canonical paths")
PY

# --- Every workflow-* skill listed in orchestrator table ---
python3 <<PY
import pathlib, re, sys
root = pathlib.Path("$SKILLS_DIR")
orch = pathlib.Path("$ORCHESTRATOR").read_text()
workflow_skills = sorted(p.parent.name for p in root.glob("workflow-*/SKILL.md"))
# Phase skills table rows: | phase | workflow-* |
listed = set(re.findall(r"workflow-[a-z0-9_-]+", orch))
missing = [s for s in workflow_skills if s not in listed]
if missing:
    print("FAIL orchestrator missing workflow skills:", ", ".join(missing))
    sys.exit(1)
print("OK  all workflow-* skills referenced in dev-pipeline/SKILL.md")
PY

# --- Routing table lives only in state-schema.md (orchestrator should reference SSOT) ---
if grep -q "Routing table (single source of truth)" "$SCHEMA_DOC"; then
  log_ok "state-schema.md contains routing SSOT"
else
  log_fail "state-schema.md missing routing SSOT section"
fi

if grep -q "single source of truth" "$ORCHESTRATOR"; then
  log_ok "dev-pipeline references routing SSOT"
else
  log_fail "dev-pipeline should reference state-schema routing SSOT"
fi

# Duplicate full routing tables in orchestrator (pipe rows with phase | awaiting_human)
dup_count=$(grep -cE '^\| (clarify|implement|verify|ai_review) \| awaiting_human \|' "$ORCHESTRATOR" || true)
if [[ "$dup_count" -gt 0 ]]; then
  log_fail "dev-pipeline still contains duplicate routing table ($dup_count rows)"
else
  log_ok "dev-pipeline has no duplicate routing table"
fi

continue="$SKILLS_DIR/continue-workflow/SKILL.md"
dup_continue=$(grep -cE '^\| [a-z_]+ \| `(approve|refine:|reject:)` \|' "$continue" 2>/dev/null || true)
if [[ "$dup_continue" -gt 0 ]]; then
  log_fail "continue-workflow still contains duplicate routing table"
else
  log_ok "continue-workflow defers to state-schema SSOT"
fi

# --- Skill frontmatter ---
for skill in "$SKILLS_DIR"/*/SKILL.md; do
  if head -1 "$skill" | grep -q '^---$'; then
    if grep -q '^name:' "$skill" && grep -q '^description:' "$skill"; then
      :
    else
      log_fail "incomplete frontmatter: ${skill#$ROOT/}"
    fi
  else
    log_fail "missing frontmatter: ${skill#$ROOT/}"
  fi
done
log_ok "skill frontmatter present"

# --- Golden transitions reference known skills ---
python3 <<PY
import json, pathlib, sys
transitions = json.load(open("$TRANSITIONS"))
skills_dir = pathlib.Path("$SKILLS_DIR")
known = {p.name for p in skills_dir.glob("workflow-*/")}
for t in transitions:
    for part in t["skill"].split("|"):
        if not part.startswith("workflow-"):
            continue
        if part not in known:
            print(f"FAIL transition references unknown skill: {part}")
            sys.exit(1)
print("OK  golden transitions reference existing skills")
PY

exit "$ERR"
