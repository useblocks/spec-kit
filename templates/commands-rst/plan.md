---
description: Translate a feature specification into an architectural plan with traceable design decisions, system tests, and optional design risks.
handoffs:
  - label: Generate Tasks
    agent: speckit.tasks
    prompt: Generate the implementation tasks for this plan
    send: true
---

## User Input

```text
$ARGUMENTS
```

## Output Format

RST mode (see `.specify/config.toml`). Generated `plan.rst` contains:

- `.. spec::` directives — architectural specifications, each `:satisfies: REQ_...` from spec.rst.
- `.. decision::` directives — architectural decisions (ADRs), each `:motivates: SPEC_...`.
- `.. risk::` directives (optional) — design-level risks, each `:affects: SPEC_...`.
- `.. test::` directives — system tests, each `:verifies: SPEC_...`.

Allowed directives/roles: same shared subset as `/speckit.specify`. No rendering directives in plan.rst — coverage is in `coverage.rst`.

## Outline

1. **Load spec context**: read `SPEC_FILE` (= `feature_directory/spec.rst`). Extract all `REQ_*` IDs from `:id:` lines so you can link to them.

2. **Read constitution** at `.specify/memory/constitution.rst` (if present) for any architectural constraints.

3. **Phase 0 — research**: produce `research.rst` with sphinx-needs directives only if there are research-discovered facts that gate the design. Most features skip this.

4. **Phase 1 — design**:
   - Author `plan.rst` from `templates/plan-template.rst`.
   - Emit one or more `.. spec::` per architectural element. Each `:satisfies:` at least one REQ from spec.rst.
   - Emit `.. decision::` for non-trivial design choices (e.g. JWT vs session cookies, sync vs async API). Body has Context / Decision / Consequences.
   - Optional: `.. risk::` for design-level concerns (e.g. "OAuth redirect can leak token via Referer"). Each `:affects:` a SPEC.
   - Emit at least one `.. test::` (system test) per SPEC, `:verifies:` it.
   - Author `data-model.rst` (if data is involved): RST sections describing entities, relationships, schema. No sphinx-needs directives there — pure prose. Path references to spec/plan use `.rst`.
   - Author `quickstart.rst` (if a getting-started script makes sense): plain RST.

5. **Self-validate** with `sphinx-build -b needs -W . _build/needs` from the project root. Fix issues; loop max 3 iterations. Common errors:
   - `SPEC_X :satisfies: REQ_Y but REQ_Y not found` → REQ ID typo or missing in spec.rst
   - `SPEC_X has no incoming verified_by` → missing system test for the SPEC
   - `DEC_X has no :motivates:` → decision orphaned

   **Honest unknowns**: same rule as `/speckit.specify`. If a design question requires user input (build vs buy, sync vs async, hosted vs self-hosted) and you cannot defend a confident decision from the spec or constitution, embed `[NEEDS CLARIFICATION: <question>]` inside the relevant directive body rather than authoring a fabricated SPEC or DEC. The marker is body-text, sphinx-build still passes, and `coverage.rst` will surface the open question for the user.

6. **Update Project Structure** section in plan.rst with the actual chosen layout.

7. **Report completion**: paths to plan.rst, research.rst, data-model.rst, quickstart.rst (whichever were authored), need counts, validation result.

## ID conventions

- SPEC: `SPEC_<DOMAIN>_<NNN>`
- DEC: `DEC_<DOMAIN>_<NNN>`
- RISK: `RISK_<DOMAIN>_<NNN>` (continue numbering started in spec.rst)
- TC (system): `TC_<DOMAIN>_SYS_<NNN>`

## Quick Guidelines

- Architecture is described, not prescribed end-to-end. Capture decisions, not every implementation detail.
- One SPEC per architecturally significant element (component, API contract, data store).
- Decisions document trade-offs — if you can't write Consequences, the decision isn't worth recording yet.
- Risks should be actionable: a RISK without a mitigation strategy in a SPEC is a flag for the reviewer.
