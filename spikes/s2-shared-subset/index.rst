S2 shared-subset sample
=======================

A minimal corpus exercising every directive and role in the free/paid
shared subset documented in ``spec-kit-hypotheses.md``.

Requirements
------------

.. req:: Start engine on button press
   :id: REQ_START
   :status: open

   When the driver presses the start button, the vehicle enters the
   running state within 500ms.

.. req:: Stop engine on button press
   :id: REQ_STOP
   :status: open

   When the driver presses the stop button, the vehicle leaves the
   running state within 500ms.

Specifications
--------------

.. spec:: Ignition controller emits start signal
   :id: SPEC_IGN_START
   :status: in_progress
   :satisfies: REQ_START

   The ignition controller emits a ``START`` signal on the CAN bus when
   the start button is pressed.

.. spec:: Ignition controller emits stop signal
   :id: SPEC_IGN_STOP
   :status: in_progress
   :satisfies: REQ_STOP

   The ignition controller emits a ``STOP`` signal on the CAN bus when
   the stop button is pressed.

   :need_part:`(ack) Acknowledge receipt of the stop signal within 50ms.`

Test cases
----------

.. test:: Start button HIL test
   :id: TC_START_HIL
   :status: open
   :verifies: REQ_START

   Drive the start button input high on the HIL rig and assert that the
   running-state signal goes high within 500ms.

.. test:: Stop button HIL test
   :id: TC_STOP_HIL
   :status: open
   :verifies: REQ_STOP

   Drive the stop button input high on the HIL rig and assert that the
   running-state signal goes low within 500ms.

Metadata extension
------------------

.. needextend:: TC_START_HIL
   :status: done

Inline role audit
-----------------

The start requirement is :need:`REQ_START`.
Things that depend on REQ_START: :need_incoming:`REQ_START`.
Things REQ_START points at: :need_outgoing:`REQ_START`.
The acknowledgement part is :need:`SPEC_IGN_STOP.ack`.
