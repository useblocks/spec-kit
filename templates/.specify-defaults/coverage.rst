Coverage Matrix
===============

This page is rendered automatically by sphinx-needs from the source
artefacts in ``specs/<feature>/``. It surfaces gaps in the V-model
trace graph: requirements without tests, specifications without
implementing tasks, risks without mitigation, and decisions without
the architectural element they motivate.


Requirements without verifying tests
------------------------------------

.. needtable::
   :types: req
   :filter: not satisfied_by
   :columns: id;title;status;traces_to


User stories without acceptance tests
-------------------------------------

.. needtable::
   :types: user_story
   :filter: not verified_by
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
   :filter: not implemented_by
   :columns: id;title;status;satisfies


Tasks without verifying tests
-----------------------------

.. needtable::
   :types: task
   :filter: not verified_by
   :columns: id;title;status;implements


Risks without mitigation
------------------------

.. needtable::
   :types: risk
   :filter: not mitigated_by
   :columns: id;title;status;affects


Decisions without motivated specifications
------------------------------------------

.. needtable::
   :types: decision
   :filter: not motivates
   :columns: id;title;status


Full traceability table (all needs)
-----------------------------------

.. needtable::
   :types: user_story;req;spec;task;test;risk;decision
   :columns: id;type;title;status;outgoing;incoming
