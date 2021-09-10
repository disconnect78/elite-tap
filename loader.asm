loader_loc equ $ffa9               ; where our loader begins

          org  loader_loc

          ; Initialise
          di
          ld   sp,$ffff

load
          ; Headerless load $bfa9 bytes starting at $4000
          ld   ix,$4000
          ld   de,$bfa9
          ld   a,$ff
          scf
          call $0556
          ; Try again on error
          jr   nc,load

          include "patches.asm"

          ; Wait for a key
          call $15de

          ; Start game
          jp   $d079

          end  loader_loc
