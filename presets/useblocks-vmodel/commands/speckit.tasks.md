---
description: Generate implementation tasks linked to architectural specifications, with verifying integration and unit tests.
handoffs:
  - label: Implement Tasks
    agent: speckit.implement
    prompt: Implement the tasks
    send: true
---

## User Input

```text
$ARGUMENTS
```

## Output Format

RST mode. `tasks.rst` contains:

- `.. task::` directives — one per implementation work item. Each `:implements: SPEC_...` from plan.rst.
- `.. test::` directives — integration TCs `:verifies: SPEC_...`, unit TCs `:verifies: TASK_...`.

Allowed directives/roles: same shared subset.

## Outline

1. **Load context**:
   - `SPEC_FILE = feature_directory/spec.rst` → enumerate REQs
   - `IMPL_PLAN = feature_directory/plan.rst` → enumerate SPECs and Decisions

2. **Generate tasks**:
   - For each SPEC, identify the implementation work needed (models, services, endpoints, etc.).
   - Emit one `.. task::` per work item with `:id: TASK_<DOMAIN>_<PHASE>_<NNN>`, `:implements: SPEC_...`.
   - Group tasks by Phase (Setup, Implementation, Tests, Polish) using RST section headings.

3. **Generate tests**:
   - For each SPEC, emit at least one integration `.. test::` `:verifies: SPEC_...` with `:id: TC_<DOMAIN>_INT_<NNN>`.
   - For each TASK, emit at least one unit `.. test::` `:verifies: TASK_...` with `:id: TC_<DOMAIN>_UNIT_<NNN>`.
   - Test bodies describe the assertion / scenario.

4. **Write to** `feature_directory/tasks.rst` from `.specify/presets/useblocks-vmodel/templates/tasks-template.rst`.

5. **Self-validate** with `sphinx-build -b needs -W . _build/needs`. Common errors:
   - `TASK_X :implements: SPEC_Y but SPEC_Y not found` → SPEC ID typo
   - `TASK_X has no incoming verified_by` → missing unit test
   - `SPEC_Y has no incoming implemented_by` → SPEC has no implementing TASK
   Fix and loop max 3 iterations.

   **Honest unknowns**: same rule as `/speckit.specify` and `/speckit.plan`. If a TASK depends on a yet-unmade product or design decision, embed `[NEEDS CLARIFICATION: <question>]` inside the task body. Do not invent a TASK that implements a fabricated SPEC.

6. **Status convention**: every task starts at `:status: open`. The implementer (`/speckit.implement`) flips to `done` either via in-place edit or `.. needextend:: TASK_X\n   :status: done` block at the bottom.

7. **Report**: tasks.rst path, total tasks/tests, validation result.

## ID conventions

- TASK: `TASK_<DOMAIN>_<PHASE>_<NNN>` — e.g. `TASK_AUTH_IMPL_001`, `TASK_AUTH_SETUP_002`, `TASK_AUTH_POLISH_001`
- TC integration: `TC_<DOMAIN>_INT_<NNN>`
- TC unit: `TC_<DOMAIN>_UNIT_<NNN>`

## Notes

- Phase grouping is presentation only — sphinx-needs treats all tasks equivalently. Phase boundaries aid the implementer.
- Don't link tasks to user stories directly. The chain is `TASK :implements: SPEC :satisfies: REQ :traces_to: US`. sphinx-needs resolves the transitive trace via incoming back-links.
- Polish tasks (TASK_<DOMAIN>_POLISH_*) :implements: a SPEC like any other. If polish work isn't tied to a SPEC, lift it into the plan first.
