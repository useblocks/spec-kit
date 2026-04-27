.. V-model task list template. Implementation tasks with verifying tests.

Tasks: [FEATURE NAME]
=====================

:Input: Design documents from ``/specs/[###-feature-name]/``
:Prerequisites: ``plan.rst`` (required), ``spec.rst`` (required)


Phase 1: Setup
--------------

.. task:: [Create project structure per implementation plan]
   :id: TASK_PLACEHOLDER_SETUP_001
   :status: open
   :implements: SPEC_PLACEHOLDER_001

   Create project structure per the implementation plan.

.. task:: [Initialise dependencies]
   :id: TASK_PLACEHOLDER_SETUP_002
   :status: open
   :implements: SPEC_PLACEHOLDER_001

   Initialise [language] project with [framework] dependencies.


Phase 2: Implementation
-----------------------

..
   ACTION REQUIRED: each implementation work item is a ``.. task::``
   that :implements: a SPEC from plan.rst. Replace the placeholders
   below with the actual list.

.. task:: [Implement OAuth flow controller]
   :id: TASK_PLACEHOLDER_IMPL_001
   :status: open
   :implements: SPEC_PLACEHOLDER_001

   [Describe the implementation work, including target files.]


Phase 3: Tests
--------------

..
   ACTION REQUIRED: every TASK must have at least one verifying TC.
   Integration tests verify SPECs at the component boundary;
   unit tests verify TASK-level units.

.. test:: [Integration test for SPEC_PLACEHOLDER_001]
   :id: TC_PLACEHOLDER_INT_001
   :status: open
   :verifies: SPEC_PLACEHOLDER_001

   [Integration scenario: how the component is exercised.]

.. test:: [Unit test for TASK_PLACEHOLDER_IMPL_001]
   :id: TC_PLACEHOLDER_UNIT_001
   :status: open
   :verifies: TASK_PLACEHOLDER_IMPL_001

   [Unit-level assertion: function signature and edge case.]


Phase N: Polish & Cross-Cutting Concerns
-----------------------------------------

..
   ACTION REQUIRED (optional): improvements that touch multiple stories.

.. task:: [Documentation updates]
   :id: TASK_PLACEHOLDER_POLISH_001
   :status: open
   :implements: SPEC_PLACEHOLDER_001

   Update docs/ for the new feature.


Dependencies
------------

* **Setup** (Phase 1): no dependencies.
* **Implementation** (Phase 2): blocked by Setup.
* **Tests** (Phase 3): blocked by Implementation.
* **Polish** (Phase N): blocked by all preceding phases.


Notes
-----

* Each task carries an explicit ``:implements:`` link so the trace graph
  closes (USER_STORY → REQ → SPEC → TASK).
* Each task has at least one verifying test, either integration or unit.
* Status updates: change ``:status: open`` to ``:status: done`` in place,
  or append a ``.. needextend:: TASK_X\n   :status: done`` block at the
  bottom of the file.
