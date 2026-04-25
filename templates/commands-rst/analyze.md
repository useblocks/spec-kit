---
description: Perform a non-destructive cross-artefact consistency and quality analysis across spec.rst, plan.rst, and tasks.rst after task generation, using needs.json as the structured oracle.
handoffs:
  - label: Fix Spec Issues
    agent: speckit.specify
    prompt: Refine the specification to address analysis findings
    send: true
  - label: Adjust Plan
    agent: speckit.plan
    prompt: Update the plan to resolve architecture or coverage gaps found during analysis
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Output Format

This project is configured for RST output (see `.specify/config.toml` `format = "rst"`). The artefacts under analysis are:

- `spec.rst` — user stories (`.. user_story::`), functional requirements (`.. req::`), risks (`.. risk::`), decisions (`.. decision::`), acceptance tests (`.. test::`)
- `plan.rst` — architectural specs (`.. spec::`), decisions (`.. decision::`), system tests (`.. test::`)
- `tasks.rst` — implementation tasks (`.. task::`)

The seven directive types are: `user_story`, `req`, `spec`, `task`, `test`, `risk`, `decision`.

Link fields that carry traceability: `:traces_to:`, `:satisfies:`, `:verifies:`, `:implements:`, `:affects:`, `:motivates:`, `:mitigates:`. The inverse link names are: `traces_from`, `satisfied_by`, `verified_by`, `implemented_by`, `affected_by`, `motivated_by`, `mitigated_by`.

Coverage filters (e.g. "requirements with no satisfying spec") are expressed as `.. needtable::` / `.. needflow::` filters in `coverage.rst` — those rendering directives belong there, not in the artefact files being analysed here.

## Pre-Execution Checks

**Check for extension hooks (before analysis)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_analyze` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Goal.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently.

## Goal

Identify inconsistencies, duplications, ambiguities, and coverage gaps across the three core artefacts (`spec.rst`, `plan.rst`, `tasks.rst`) before implementation. This command MUST run only after `/speckit.tasks` has successfully produced a complete `tasks.rst`.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

**Constitution Authority**: The project constitution (`.specify/memory/constitution.rst` if present, or `/memory/constitution.rst`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks — not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/speckit.analyze`.

**Structured oracle**: The primary source of truth for cross-artefact analysis is `needs.json`, built by `sphinx-build -b needs`. Do NOT grep over `.rst` source files to find requirements or links. The JSON already has all resolved link targets and field values.

## Execution Steps

### 1. Initialize Analysis Context

Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.rst
- PLAN = FEATURE_DIR/plan.rst
- TASKS = FEATURE_DIR/tasks.rst
- NEEDS_JSON = FEATURE_DIR/_build/needs/needs.json (or project-root equivalent)

Abort with an error message if any required artefact is missing (instruct the user to run the missing prerequisite command).
For single quotes in args like "I'm Groot", use escape syntax: e.g. `'I'\''m Groot'` (or double-quote if possible).

### 2. Load the Structured Oracle

Build (or verify) `needs.json`:

```bash
uv run --project <SPEC_KIT_ROOT> python -m sphinx -b needs -W . _build/needs
```

from the project root. If the build fails with errors, report them and abort — a broken sphinx build means the oracle is unreliable.

Load `_build/needs/needs.json`. The top-level structure is:

```
{
  "versions": {
    "current": {
      "needs": { "<id>": { "type": ..., "links": [...], "links_back": [...], ... }, ... },
      "needs_amount": N
    }
  }
}
```

Iterate the `needs` dict. For each need, extract:
- `id`, `type`, `title`, `description`, `status`
- outgoing link arrays: `links` (traces_to), `satisfies`, `verifies`, `implements`, `affects`, `motivates`, `mitigates`
- incoming link arrays: `links_back` (traces_from), `satisfied_by`, `verified_by`, `implemented_by`, `affected_by`, `motivated_by`, `mitigated_by`
- `docname` (which .rst file the need lives in)

**Do NOT grep `.rst` files** for requirement text or link resolution. `needs.json` is the oracle.

### 3. Coverage Gap Detection via Oracle

The canonical coverage queries — equivalent to what `coverage.rst` renders via its filter expressions — are:

**a. Unsatisfied requirements** (REQ with no satisfying SPEC):

```python
gaps = [n for n in needs.values()
        if n["type"] == "req" and not n.get("satisfied_by")]
```

**b. Unverified user stories** (US with no test verifying them):

```python
gaps = [n for n in needs.values()
        if n["type"] == "user_story" and not n.get("verified_by")]
```

**c. Unimplemented specs** (SPEC with no implementing TASK):

```python
gaps = [n for n in needs.values()
        if n["type"] == "spec" and not n.get("implemented_by")]
```

**d. Orphaned tasks** (TASK that implements nothing):

```python
orphans = [n for n in needs.values()
           if n["type"] == "task" and not n.get("implements")]
```

**e. Unmitigated risks** (RISK with no mitigating TASK or SPEC):

```python
gaps = [n for n in needs.values()
        if n["type"] == "risk" and not n.get("mitigated_by")]
```

**f. Dangling link targets**: links pointing to IDs that do not appear as keys in the `needs` dict.

Alternatively, if a pre-rendered `coverage.html` is available at `_build/html/coverage.html`, you may read its rendered filter tables instead of applying Python-equivalent filters — both paths are acceptable.

### 4. Build Semantic Models

Create internal representations (do not include raw artefact content in output):

- **Requirements inventory**: All `req` needs with IDs, title, `satisfied_by`, `verified_by` fields.
- **User story inventory**: All `user_story` needs with `verified_by` and `traces_from` (linked reqs).
- **Spec inventory**: All `spec` needs with `satisfies` (upstream REQ) and `implemented_by` (downstream TASKs).
- **Task coverage mapping**: All `task` needs with `implements` list.
- **Constitution rule set** (if constitution file present): extract MUST/SHOULD normative statements.

### 5. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in an overflow summary.

#### A. Duplication Detection

- Identify near-duplicate requirement or spec titles across `spec.rst` and `plan.rst`.
- Mark the lower-quality phrasing for consolidation.

#### B. Ambiguity Detection

- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria — look at `description` fields in needs.json.
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`) in need bodies.

#### C. Underspecification

- REQ needs whose description body contains a verb but no measurable outcome.
- User stories missing any acceptance criterion in the body text.
- TASK needs referencing file paths or components not traceable to any SPEC or REQ in the oracle.

#### D. Constitution Alignment

- Any requirement or plan element conflicting with a MUST principle from the constitution.
- Missing mandated sections or quality gates from the constitution.

#### E. Coverage Gaps

Run the Python-equivalent queries from Step 3. Report:
- REQs with no `satisfied_by`
- User stories with no `verified_by`
- SPECs with no `implemented_by`
- TASKs with no `implements`
- RISKs with no `mitigated_by`
- Dangling link targets

#### F. Inconsistency

- Terminology drift: the same concept named differently across `spec.rst`, `plan.rst`, and `tasks.rst` (compare need titles and description text).
- Data entities referenced in plan needs but absent in spec needs (or vice versa).
- Task ordering contradictions: TASK A `implements` SPEC B which `satisfies` REQ C, but TASK A has no dependency on a task implementing a prerequisite SPEC.
- Conflicting requirements (e.g., one REQ mandates technology X while another mandates technology Y).

### 6. Severity Assignment

Use this heuristic to prioritise findings:

- **CRITICAL**: Violates a constitution MUST; REQ with zero coverage that blocks baseline functionality; broken sphinx build; dangling link target.
- **HIGH**: Duplicate or conflicting requirement; ambiguous security/performance attribute; untestable acceptance criterion; SPEC with no implementing task.
- **MEDIUM**: Terminology drift; missing non-functional task coverage; underspecified edge case; unmitigated risk.
- **LOW**: Style or wording improvements; minor redundancy not affecting execution order.

### 7. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

```
## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| A1 | Duplication | HIGH | spec.rst REQ_AUTH_001, REQ_AUTH_002 | Two near-identical requirements | Merge; keep clearer wording |
```

(One row per finding. Stable IDs prefixed by category initial: A=Duplication, B=Ambiguity, C=Underspec, D=Constitution, E=Coverage, F=Inconsistency.)

**Coverage Summary Table:**

| Need ID | Type | Has Downstream Link? | Downstream IDs | Notes |
|---------|------|----------------------|----------------|-------|

**Constitution Alignment Issues:** (if any)

**Orphaned Tasks:** (TASKs with no `implements` link)

**Metrics:**

- Total needs in oracle (by type breakdown)
- REQ coverage % (REQs with >= 1 `satisfied_by`)
- US verification % (user stories with >= 1 `verified_by`)
- SPEC implementation % (SPECs with >= 1 `implemented_by`)
- Ambiguity count
- Duplication count
- Critical issues count

### 8. Provide Next Actions

At end of report, output a concise Next Actions block:

- If CRITICAL issues exist: Recommend resolving before `/speckit.implement`.
- If only LOW/MEDIUM: User may proceed, but provide improvement suggestions.
- Provide explicit command suggestions: e.g., "Run `/speckit.specify` to add missing acceptance tests", "Run `/speckit.plan` to add SPEC covering REQ_FEATURE_003", "Edit `tasks.rst` directly to add `implements` links for orphaned tasks".

### 9. Offer Remediation

Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

### 10. Check for Extension Hooks

After reporting, check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_analyze` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently.

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation.
- **Progressive disclosure**: Load the oracle incrementally; do not dump the full `needs.json` content into the analysis output.
- **Token-efficient output**: Limit findings table to 50 rows; summarise overflow.
- **Deterministic results**: Re-running without changes should produce consistent IDs and counts.

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis).
- **NEVER hallucinate missing sections** (if absent, report them accurately).
- **Prioritise constitution violations** (these are always CRITICAL).
- **Use examples over exhaustive rules** (cite specific need IDs, not generic patterns).
- **Report zero issues gracefully** (emit success report with coverage statistics).
- **Use the oracle, not the source**: load `needs.json` and apply link-field queries; do not regex-grep over `.rst` prose.

## Context

{ARGS}
