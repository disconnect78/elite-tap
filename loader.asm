; Loader
;
; This loads the game data, applies some patches, then starts the game

loader_loc equ $ffa9               ; where our loader begins
game_dest equ $4000                ; location that game data should be loaded to
game_len equ $bfa9                 ; length of game data to be laoded
game_start equ $d079               ; start address of game

          org  loader_loc

          ; Initialise
          di
          ld   sp,$ffff

load
          ; Headerless load
          ld   ix,game_dest
          ld   de,game_len
          ld   a,$ff
          scf
          call $0556
          ; Try again on error
          jr   nc,load

          include "patches.asm"

          ; Wait for a key
          call $15de

          jp   game_start

          end  loader_loc
