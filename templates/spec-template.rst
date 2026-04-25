Feature Specification: [FEATURE NAME]
======================================

:Feature Branch: ``[###-feature-name]``
:Created: [DATE]
:Status: Draft
:Input: User description: "$ARGUMENTS"


User Stories
------------

..
   ACTION REQUIRED: replace the example below with one user story per
   numbered ``.. user_story::`` directive. Priorities P1/P2/P3 go in the
   directive title; the body holds the journey description; nested
   field lists capture acceptance scenarios (Given/When/Then).

.. user_story:: [Brief Title — Priority P1]
   :id: US_PLACEHOLDER_001
   :status: open

   [Describe this user journey in plain language, one paragraph.]

   :Why: [Why this priority]
   :Independent test: [How to verify on its own]

   **Acceptance Scenarios**:

   1. **Given** [initial state], **When** [action], **Then** [outcome]
   2. **Given** [initial state], **When** [action], **Then** [outcome]


Functional Requirements
-----------------------

..
   ACTION REQUIRED: each requirement is a ``.. req::`` directive that
   :traces_to: at least one US_PLACEHOLDER_NNN above. The body is the
   normative requirement statement.

.. req:: [Allow users to create accounts]
   :id: REQ_PLACEHOLDER_001
   :status: open
   :traces_to: US_PLACEHOLDER_001

   System MUST [allow users to create accounts]

.. req:: [Validate email addresses]
   :id: REQ_PLACEHOLDER_002
   :status: open
   :traces_to: US_PLACEHOLDER_001

   System MUST [validate email addresses]


Risks (optional)
----------------

..
   ACTION REQUIRED (optional): identify domain, security, or UX risks.
   Each ``.. risk::`` :affects: one or more REQ. Skip the section if
   no significant risks are identified.

.. risk:: [Brief risk title]
   :id: RISK_PLACEHOLDER_001
   :status: open
   :affects: REQ_PLACEHOLDER_001

   [Describe the risk and its potential impact.]


Decisions (optional)
--------------------

..
   ACTION REQUIRED (optional): record requirement-level decisions (ADRs).
   Each ``.. decision::`` may :traces_to: a US or :motivates: a future
   SPEC.

.. decision:: [Brief decision title]
   :id: DEC_PLACEHOLDER_001
   :status: open
   :traces_to: US_PLACEHOLDER_001

   **Context**: [Why a decision is needed]

   **Decision**: [What was decided]

   **Consequences**: [Trade-offs accepted]


Acceptance Tests
----------------

..
   ACTION REQUIRED: each user story above must have at least one
   acceptance test that :verifies: it. Test bodies describe the
   end-to-end pass criterion.

.. test:: [Acceptance test title]
   :id: TC_PLACEHOLDER_ACC_001
   :status: open
   :verifies: US_PLACEHOLDER_001

   [Test description: how to validate the user story end-to-end.]


Key Entities
------------

..
   ACTION REQUIRED (optional): name data entities. Plain RST bullet
   list — entities are not sphinx-needs items.

* **[Entity 1]**: [What it represents, key attributes]
* **[Entity 2]**: [What it represents, relationships]


Success Criteria
----------------

..
   ACTION REQUIRED: measurable, technology-agnostic outcomes. Plain
   RST bullet list — these are project-level metrics, not need items.

* **SC-001**: [Measurable metric]
* **SC-002**: [Measurable metric]


Assumptions
-----------

* [Assumption about target users / scope / environment]
* [Dependency on existing system / service]
