# useblocks V-model RST preset

Switches every spec-kit core command (`/speckit.specify`, `/speckit.plan`,
`/speckit.tasks`, `/speckit.implement`, `/speckit.clarify`, `/speckit.analyze`,
`/speckit.checklist`, `/speckit.constitution`, `/speckit.taskstoissues`) to
emit reStructuredText artefacts with a complete sphinx-needs trace graph:

User Story → Functional Requirement → Architectural Specification → Implementation Task,
plus optional Risk and Decision records.

Every artefact is validated by `sphinx-build -b needs -W`. The build is the
oracle, not grep or regex. Open questions live as `[NEEDS CLARIFICATION]`
markers inside directive bodies (the build still passes), and the
`coverage.rst` page lists them for `/speckit.clarify` to resolve.

## Install

The preset is not yet listed in the default spec-kit preset catalog. Install from a local checkout of this repository:

```bash
specify init my-project --integration claude
cd my-project
specify preset add --dev path/to/spec-kit/presets/useblocks-vmodel
```

Once the preset is available in your active catalog (set via `SPECKIT_PRESET_CATALOG_URL` or a project-level `.specify/preset-catalogs.yml`), the `--dev` flag is no longer needed:

```bash
specify preset add useblocks-vmodel
```

## First run

The first command you invoke (typically `/speckit.specify` or
`/speckit.constitution`) detects missing scaffolding and runs the bootstrap
script idempotently:

```bash
bash .specify/presets/useblocks-vmodel/scripts/bash/bootstrap-vmodel.sh
```

PowerShell mirror:

```powershell
pwsh .specify/presets/useblocks-vmodel/scripts/powershell/bootstrap-vmodel.ps1
```

Bootstrap creates four files at the project root if they are missing:

- `ubproject.toml`: sphinx-needs schema, link types, ID regex, ubcode config
- `conf.py`: sphinx config wired to `needs_from_toml`
- `coverage.rst`: master document with `:glob:` toctree over `specs/*/`
- `.specify/config.toml`: `format = "rst"` flag consumed by command prompts

Existing files are left untouched. Bootstrap is safe to re-run.

## Workflow

```text
/speckit.constitution     # optional: project principles → .specify/memory/constitution.rst
/speckit.specify <desc>   # → specs/<feature>/spec.rst with US/REQ/RISK/TC
/speckit.clarify          # optional: resolve [NEEDS CLARIFICATION] markers
/speckit.plan <stack>     # → specs/<feature>/plan.rst with SPEC/DEC + ancillary docs
/speckit.tasks            # → specs/<feature>/tasks.rst with TASK directives
/speckit.implement        # execute tasks while preserving trace links
/speckit.analyze          # cross-artefact consistency report
```

After each command, `sphinx-build -b needs -W` is the source of truth for
structural completeness. The agent re-runs the build until it is green or
hits the iteration cap (typically 3 attempts).

## ID conventions

- `US_<DOMAIN>_<NNN>`: User Story
- `REQ_<DOMAIN>_<NNN>`: Functional Requirement
- `SPEC_<DOMAIN>_<NNN>`: Architectural Specification
- `TASK_<DOMAIN>_<PHASE>_<NNN>`: Implementation Task (for example, `TASK_AUTH_IMPL_001`)
- `TC_<DOMAIN>_<KIND>_<NNN>`: Test Case (`KIND` ∈ `ACC`, `SYS`, `INT`, `UNIT`)
- `RISK_<DOMAIN>_<NNN>`: Risk
- `DEC_<DOMAIN>_<NNN>`: Decision

ID regex enforced in `ubproject.toml`:
`^[A-Z]+_[A-Z][A-Z0-9_]*$` (digits cannot follow the first underscore).

## Trace link types

| Outgoing | Back-link | Direction |
|---|---|---|
| `:traces_to:` | `:traces_from:` | REQ → US, DEC → US |
| `:satisfies:` | `:satisfied_by:` | SPEC → REQ |
| `:implements:` | `:implemented_by:` | TASK → SPEC |
| `:verifies:` | `:verified_by:` | TC → US, TC → SPEC, TC → TASK |
| `:affects:` | `:affected_by:` | RISK → REQ/SPEC/TASK |
| `:motivates:` | `:motivated_by:` | DEC → SPEC |
| `:mitigates:` | `:mitigated_by:` | SPEC/TASK/DEC → RISK |

## Layout

```
.specify/presets/useblocks-vmodel/
├── preset.yml                       # 9 command overrides, replaces: speckit.*
├── commands/                        # AI prompts (one per replaced command)
├── templates/                       # per-feature RST scaffolds
├── scaffold/                        # project-root files copied by bootstrap
└── scripts/
    ├── bash/bootstrap-vmodel.sh
    └── powershell/bootstrap-vmodel.ps1
```

## Compatibility

- spec-kit `>=0.8.0` (preset composition strategies)
- sphinx-needs `>=2.0`
- Python `>=3.10` (sphinx-needs requirement)

## License

MIT
