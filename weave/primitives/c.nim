# Weave
# Copyright (c) 2019 Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# Random
# ----------------------------------------------------------------------------------

proc rand_r*(seed: var uint32): int32 {.header: "<stdlib.h>".}
  ## Random number generator from C stdlib
  ## small amount of state
  ## TODO: replace by Nim's