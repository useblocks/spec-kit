Project Trace Graph
===================

.. toctree::
   :maxdepth: 3
   :glob:

   specs/*/spec
   specs/*/plan
   specs/*/tasks


Coverage Matrix
===============

This page is rendered automatically by sphinx-needs from the source
artefacts in ``specs/<feature>/``. It surfaces gaps in the V-model
trace graph: requirements without tests, specifications without
implementing tasks, risks without mitigation, and decisions without
the architectural element they motivate.


Requirements without satisfying specs
-------------------------------------

.. needtable::
   :types: req
   :filter: not satisfies_back
   :columns: id;title;status;traces_to


User stories without acceptance tests
-------------------------------------

.. needtable::
   :types: user_story
   :filter: not verifies_back
   :columns: id;title;status


Specifications without satisfying requirements
----------------------------------------------

.. needtable::
   :types: spec
   :filter: not satisfies
   :columns: id;title;status


Specifications without implementing tasks
-----------------------------------------

.. needtable::
   :types: spec
   :filter: not implements_back
   :columns: id;title;status;satisfies


Tasks without verifying tests
-----------------------------

.. needtable::
   :types: task
   :filter: not verifies_back
   :columns: id;title;status;implements


Risks without mitigation
------------------------

.. needtable::
   :types: risk
   :filter: not mitigates_back
   :columns: id;title;status;affects


Decisions missing both spec motivation and story trace
------------------------------------------------------

Requirement-level decisions (spec.rst) may validly only ``:traces_to:`` a
user story. Forward-looking architectural decisions (plan.rst) typically
``:motivates:`` a SPEC. This table flags only decisions with neither
link, which are real coverage gaps.

.. needtable::
   :types: decision
   :filter: not motivates and not traces_to
   :columns: id;title;status


Needs with open clarifications
------------------------------

.. needtable::
   :types: user_story;req;spec;task;test;risk;decision
   :filter: "[NEEDS CLARIFICATION" in content
   :columns: id;type;title;status


Full traceability table (all needs)
-----------------------------------

.. needtable::
   :types: user_story;req;spec;task;test;risk;decision
   :columns: id;type;title;status;outgoing;incoming


Trace graph (visual)
--------------------

The diagram below renders the same trace graph visually. It needs a
diagram engine (Graphviz or PlantUML) at HTML build time; if neither is
available, sphinx-needs emits a warning and the table above remains
authoritative.

.. needflow::
   :types: user_story;req;spec;task;test;risk;decision
   :show_link_names:
   :align: center
