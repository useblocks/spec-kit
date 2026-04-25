---
description: Execute the implementation plan by processing all open tasks defined in tasks.rst, tracking status per task via in-place edits or needextend blocks.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Output Format

RST mode. This command does **not** emit a new artefact — it **consumes** `tasks.rst`.

`tasks.rst` was authored by `/speckit.tasks`. It contains:

- `.. task::` directives with `:status: open` — work items awaiting implementation.
- `.. test::` directives — unit and integration TCs linked to tasks and specs.

As each task is completed, update its status using one of two accepted mechanisms:

**In-place edit** — change the field directly inside the directive:

```rst
.. task:: Short title
   :id: TASK_AUTH_IMPL_001
   :status: done
   :implements: SPEC_AUTH_001
```

**Append `.. needextend::` block** at the bottom of `tasks.rst`:

```rst
.. needextend:: TASK_AUTH_IMPL_001
   :status: done
```

Both mechanisms are valid. The `needextend` approach leaves the original directive untouched (better for audit trails). In-place editing is simpler when tasks are completed one by one.

Do not mix both for the same task ID — pick one and use it consistently within a session.

## Pre-Execution Checks

**Check for extension hooks (before implementation)**:

- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_implement` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue.
- Filter out hooks where `enabled` is explicitly `false`. Hooks without an `enabled` field are treated as enabled.
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

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory.
   - For each checklist count total items (`- [ ]` / `- [X]`), completed items (`- [X]`), and incomplete items (`- [ ]`).
   - Create a status table:

     ```text
     | Checklist        | Total | Completed | Incomplete | Status |
     |------------------|-------|-----------|------------|--------|
     | requirements.rst | 12    | 12        | 0          | PASS   |
     | security.rst     | 6     | 4         | 2          | FAIL   |
     ```

   - **If any checklist is incomplete**: display the table, then ask:
     "Some checklists are incomplete. Proceed with implementation anyway? (yes/no)"
     Wait for user response. If "no" / "wait" / "stop" — halt. If "yes" / "proceed" — continue to step 3.
   - **If all checklists are complete**: display the table and proceed automatically.

3. **Load implementation context**:
   - **REQUIRED**: Read `tasks.rst` for the complete task list (all `.. task::` and `.. test::` directives).
   - **REQUIRED**: Read `plan.rst` for tech stack, architecture, and file structure.
   - **IF EXISTS**: Read `spec.rst` for the requirement and user-story trace chain.
   - **IF EXISTS**: `data-model.rst` — entities and relationships.
   - **IF EXISTS**: `contracts/` — API specifications and test requirements.
   - **IF EXISTS**: `research.rst` — technical decisions and constraints.
   - **IF EXISTS**: `quickstart.rst` — integration scenarios.

4. **Project setup verification** — create or verify ignore files based on the detected project stack:

   - Check `git rev-parse --git-dir 2>/dev/null` → create/verify `.gitignore` if in a git repo.
   - Check for `Dockerfile*` or Docker in `plan.rst` → create/verify `.dockerignore`.
   - Check for `.eslintrc*` → create/verify `.eslintignore`.
   - Check for `eslint.config.*` → ensure the config's `ignores` entries cover required patterns.
   - Check for `.prettierrc*` → create/verify `.prettierignore`.
   - Check for `.npmrc` or `package.json` → create/verify `.npmignore` (if publishing).
   - Check for `*.tf` files → create/verify `.terraformignore`.
   - Check for Helm charts → create/verify `.helmignore`.

   If an ignore file exists: append only missing critical patterns.
   If it is absent: create with the full pattern set for the detected technology.

5. **Parse `tasks.rst`** and extract:
   - Task phases: Setup, Implementation, Tests, Polish (from RST section headings).
   - Task IDs (`TASK_<DOMAIN>_<PHASE>_<NNN>`) and their `:status:` fields.
   - Dependencies implied by phase order: Setup must finish before Implementation; Tests run before Polish.
   - Parallel markers in the directive body (e.g. `[P]`) where present.
   - Open tasks only: collect all directives where `:status: open`.

6. **Execute implementation following the task plan**:
   - **Phase-by-phase**: complete each phase before moving to the next.
   - **Respect dependencies**: sequential tasks in order; parallel tasks `[P]` may run concurrently.
   - **TDD order**: if test tasks exist alongside implementation tasks in the same phase, write tests first.
   - **File coordination**: tasks that write to the same file must run sequentially.
   - **Validation checkpoints**: verify each phase is complete before proceeding to the next.

7. **Implementation phase rules**:
   - **Setup first**: initialise project structure, dependencies, configuration files.
   - **Tests before code**: write tests for contracts, entities, and integration scenarios before their implementations.
   - **Core development**: implement models, services, CLI commands, endpoints as described in each `.. task::` body.
   - **Integration work**: database connections, middleware, logging, external services.
   - **Polish and validation**: performance optimisation, inline documentation, cleanup.

8. **Progress tracking and status updates**:
   - After completing each task, immediately update its `:status:` in `tasks.rst` via in-place edit **or** a `.. needextend::` block (choose one approach per session and stay consistent).
   - Report progress after each completed task.
   - Halt execution if any non-parallel task fails.
   - For parallel tasks `[P]`, continue with successful tasks and report failed ones separately.
   - Provide error messages with enough context for debugging.
   - If implementation cannot proceed, suggest the next step (e.g. re-run `/speckit.tasks` to regenerate the task list).

9. **Self-validation after each phase batch**:

   Run:

   ```bash
   sphinx-build -b needs -W . _build/needs
   ```

   from the project root after completing each phase. If a status update introduced an inconsistency (typically a typo'd need ID in a `.. needextend::` block), fix the directive and re-run. Maximum 3 iterations per phase.

   Common errors:
   - `TASK_X :implements: SPEC_Y but SPEC_Y not found` → SPEC ID typo in `tasks.rst`
   - `needextend target TASK_X not found` → task ID in `.. needextend::` does not match any directive

10. **Completion validation**:
    - Verify all `.. task::` directives that were `:status: open` at the start are now `:status: done`.
    - Check that implemented features match the original specification in `spec.rst`.
    - Confirm tests pass and coverage meets the requirements described in TCs.
    - Confirm the implementation follows the technical decisions in `plan.rst`.
    - Run a final `sphinx-build -b needs -W . _build/needs` to confirm the full need graph is consistent.
    - Report final status with a summary of completed tasks, any skipped tasks, and any remaining warnings.

Note: This command requires a complete task breakdown in `tasks.rst`. If tasks are incomplete or missing, run `/speckit.tasks` first to generate the task list.

11. **Check for extension hooks (after completion validation)**:
    - Check if `.specify/extensions.yml` exists in the project root.
    - If it exists, read it and look for entries under the `hooks.after_implement` key.
    - If the YAML cannot be parsed or is invalid, skip hook checking silently and continue.
    - Filter out hooks where `enabled` is explicitly `false`. Hooks without an `enabled` field are treated as enabled.
    - For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
      - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
      - If the hook defines a non-empty `condition`, skip and leave condition evaluation to the HookExecutor implementation.
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
