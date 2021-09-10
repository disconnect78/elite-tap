          ; Patch out Lenslok
          ; * The previous tap version patched $c22e to $18 which makes it pass the Lenslok check regardless of a right
          ;   or wrong response. This works fine but we're going to patch so it skips Lenslok entirely by ret'ing from
          ;   the "do Lenslok check" call.
          ld   a,$c9
          ld   ($c213),a

          ; Patches suggested by patters: https://spectrumcomputing.co.uk/forums/viewtopic.php?p=73719#p73719
          ; * Fix Viper encounter legal status check (ersh)
          ld   a,95
          ld   (42038),a
          ; * Fix traffic at stations, Vipers emerge if station attacked (tomas)
          ld   a,64
          ld   (24680),a
