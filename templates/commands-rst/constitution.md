---
description: Create or update the project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync.
handoffs:
  - label: Build Specification
    agent: speckit.specify
    prompt: Implement the feature specification based on the updated constitution. I want to build...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Output Format

This project is configured for RST output (see `.specify/config.toml` `format = "rst"`). The constitution is a project-principles document — it does NOT use sphinx-needs directives. When writing the constitution file, you MUST:

- Use reStructuredText syntax throughout: section underlines, bullet lists, field lists.
- Structure principles as RST sub-sections (underline with `~~~`).
- Group related sections under top-level RST sections (underline with `---`).
- Use field lists (`:Version:`, `:Ratified:`, `:Last Amended:`) for governance metadata at the bottom.
- Do NOT emit any sphinx-needs directives (`.. req::`, `.. user_story::`, `.. test::`, `.. risk::`, `.. decision::`, `.. needtable::`, `.. needflow::`, or similar).
- Do NOT emit any rendering directives. The constitution is plain prose and structured text only.

A docutils syntax check is acceptable but not required:
```bash
python -c "from docutils.core import publish_doctree; publish_doctree(open('.specify/memory/constitution.rst').read())"
```

## Pre-Execution Checks

**Check for extension hooks (before constitution update)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_constitution` key.
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

You are updating the project constitution at `.specify/memory/constitution.rst`. This file is an RST document containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`). Your job is to (a) collect or derive concrete values, (b) fill the template precisely, and (c) propagate any amendments across dependent artifacts.

**Note**: If `.specify/memory/constitution.rst` does not exist yet, it should have been initialized from `templates/constitution-template.rst` during project setup. If it is missing, copy the template first.

Follow this execution flow:

1. Load the existing constitution at `.specify/memory/constitution.rst`.
   - Identify every placeholder token of the form `[ALL_CAPS_IDENTIFIER]`.
   - **IMPORTANT**: The user may require fewer or more principles than the three in the template. Respect any stated count. Author as many principles as needed, each as an RST sub-section following the same `~~~` underline structure. Do not leave unused placeholder sections in the output.

2. Collect or derive values for placeholders:
   - If user input (conversation) supplies a value, use it.
   - Otherwise infer from existing repo context (README, docs, prior constitution versions if present).
   - For governance dates: `RATIFICATION_DATE` is the original adoption date (if unknown, ask or mark TODO); `LAST_AMENDED_DATE` is today if changes are made, otherwise keep the previous value.
   - `CONSTITUTION_VERSION` must increment according to semantic versioning rules:
     - MAJOR: Backward-incompatible governance or principle removals or redefinitions.
     - MINOR: New principle or section added, or materially expanded guidance.
     - PATCH: Clarifications, wording, typo fixes, non-semantic refinements.
   - If the version bump type is ambiguous, propose reasoning before finalizing.

3. Draft the updated constitution content in RST:
   - Replace every placeholder with concrete text. No bracketed tokens may remain unless the project has explicitly chosen to defer them — justify any deferrals in the Sync Impact Report.
   - Preserve the RST heading hierarchy from `templates/constitution-template.rst`.
   - Each Principle sub-section: a succinct name line (`~~~` underline), a paragraph or bullet list of non-negotiable rules, and an explicit rationale if not obvious.
   - The Governance section MUST list the amendment procedure, versioning policy, and compliance review expectations.
   - Principles MUST be declarative and testable. Replace "should" with MUST or SHOULD with explicit rationale where appropriate.

4. Consistency propagation checklist (active validations):
   - Read `templates/plan-template.rst` and ensure any "Constitution Check" or architectural constraints align with updated principles.
   - Read `templates/spec-template.rst` for scope and requirements alignment — update if the constitution adds or removes mandatory sections.
   - Read `templates/tasks-template.rst` and ensure task categorization reflects new or removed principle-driven task types (e.g., observability, versioning, testing discipline).
   - Read each command file in `templates/commands-rst/*.md` (including this one) to verify no outdated references remain.
   - Read any runtime guidance docs present (e.g., `README.md`, `docs/quickstart.md`). Update references to changed principles.

5. Produce a Sync Impact Report prepended as an RST comment block at the top of the constitution file after update:
   - Version change: old to new.
   - List of modified principles (old title to new title if renamed).
   - Added sections.
   - Removed sections.
   - Templates requiring updates (updated / pending) with file paths.
   - Follow-up TODOs if any placeholders were intentionally deferred.

   Use RST comment syntax:

   ```rst
   ..
      SYNC IMPACT REPORT
      Version: X.Y.Z -> A.B.C
      Modified principles: ...
      Added: ...
      Removed: ...
      Templates updated: ...
      Deferred: ...
   ```

6. Validation before final output:
   - No remaining unexplained bracket tokens.
   - Version line in the field list matches the Sync Impact Report.
   - Dates are in ISO format YYYY-MM-DD.
   - Principles are declarative, testable, and free of vague language.
   - RST heading underlines match the character count of the heading text exactly.

7. Write the completed constitution back to `.specify/memory/constitution.rst` (overwrite).

8. Output a final summary to the user with:
   - New version and bump rationale.
   - Any files flagged for manual follow-up.
   - Suggested commit message (e.g., `docs: amend constitution to vX.Y.Z (principle additions + governance update)`).

If the user supplies partial updates (e.g., only one principle revision), still perform validation and version decision steps.

If critical information is missing (e.g., ratification date truly unknown), insert `TODO(<FIELD_NAME>): explanation` and include it in the Sync Impact Report under deferred items.

Do not create a new template. Always operate on the existing `.specify/memory/constitution.rst` file.

## Formatting and Style

- Use RST section underlines exactly as in `templates/constitution-template.rst`:
  - Top-level sections: `---` underline.
  - Principle sub-sections: `~~~` underline.
- Wrap long rationale lines to keep readability (under 100 characters ideally), but do not introduce awkward mid-word breaks.
- Keep a single blank line between sections.
- Avoid trailing whitespace.
- RST underline length MUST match the heading text character count.

## Post-Execution Checks

**Check for extension hooks (after constitution update)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_constitution` key.
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
