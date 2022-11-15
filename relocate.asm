; Relocation stub
; 
; This is intended to be embedded in a small BASIC program. It includes our machine code loader and relocates it to the
; desired location.

reloc_destination equ $ffa9                  ; where we relocate to
reloc_length equ reloc_end - reloc_start     ; length of relocation stub
loader_length equ loader_end - loader_start  ; length of loader

reloc_start
          ; bc = start address of this code when called
          ; we need to get this into hl for our ldir
          push bc
          pop  hl

          ; set the copy destination, accounting for the length of the relocation stub
          ld   de,reloc_destination - reloc_length

          ; next we calculate the length to copy, which is basically relocation stub + loader
          ; (we could calculate this usual labels alone but this is more readable)
          ld   bc,reloc_length + loader_length

          ; copy loader (hl = source, de = destination, bc = bytes to copy)
          ldir

          ; jump to start of loader
          jp   reloc_destination
reloc_end

loader_start
          incbin "loader.bin"
loader_end
