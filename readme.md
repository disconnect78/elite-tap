# ELITE TAP CONVERTER

## Overview

This is a write-up of how I created a tap version of Elite (both the Krait and Adder versions) and steps to reproduce it. I'm running macOS so you may need to adjust some steps to suit if you're not. Even if you are, there are some things I may have already had installed that you don't (Homebrew, Python etc.); if any of the below doesn't work then you may need to figure this out for yourself I'm afraid!

For this conversion we will allow the game's Softlock protection to load and decrypt the game. We will dump the entire block of game data from `$4000` to `$ffa8`, then write a small machine code loader to load it back and patch out the Lenslok protection. We will compile the loader, embed it in a short BASIC program, then put together our final tap file.

## Prerequisites

You'll need a TZX copy of Elite. A valid version can be downloaded from the TZX Vault:
- http://www.tzxvault.org/Spectrum/TZX/Elite-48k.zip

You'll also need the following tools:

### Tomaz Kac's ZXTape utilities
The win32 versions don't compile under macOS but the Amiga versions will, so we use these:
- http://ftp.fau.de/aminet/misc/emu/tap2tzx-os4.lha
- http://ftp.fau.de/aminet/misc/emu/tzx2tap-os4.lha

```
gcc tzx2tap -o tzx2tap
gcc tap2tzx -o tap2tzx
cp tzx2tap /usr/local/bin
cp tap2tzx /usr/local/bin
```

### TZX Tools
- https://github.com/shred/tzxtools

I had to install `portaudio` before these would install:
```
brew install portaudio
pip3 install tzxtools
```

### Pasmo
- https://pasmo.speccy.org/

Download the gzipped tar file with sources, then build:

```
./configure
make
cp pasmo /usr/local/bin
```

### taptools
- http://www.seasip.info/ZX/unix.html

Download the gzipped tar file with sources, then build:

```
./configure
make
cp bin2bas /usr/local/bin
```
Note that we only copy `bin2bas` as this is all we use.

## Dumping the game data

To dump the data we will use Fuse emulator to load the game then save out the required data. Ideally, we would set a debugger breakpoint and dump the data when it triggers; unfortunately this isn't possible in macOS Fuse as the required menu option is greyed out when in the debugger. So we have to find another way to do it.

Start by opening the debugger and setting a breakpoint at $d05f, which we will reach once the game is loaded and decrypted:

```
br $d05f
```

Load the game from tape and wait until we hit the breakpoint. Now we need to patch in an infinite loop; when we hit this, we can dump the game data at our leisure:

```
se $d079 $18
se $d07a $fe
```

Exit the debugger and almost immediately we should hit the loop. Use the `Export Binary Data` menu option to export the data to a file with the start address `16384` and length `49065`. Copy it into the working directory (ie. this one). We're going to create taps of both the A-side and B-side of the tape, so do this for both versions, exporting files `eilte48_a.bin` and `elite48_b.bin` as appropriate.

Finally, we patch our loop back to the original bytes. The original location was `$d079` but we saved memory from start address `16384`, ie. `$4000`. This means we need to subtract `$4000` from `$d079` to give us the actual location to patch in the file, which is `$9079`:

```
echo "9079: 0000" | xxd -r - elite.bin
```

## Writing a loader

`loader.asm` is a simple loader which will headerlessly load the block of code we just dumped. After loading, it will apply some patches.

## Patching the game

We apply 3 patches, as defined in `patches.asm`:
- Patch out Lenslok by writing a `ret` instruction at the very start of the Lenslok routine;
- [As suggested by patters on the Spectrum Computing forum](https://spectrumcomputing.co.uk/forums/viewtopic.php?p=73719#p73719), we apply 2 gameplay bugfixes.

### A word on Lenslok

It's become something of a meme that Lenslok was a bad attempt at protection because of the various usability issues, but it turns out that it wasn't even implemented effectively here! At the very least, they could have made the check routine essential to running the game. For example, Driller does this by having two bytes in the game corrupted, and the "enter a word from the manual" routine patches them back to what they should have been (it patches one byte when you enter the routine, and the other when you exit it). These bytes are essential to the game and it will crash immediately without them. An sneakier method of protection is in the game ACE, where the corrupted byte isn't needed until you reach the second level. So if you patch out the "enter the code" check, you might think you've cracked the protection if you just give it a quick test, but play it for any length of time and you'll realise you haven't!

## Relocating the loader.

Just for shits and/or giggles, we're going to embed our loader in a small BASIC program. In order to do this, we need to write a short routine to relocate the loader to where it needs to be. This is done in `relocate.asm`.

## Putting it all together

`make both` will do everything needed to assemble the tap files:
- Compile the loader, followed by the relocation code that will contain it;
- Embed this loader and relocation bundle in a BASIC program;
- Convert the dumped binary data to a tap file;
- Convert the tap to a TZX file (as the TZX tools are more versatile);
- Glue everything together then remove the unneeded header introduced in the dumped binary data tap;
- Convert this TZX to our final tap file.
- Delete the interim files.

It will do this for both `elite48_a.bin` and `elite48_b.bin`. If you only want to do one, simply call `make TARGET=file`. For example, if you exported the data to `elite.bin`:

```
make TARGET=elite
```

This will produce a file `elite.tap`.
