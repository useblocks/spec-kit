---
description: Export tasks from tasks.rst to GitHub issues (one issue per task directive) and write back the issue URL into tasks.rst.
tools: ['github/github-mcp-server/issue_write']
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

RST mode. This command reads `tasks.rst` (produced by `/speckit.tasks`) and writes back to it after issue creation.

**Source** — `tasks.rst` contains `.. task::` directives:

```rst
.. task:: Short title
   :id: TASK_AUTH_IMPL_001
   :implements: SPEC_AUTH_001
   :status: open

   Body describing the work item.
```

**Target** — one GitHub issue per `.. task::` directive, created in the repository that matches the Git remote.

**Write-back** — after creation, the issue URL is recorded in `tasks.rst` using one of two mechanisms:

- **Option (a) — preferred** when `link_to_issue` is declared as a custom field in `ubproject.toml`:
  Add a `:link_to_issue: <url>` option to the directive.

- **Option (b) — fallback** when `link_to_issue` is not declared:
  Append a comment line inside the directive body:

  ```rst
  .. task:: Short title
     :id: TASK_AUTH_IMPL_001
     :implements: SPEC_AUTH_001
     :status: open

     Body describing the work item.

     .. GitHub issue: https://github.com/org/repo/issues/42
  ```

  sphinx-needs ignores RST comments inside directive bodies, so option (b) is always safe.

To detect which mechanism to use, check `ubproject.toml` for a `needs_extra_options` entry containing `link_to_issue`. If present, use (a); otherwise use (b).

## Pre-Execution Checks

**Check for extension hooks (before tasks-to-issues conversion)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_taskstoissues` key.
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

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

2. From the executed script, extract the path to `tasks.rst`.

3. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

4. Parse `tasks.rst` — collect every `.. task::` directive: its ID, title, body, and all options.

5. Check `ubproject.toml` for `link_to_issue` in `needs_extra_options` (determines write-back mechanism).

6. For each task directive, use the GitHub MCP server to create a new issue in the repository matching the Git remote. Issue content:
   - **Title**: the directive title (first argument after `.. task::`).
   - **Body**: the directive body, prefixed with a trace line: `Implements: <id>`.
   - **Labels** (if the repo has them): derive from `:status:` and phase implied by the ID (e.g. `IMPL`, `SETUP`, `POLISH`).

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL

7. After each issue is created, write back the URL into `tasks.rst` using the selected mechanism (a or b).

8. **Self-validate** with:

   ```bash
   sphinx-build -b needs -W . _build/needs
   ```

   - If option (a) was used and `link_to_issue` is not in `needs_extra_options`, sphinx-needs will warn about an unknown field. Either add it to `ubproject.toml` or switch to option (b) and re-run.
   - Max 3 iterations.

9. **Report**: total issues created, write-back mechanism used, validation result (PASS / WARNINGS REMAINING).

## Post-Execution Checks

**Check for extension hooks (after tasks-to-issues conversion)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_taskstoissues` key.
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
