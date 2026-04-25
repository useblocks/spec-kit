# RST + sphinx-needs output format (V-model mode)

> **Status:** opt-in preview. Default remains Markdown.

## What you get

When you opt into `format = "rst"`, spec-kit becomes a generator of a
complete V-model trace graph instead of flat Markdown bullet lists:

| Layer                       | Source       | sphinx-needs directive | Verifying test side             |
|-----------------------------|--------------|------------------------|---------------------------------|
| User Story                  | `spec.rst`   | `.. user_story::`      | `.. test::` (acceptance)        |
| Functional Requirement      | `spec.rst`   | `.. req::`             | acceptance TC verifies the US   |
| Architectural Specification | `plan.rst`   | `.. spec::`            | `.. test::` (system)            |
| Implementation Task         | `tasks.rst`  | `.. task::`            | `.. test::` (integration, unit) |

Plus risk and decision (ADR) directives with their own link types, and a
`coverage.rst` page that surfaces gaps via auto-rendered
`.. needtable::`.

## Link types

The forward links connect every layer:

| Outgoing link  | Source type → target type     | Meaning                          |
|----------------|-------------------------------|----------------------------------|
| `:traces_to:`  | REQ → US, DEC → US            | "is motivated by"                |
| `:satisfies:`  | SPEC → REQ                    | "implements the requirement"     |
| `:implements:` | TASK → SPEC                   | "delivers the specification"     |
| `:verifies:`   | TC → US / SPEC / TASK         | "asserts the parent's contract"  |
| `:affects:`    | RISK → REQ / SPEC / TASK      | "puts this thing at risk"        |
| `:motivates:`  | DEC → SPEC                    | "is the rationale for the spec"  |
| `:mitigates:`  | SPEC / TASK → RISK            | "reduces the risk"               |

Each link type also has a sphinx-needs back-link field
(`<linkname>_back`, e.g. `verifies_back`) that lets you query the graph
in the reverse direction — for example, to find all tests that verify
a given user story, filter by `verifies_back`.

## When to use

- You need machine-checkable consistency (every requirement has a test,
  every spec has an implementing task).
- You want a queryable trace graph for downstream tooling (audits,
  coverage matrices, change-impact analysis).
- You work in a domain (automotive, medical, aerospace) where
  ISO 26262 / IEC 62304 / DO-178 ask for explicit trace links.

Stay on the default (`md`) for casual / exploratory projects.

## Enabling

### New project

```bash
specify init --format rst
```

This scaffolds:

- `.specify/config.toml` with `format = "rst"`
- `ubproject.toml` (sphinx-needs config: 7 directive types, 7 link types)
- `conf.py` (Sphinx config)
- `coverage.rst` (auto-rendered V-model coverage page)

### Existing project

Edit `.specify/config.toml`:

```toml
format = "rst"
```

Convert existing `.md` artefacts to `.rst` manually.

### One-shot override

```bash
SPECIFY_FORMAT=rst /speckit.specify "your feature"
```

## Self-validation

Slash commands (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`)
self-validate by running:

```bash
sphinx-build -b needs -W . _build/needs
```

The build fails if:

- a `:satisfies:` / `:traces_to:` / etc. references an unknown ID
- a directive lacks a required link (e.g. REQ without `:traces_to:`)
- an ID violates regex `^[A-Z]+_[A-Z][A-Z0-9_]*$`
- a `:status:` value is outside the schema enum

The agent fixes each error and re-runs, max 3 iterations.

## Coverage matrix

`coverage.rst` is rendered automatically on `sphinx-build -b html`.
Sections:

- Requirements without verifying tests
- User stories without acceptance tests
- Specifications without satisfying requirements
- Specifications without implementing tasks
- Tasks without verifying tests
- Risks without mitigation
- Decisions without motivated specifications
- **Needs with open clarifications** — every directive whose body still contains `[NEEDS CLARIFICATION: ...]`
- Full traceability table

Open `_build/html/coverage.html` to read.

## Honest unknowns: `[NEEDS CLARIFICATION]`

The slash-command prompts instruct the agent to embed
`[NEEDS CLARIFICATION: <question>]` inside a directive body whenever the
input is silent on a product question that requires user judgement (header
row handling, language choice, performance thresholds, public API contract).

`sphinx-build -W` still passes — the marker lives in body text, not in a
link target. The "Needs with open clarifications" section in `coverage.rst`
surfaces every need that still carries one, so the user can resolve them
in a follow-up `/speckit.clarify` round (or by editing the directive body
directly).

This trades autonomy for honesty: the V-model trace graph closes, but
visibly invented requirements are not allowed to dress themselves up as
confident decisions. If you would prefer the agent to make a guess and
move on, you can edit the prompt under `.claude/skills/speckit-specify/SKILL.md`
to soften the rule.

## Cross-feature reuse with `needimport`

A second feature can reference requirements from a first:

```rst
.. needimport:: ../001-auth/_build/needs/needs.json
   :hide:

.. spec:: Audit log component
   :id: SPEC_AUDIT_LOG_001
   :satisfies: REQ_AUTH_TOK_001

   ...
```

Pre-condition: feature `001-auth` must have been built first
(`sphinx-build -b needs` from its directory).

## ID conventions

- `US_<DOMAIN>_<NNN>` — user story
- `REQ_<DOMAIN>_<NNN>` — functional requirement
- `SPEC_<DOMAIN>_<NNN>` — architectural specification
- `TASK_<DOMAIN>_<PHASE>_<NNN>` — implementation task
- `TC_<DOMAIN>_<KIND>_<NNN>` — test case (KIND ∈ ACC, SYS, INT, UNIT)
- `RISK_<DOMAIN>_<NNN>` — risk
- `DEC_<DOMAIN>_<NNN>` — decision (ADR)

`<DOMAIN>` is a stable token for the feature. It must be globally
unique across the project (cross-feature references rely on this).

## Reverting

```toml
# in .specify/config.toml
format = "md"
```

Existing `.rst` artefacts stay on disk; new features will be created
as `.md`.
