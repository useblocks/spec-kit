---
description: Create or update the feature specification with full V-model trace links (User Story / Functional Requirement / Acceptance Test, plus optional Risk / Decision).
handoffs:
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: speckit.clarify
    prompt: Clarify specification requirements
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Output Format

This project is configured for RST output (see `.specify/config.toml` `format = "rst"`). When writing the spec file, you MUST:

- Use reStructuredText syntax (section underlines, field lists, RST code-blocks).
- Express user stories, requirements, risks, decisions, and acceptance tests as sphinx-needs directives.
- Every directive carries an `:id:` matching regex `^[A-Z]+_[A-Z][A-Z0-9_]*$` (digits cannot follow the first underscore).
- Every requirement `.. req::` MUST have a `:traces_to: US_...` linking it to a user story.
- Every user story `.. user_story::` MUST be verified by at least one `.. test::` with `:verifies:`.
- Every risk `.. risk::` MUST `:affects:` at least one REQ.
- Every decision `.. decision::` MUST `:traces_to:` a user story (or `:motivates:` a SPEC, if it's a forward-looking architectural decision).

Allowed directives and roles in the spec.rst:
- `.. user_story::`, `.. req::`, `.. risk::`, `.. decision::`, `.. test::`, `.. needextend::`
- `:need:`, `:need_outgoing:`, `:need_incoming:`, `:need_part:`

If you find yourself wanting to use `.. needtable::`, `.. needflow::`, or any other rendering directive — those go in `coverage.rst` (auto-rendered), not in `spec.rst`. Keep authored artefacts focused on data; rendering is centralised.

### Handling unknowns: prefer `[NEEDS CLARIFICATION]` over invention

When the user input is silent on a question that requires user judgement (header-row handling, language choice, performance thresholds, API surface contract, default values), **do not invent a SHOULD or MUST clause to close the gap**. Instead, embed the marker inside the directive body:

```rst
.. req:: Validate the bucket count
   :id: REQ_FEATURE_BUCKETS_001
   :status: open
   :traces_to: US_FEATURE_001

   System MUST reject negative or zero bucket counts.
   [NEEDS CLARIFICATION: should buckets > 1000 be rejected as well, or accepted with a warning?]
```

The `sphinx-build -W` self-validation will still pass — the marker lives inside the body, not in a link target. The `coverage.rst` page surfaces every need whose body contains `[NEEDS CLARIFICATION` so the user can answer them in a follow-up `/speckit.clarify` pass.

**Rule of thumb**: if you cannot point at a sentence in the user input that justifies a SHOULD/MUST, keep the question visible. Inventing a closed REQ that traces back to a user story still produces a confident-looking trace graph — and a graph of fabricated requirements is worse than an honest gap.

## Outline

The text the user typed after `/speckit.specify` is the feature description. Given that description:

1. **Generate a concise short name** (2-4 words). Examples in original prompt apply.

2. **Branch / feature directory creation** via `before_specify` hook (if registered). Same logic as MD mode — see `.specify/extensions.yml`.

3. **Create the spec feature directory** at `SPECIFY_FEATURE_DIRECTORY` and copy `spec-template.rst` to `SPEC_FILE = SPECIFY_FEATURE_DIRECTORY/spec.rst`. Persist `feature_directory` to `.specify/feature.json`.

4. **Load `templates/spec-template.rst`** to understand required sections.

5. **Fill the spec** following V-model semantics:

   a. **User stories** — emit one `.. user_story::` per journey. Use `US_<UPPER_FEATURE>_<NNN>` for IDs. Priority goes in the title; rationale and Acceptance Scenarios go in the body.

   b. **Functional requirements** — derive 5-12 `.. req::` directives from user stories. Each `:traces_to:` at least one US. Use `REQ_<UPPER_FEATURE>_<NNN>` IDs. Body is the normative MUST/SHOULD statement.

   c. **Risks (optional but encouraged)** — list domain, security, or UX risks as `.. risk::`. Each `:affects:` at least one REQ.

   d. **Decisions (optional)** — record requirement-level decisions as `.. decision::` with Context / Decision / Consequences body sections.

   e. **Acceptance tests** — emit at least one `.. test::` per user story with `:verifies: US_...`. Body is the end-to-end acceptance criterion (often distilling Given/When/Then into a single check).

6. **Write the spec** to `SPEC_FILE`, replacing every placeholder. Preserve exact section order from the template.

7. **Self-validate** by running:

   ```bash
   uv run --project <SPEC_KIT_ROOT> python -m sphinx -b needs -W . _build/needs
   ```

   from the project root. If the build fails:

   - Read the warning/error list (typically: missing `:traces_to:`, `:verifies:`, broken IDs, ID regex violations).
   - Fix each issue in `spec.rst`.
   - Re-run sphinx-build.
   - Loop maximum 3 times. After 3 failed iterations, report the remaining warnings in the completion message and let the user decide.

   Sphinx-build output is the structured oracle. Do NOT rely on grep or pattern matching for validation — the oracle is `sphinx-build -W`.

8. **Generate Spec Quality Checklist** at `SPECIFY_FEATURE_DIRECTORY/checklists/requirements.rst` using `templates/checklist-template.rst` structure. Validate the spec against it; if items fail, iterate up to 3 times.

9. **Preserve [NEEDS CLARIFICATION] markers in directive bodies.** Do NOT invent answers to close them. The `coverage.rst` page surfaces these needs in an "Open clarifications" table for the user to resolve via `/speckit.clarify` (interactive) or by editing the directive body directly. Up to 3 markers per spec; if more questions arise, batch the next round in a subsequent run.

10. **Report completion** with:
    - `SPECIFY_FEATURE_DIRECTORY`
    - `SPEC_FILE` (`spec.rst`)
    - Number of needs created (use `needs.json` count)
    - Self-validation result (PASS / WARNINGS REMAINING)
    - Readiness for `/speckit.clarify` or `/speckit.plan`.

11. **`after_specify` hooks** — same convention as MD mode.

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW (tech stack, APIs) — that's `/speckit.plan`.
- Author for non-technical stakeholders.
- Trace every requirement back to a user story; trace every user story to an acceptance test.
- Use stable, descriptive IDs (`REQ_AUTH_LOGIN_001` not `REQ_001`).

## ID Conventions

- US: `US_<DOMAIN>_<NNN>` — e.g. `US_AUTH_LOGIN_001`
- REQ: `REQ_<DOMAIN>_<NNN>` — e.g. `REQ_AUTH_VALIDATE_001`
- RISK: `RISK_<DOMAIN>_<NNN>` — e.g. `RISK_AUTH_TOKEN_LEAK_001`
- DEC: `DEC_<DOMAIN>_<NNN>` — e.g. `DEC_AUTH_USE_OAUTH_001`
- TC (acceptance): `TC_<DOMAIN>_ACC_<NNN>` — e.g. `TC_AUTH_ACC_001`

`<DOMAIN>` is a stable token tied to the feature, not a numeric prefix. Cross-feature references (`needimport`) rely on these being globally unique.

## For AI Generation

- Make informed guesses with industry standards for *implementation* details (e.g. error message format, log level).
- For *product* questions the user must answer (header handling, language choice, performance thresholds, public API contract): keep `[NEEDS CLARIFICATION]` markers, do not invent.
- Document non-obvious assumptions in the Assumptions bullet list — these are claims you'd happily defend in review.
- Maximum 3 [NEEDS CLARIFICATION] markers per artefact.
- Every requirement must be testable; if you can't write the acceptance test, the requirement is too vague.
- Self-validation via sphinx-build is the source of truth for *structural* soundness. It does NOT verify product correctness — open clarifications surface in `coverage.rst` for that.
