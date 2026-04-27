Implementation Plan: [FEATURE]
==============================

:Branch: ``[###-feature-name]``
:Date: [DATE]
:Spec: [link]
:Input: Feature specification from ``/specs/[###-feature-name]/spec.rst``

..
   This template is filled in by the ``/speckit.plan`` command.
   It captures architectural and detailed-design decisions that
   :satisfies: the requirements authored in spec.rst.


Summary
-------

[Extract from feature spec: primary requirement + technical approach.]


Technical Context
-----------------

:Language/Version: [e.g., Python 3.11]
:Primary Dependencies: [e.g., FastAPI]
:Storage: [if applicable]
:Testing: [e.g., pytest]
:Target Platform: [e.g., Linux server]
:Project Type: [e.g., web-service]
:Performance Goals: [domain-specific]
:Constraints: [domain-specific]
:Scale/Scope: [domain-specific]


Architectural Specifications
----------------------------

..
   ACTION REQUIRED: each architectural component, interface, or
   non-functional commitment is a ``.. spec::`` directive with
   :satisfies: linking to one or more REQ from spec.rst.

.. spec:: [Component or design decision title]
   :id: SPEC_PLACEHOLDER_001
   :status: open
   :satisfies: REQ_PLACEHOLDER_001

   [Describe the architectural element. What it does, what it owns,
   how it interacts with neighbours.]


Decisions (ADR)
---------------

..
   ACTION REQUIRED: capture architectural decisions with rationale.
   Each ``.. decision::`` :motivates: one or more SPEC.

.. decision:: [Decision title — e.g. "Use JWT for session tokens"]
   :id: DEC_PLACEHOLDER_001
   :status: open
   :motivates: SPEC_PLACEHOLDER_001

   **Context**: [Forces in play, problem statement]

   **Decision**: [What was chosen]

   **Consequences**: [Trade-offs and downstream effects]


Design Risks (optional)
-----------------------

..
   ACTION REQUIRED (optional): risks identified during architectural
   design. Distinct from spec-level risks (those go in spec.rst).
   Each ``.. risk::`` :affects: a SPEC and ideally is mitigated by
   a different SPEC or a future TASK using ``:mitigates: RISK_...``
   on the mitigating need.

.. risk:: [Design-level risk title]
   :id: RISK_PLACEHOLDER_010
   :status: open
   :affects: SPEC_PLACEHOLDER_001

   [Describe the design risk and any mitigation strategy.]


System Tests
------------

..
   ACTION REQUIRED: each architectural specification must have at
   least one ``.. test::`` that :verifies: it. System tests assert
   the SPEC's contract end-to-end at the integration boundary.

.. test:: [System test title]
   :id: TC_PLACEHOLDER_SYS_001
   :status: open
   :verifies: SPEC_PLACEHOLDER_001

   [Description of the system-level scenario the test validates.]


Project Structure
-----------------

.. code-block:: text

   specs/[###-feature]/
   ├── plan.rst              # This file
   ├── research.rst          # Phase 0 output
   ├── data-model.rst        # Phase 1 output
   ├── quickstart.rst        # Phase 1 output
   └── contracts/            # Phase 1 output

**Source structure**: [Document the selected source-tree layout.]


Complexity Tracking
-------------------

..
   ACTION REQUIRED (only if Constitution Check has violations):
   each row is a justified complexity introduction.

+--------------------+------------------+----------------------------+
| Violation          | Why Needed       | Simpler Alternative        |
|                    |                  | Rejected Because           |
+====================+==================+============================+
| [e.g., 4th project]| [current need]   | [why 3 insufficient]       |
+--------------------+------------------+----------------------------+
