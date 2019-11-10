# Project Picasso
# Copyright (c) 2019 Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes/[victims_bitsets, sync_types, context_thread_local, bounded_queues],
  ./runtime,
  ./instrumentation/[contracts, profilers, loggers],
  ./channels/channels_mpsc_bounded_lock,
  ./memory/[intrusive_stacks, object_pool],
  ./static_config,
  ./thieves

# Worker
# ----------------------------------------------------------------------------------

proc recv(req: var StealRequest): bool {.inline.} =
  ## Check the worker theft channel
  ## for thieves.
  ##
  ## Updates req and returns true if a StealRequest was found

  profile(send_recv_req):
    result = globalCtx.com.thievingChannels[localCtx.worker.ID].tryRecv(req)

    # We treat specially the case where children fail to steal
    # and defer to the current worker (their parent)
    while result and req.state == Waiting:
      debugTermination:
        log("Worker %d receives STATE_FAILED from worker %d\n",
            localCtx.worker.ID, req.thiefID)

      # Only children can forward a request where they sleep
      ascertain: req.thiefID == localCtx.worker.left or
                 req.thiefID == localCtx.worker.right
      if req.thiefID == localCtx.worker.left:
        ascertain: not localCtx.worker.isLeftIdle
        localCtx.worker.isLeftIdle = true
      else:
        ascertain: not localCtx.worker.isRightIdle
        localCtx.worker.isRightIdle = true
      # The child is now passive (work-sharing/sender-initiated/push)
      # instead of actively stealing (receiver-initiated/pull)
      # We keep its steal request for when we have more work.
      # while it backs off to save CPU
      localCtx.worker.workSharingRequests.enqueue(req)
      # Check the next steal request
      result = globalCtx.com.thievingChannels[localCtx.worker.ID].tryRecv(req)

  postCondition: not result or (result and req.state != Waiting)