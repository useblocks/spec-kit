---
description: Identify underspecified areas in the current feature spec by asking up to 3 highly targeted clarification questions and encoding answers back into the sphinx-needs directives in spec.rst.
handoffs:
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
scripts:
   sh: scripts/bash/check-prerequisites.sh --json --paths-only
   ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Output Format

This project is configured for RST output (see `.specify/config.toml` `format = "rst"`). All spec artefacts live in `spec.rst`. The V-model directive types in use are:

| Directive        | ID prefix    | Purpose                              |
|------------------|--------------|--------------------------------------|
| `.. user_story::` | `US_`        | User-facing goal                     |
| `.. req::`        | `REQ_`       | Normative functional requirement     |
| `.. spec::`       | `SPEC_`      | Technical / design specification     |
| `.. task::`       | `TASK_`      | Implementation work item             |
| `.. test::`       | `TC_`        | Acceptance / verification test       |
| `.. risk::`       | `RISK_`      | Identified risk                      |
| `.. decision::`   | `DEC_`       | Architecture or design decision      |

Link types in use: `traces_to`, `satisfies`, `verifies`, `implements`, `affects`, `motivates`, `mitigates`.

`[NEEDS CLARIFICATION]` markers live **inside directive bodies**, indented under their parent directive. When replacing a marker the indentation of the directive body MUST be preserved. Example:

```rst
.. req:: Authenticate users
   :id: REQ_AUTH_001
   :status: open

   The system MUST [NEEDS CLARIFICATION: which auth method — OAuth2, SAML, or local password?]
```

After replacement:

```rst
.. req:: Authenticate users
   :id: REQ_AUTH_001
   :status: open

   The system MUST support OAuth2 for authentication.
```

## Pre-Execution Checks

**Check for extension hooks (before clarification)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_clarify` key.
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

    Wait for the result of the hook command before proceeding to the Outline.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently.

## Outline

Goal: Detect and reduce ambiguity or missing decision points in the active feature specification (`spec.rst`) and record the clarifications directly in that file, preserving all sphinx-needs directive syntax.

Note: This clarification workflow is expected to run (and be completed) BEFORE invoking `/speckit.plan`. If the user explicitly states they are skipping clarification (e.g., exploratory spike), you may proceed, but must warn that downstream rework risk increases.

Execution steps:

1. Run `{SCRIPT}` from repo root **once** (combined `--json --paths-only` mode / `-Json -PathsOnly`). Parse minimal JSON payload fields:
   - `FEATURE_DIR`
   - `FEATURE_SPEC` (path to `spec.rst`)
   - (Optionally capture `IMPL_PLAN`, `TASKS` for future chained flows.)
   - If JSON parsing fails, abort and instruct user to re-run `/speckit.specify` or verify feature branch environment.
   - For single quotes in args like "I'm Groot", use escape syntax: e.g `'I'\''m Groot'` (or double-quote if possible: `"I'm Groot"`).

2. Load `spec.rst`. Perform a structured ambiguity and coverage scan using this taxonomy. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output the raw map unless no questions will be asked).

   Functional Scope & Behavior:
   - Core user goals and success criteria
   - Explicit out-of-scope declarations
   - User roles / personas differentiation

   Domain & Data Model:
   - Entities, attributes, relationships
   - Identity and uniqueness rules
   - Lifecycle / state transitions
   - Data volume / scale assumptions

   Interaction & UX Flow:
   - Critical user journeys / sequences
   - Error / empty / loading states
   - Accessibility or localization notes

   Non-Functional Quality Attributes:
   - Performance (latency, throughput targets)
   - Scalability (horizontal/vertical, limits)
   - Reliability and availability (uptime, recovery expectations)
   - Observability (logging, metrics, tracing signals)
   - Security and privacy (authN/Z, data protection, threat assumptions)
   - Compliance / regulatory constraints (if any)

   Integration & External Dependencies:
   - External services / APIs and failure modes
   - Data import / export formats
   - Protocol / versioning assumptions

   Edge Cases & Failure Handling:
   - Negative scenarios
   - Rate limiting / throttling
   - Conflict resolution (e.g., concurrent edits)

   Constraints & Tradeoffs:
   - Technical constraints (language, storage, hosting)
   - Explicit tradeoffs or rejected alternatives

   Terminology & Consistency:
   - Canonical glossary terms
   - Avoided synonyms / deprecated terms

   Completion Signals:
   - Acceptance criteria testability
   - Measurable Definition of Done indicators

   Misc / Placeholders:
   - `[NEEDS CLARIFICATION]` markers already present in directive bodies
   - Ambiguous adjectives ("robust", "intuitive") lacking quantification

   For each category with Partial or Missing status, add a candidate question opportunity unless:
   - Clarification would not materially change implementation or validation strategy.
   - Information is better deferred to planning phase (note internally).

3. Generate (internally) a prioritized queue of candidate clarification questions (maximum 3). Do NOT output them all at once. Apply these constraints:
   - Maximum of 3 total questions across the whole session.
   - Each question must be answerable with EITHER:
      - A short multiple-choice selection (2–5 distinct, mutually exclusive options), OR
      - A one-word / short-phrase answer (explicitly constrain: "Answer in <=5 words").
   - Only include questions whose answers materially impact architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation.
   - Ensure category coverage balance: attempt to cover the highest-impact unresolved categories first; avoid asking two low-impact questions when a single high-impact area (e.g., security posture) is unresolved.
   - Exclude questions already answered, trivial stylistic preferences, or plan-level execution details (unless blocking correctness).
   - Favor clarifications that reduce downstream rework risk or prevent misaligned acceptance tests.
   - If more than 3 categories remain unresolved, select the top 3 by (Impact × Uncertainty) heuristic.

4. Sequential questioning loop (interactive):
   - Present EXACTLY ONE question at a time.
   - For multiple-choice questions:
      - **Analyze all options** and determine the **most suitable option** based on:
         - Best practices for the project type
         - Common patterns in similar implementations
         - Risk reduction (security, performance, maintainability)
         - Alignment with any explicit project goals or constraints visible in `spec.rst`
      - Present your **recommended option prominently** at the top with clear reasoning (1–2 sentences explaining why this is the best choice).
      - Format as: `**Recommended:** Option [X] — <reasoning>`
      - Then render all options as a Markdown table:

      | Option | Description |
      |--------|-------------|
      | A | <Option A description> |
      | B | <Option B description> |
      | C | <Option C description> (add D/E as needed up to 5) |
      | Short | Provide a different short answer (<=5 words) (include only if free-form alternative is appropriate) |

      - After the table, add: `You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
   - For short-answer style (no meaningful discrete options):
      - Provide your **suggested answer** based on best practices and context.
      - Format as: `**Suggested:** <your proposed answer> — <brief reasoning>`
      - Then output: `Format: Short answer (<=5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.`
   - After the user answers:
      - If the user replies with "yes", "recommended", or "suggested", use your previously stated recommendation/suggestion as the answer.
      - Otherwise, validate the answer maps to one option or fits the <=5 word constraint.
      - If ambiguous, ask for a quick disambiguation (count still belongs to same question; do not advance).
      - Once satisfactory, record it in working memory (do not yet write to disk) and move to the next queued question.
   - Stop asking further questions when:
      - All critical ambiguities resolved early (remaining queued items become unnecessary), OR
      - User signals completion ("done", "good", "no more"), OR
      - You reach 3 asked questions.
   - Never reveal future queued questions in advance.
   - If no valid questions exist at start, immediately report no critical ambiguities.

5. Integration after EACH accepted answer (incremental update approach):
   - Maintain an in-memory representation of `spec.rst` (loaded once at start) plus the raw file contents.
   - For the first integrated answer in this session:
      - Ensure a `Clarifications` RST section exists (create it just after the highest-level contextual / overview section per the template if missing). Use a section underline consistent with the document's heading style.
      - Under it, create (if not present) a `Session YYYY-MM-DD` subsection for today.
   - Append a bullet line immediately after acceptance: `- Q: <question> → A: <final answer>`
   - Then immediately apply the clarification to the most appropriate sphinx-needs directive(s):
      - Functional ambiguity: update or add a bullet in the body of the relevant `.. req::` or `.. user_story::` directive.
      - User interaction / actor distinction: update the body of the relevant `.. user_story::` with clarified role, constraint, or scenario.
      - Data shape / entities: update the body of the relevant `.. req::` or `.. spec::` directive (add fields, types, relationships); note added constraints succinctly.
      - Non-functional constraint: add / modify measurable criteria in the body of the relevant `.. req::` (convert vague adjective to metric or explicit target).
      - Edge case / negative flow: add a new bullet in an existing `.. req::` body or emit a new `.. req::` directive under Edge Cases (with a fresh ID allocated per ID conventions).
      - Terminology conflict: normalize the term across all affected directive bodies; retain the original only if necessary by adding `(formerly referred to as "X")` once.
   - Preserve directive body indentation exactly: replacement text must be indented to match the surrounding directive content (typically 3 spaces).
   - If the clarification invalidates an earlier ambiguous statement, replace that statement instead of duplicating; leave no obsolete contradictory text.
   - Save `spec.rst` AFTER each integration to minimize risk of context loss (atomic overwrite).
   - Preserve formatting: do not reorder unrelated directives or sections; keep heading hierarchy intact.
   - Keep each inserted clarification minimal and testable (avoid narrative drift).

6. Self-validation (performed after EACH write and as a final pass):

   Run:

   ```bash
   uv run --project <SPEC_KIT_ROOT> python -m sphinx -b needs -W . _build/needs
   ```

   from the project root. If the build fails:

   - Read the warning / error list (typically: missing `:traces_to:`, `:verifies:`, broken IDs, malformed directive syntax from the edit).
   - Fix each issue in `spec.rst`, preserving directive body indentation.
   - Re-run sphinx-build.
   - Loop maximum 3 times. After 3 failed iterations, report the remaining warnings in the completion message and let the user decide.

   Sphinx-build output is the structured oracle. Do NOT rely on grep or pattern matching for validation — the oracle is `sphinx-build -W`.

   Additional structural checks:
   - Clarifications section contains exactly one bullet per accepted answer (no duplicates).
   - Total asked (accepted) questions ≤ 3.
   - Updated directives contain no lingering `[NEEDS CLARIFICATION]` markers that the new answer was meant to resolve.
   - No contradictory earlier statement remains in any directive body.
   - Terminology consistency: same canonical term used across all updated directives.

7. Write the updated `spec.rst` back to `FEATURE_SPEC`.

8. Report completion (after questioning loop ends or early termination):
   - Number of questions asked and answered.
   - Path to updated `spec.rst`.
   - Directives touched (list IDs and types).
   - Coverage summary table listing each taxonomy category with Status: Resolved (was Partial/Missing and addressed), Deferred (exceeds question quota or better suited for planning), Clear (already sufficient), Outstanding (still Partial/Missing but low impact).
   - If any Outstanding or Deferred remain, recommend whether to proceed to `/speckit.plan` or run `/speckit.clarify` again later post-plan.
   - Suggested next command.

Behavior rules:

- If no meaningful ambiguities found (or all potential questions would be low-impact), respond: "No critical ambiguities detected worth formal clarification." and suggest proceeding.
- If `spec.rst` is missing, instruct user to run `/speckit.specify` first (do not create a new spec here).
- Never exceed 3 total asked questions (clarification retries for a single question do not count as new questions).
- Avoid speculative tech stack questions unless the absence blocks functional clarity.
- Respect user early termination signals ("stop", "done", "proceed").
- If no questions asked due to full coverage, output a compact coverage summary (all categories Clear) then suggest advancing.
- If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: {ARGS}

## Post-Execution Checks

**Check for extension hooks (after clarification)**:
Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_clarify` key.
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
