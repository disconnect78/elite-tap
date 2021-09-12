# ELITE TAP CONVERTER

## Overview

This is a write-up of how I created a tap version of Elite (both the Krait and Adder versions) and steps to reproduce it. I'm running macOS so you may need to adjust some steps to suit if you're not. Even if you are, there may be some things I already had installed that you don't ([Homebrew](https://brew.sh/), Python etc.); if any of the below doesn't work then you'll need to figure this out for yourself I'm afraid!

For this conversion we will allow the game's Softlock protection to load and decrypt the game. We will dump the entire block of game data from `$4000` to `$ffa8`, then write a small machine code loader to headerlessly load it back and patch out the Lenslok protection, along with applying a couple of bug fixes. We will compile the loader, embed it in a short BASIC program, then put together our final tap file.

## Prerequisites

You'll need a TZX copy of Elite. A valid version can be downloaded from the [TZX Vault](https://tzxvault.org/):
- http://www.tzxvault.org/Spectrum/TZX/Elite-48k.zip

You'll also need the following tools and programs:

### Fuse
This is the emulator we use to load then dump the game data. Note that I've used the native macOS version.
- http://fuse-emulator.sourceforge.net/
- https://fuse-for-macosx.sourceforge.io/

### UnrealSpeccy
Alternatively, we can use the emulator UnrealSpecch if we have some way of running Windows software -- either natively or under something like [Parallels](https://www.parallels.com/).
- http://dlcorp.nedopc.com/viewforum.php?f=8

### Tomaz Kac's ZXTape utilities
We use these to convert from tap to TZX and back again. The win32 versions don't compile under macOS but the Amiga versions will, so we use these:
- http://ftp.fau.de/aminet/misc/emu/tap2tzx-os4.lha
- http://ftp.fau.de/aminet/misc/emu/tzx2tap-os4.lha

```
gcc tzx2tap -o tzx2tap
gcc tap2tzx -o tap2tzx
cp tzx2tap /usr/local/bin
cp tap2tzx /usr/local/bin
```

### TZX Tools
We use the `tzxmerge` tool to combine interim TZX files into one file, and `tzxcut` to remove the unwanted code header.
- https://github.com/shred/tzxtools

I had to install `portaudio` before these would install:
```
brew install portaudio
pip3 install tzxtools
```

### Pasmo
This is the Z80 compiler we use.
- https://pasmo.speccy.org/

Download the gzipped tar file with sources, then build:

```
./configure
make
cp pasmo /usr/local/bin
```

### taptools
We use `bin2bas` to embed the loader in a BASIC program.
- http://www.seasip.info/ZX/unix.html

Download the gzipped tar file for v1.1.1 (which supports TZX) with sources, then build:

```
./configure
make
cp bin2bas /usr/local/bin
```

## Dumping the game data

We will use an emulator to load the game then save out the required data. Note that the game's Softlock protection will only correctly decrypt the game if loaded into a standard 48k Spectrum, so make sure you're emulating one.

### Using Fuse

Ideally, we would set a debugger breakpoint and dump the data when it triggers; unfortunately this isn't possible in macOS Fuse as the required menu option is greyed out when we've hit the breakpoint. So we have to find another way to do it.

Start by opening the debugger and setting a breakpoint at $d079, which we will reach once the game is loaded and decrypted:

```
br $d079
```

Load the game from tape and wait until we hit the breakpoint. Now we need to patch in an infinite loop so that we can return to the emulator window and dump the game data at our leisure:

```
se $d07a $18
se $d07b $fe
```

Exit the debugger and almost immediately we should hit the loop. Use the `Export Binary Data` menu option to export the data to a file with the start address `16384` and length `49065`. Copy it into the working directory (ie. this one). We're going to create taps of both the A-side and B-side of the tape, so do this for both versions, exporting files `eilte48_a.bin` and `elite48_b.bin` as appropriate.

Finally, we patch the binary files so that the loop we added is patched back to the original bytes. The original location was `$d07a` but we saved memory from start address `16384`, ie. `$4000`. This means we need to subtract `$4000` from `$d07a` to give us the actual location to patch in the file, which is `$907a`:

```
echo "907a: 0000" | xxd -r - elite48_a.bin
echo "907a: 0000" | xxd -r - elite48_b.bin
```

### Using UnrealSpeccy

UnrealSpeccy's debugger allows us to set a breakpoint and save out the game data from the debugger without needing to do any additional patchimg.

Before we start, we must make sure we have the correct 48k ROMs loaded, otherwise the game won't decrypt correctly. Hit `Alt+F1` to open the settings window and make sure the `MEMORY` tab is open. Ensure `Custom ROMSET` is set to `ZX-Spectrum 48K` then click `OK`. Then press `Shift+F12` to reset to 48K mode.

Now press `Esc` to open the debugger. Press `Alt+C` to open the breakpoints manager. Under `Execution breakpoints`, type `d079` then press `Enter` to create the breakpoint. Press `Esc` to exit the breakpoints manager, then `Esc` again to return to the emulator.

Press `F3` to select the tape file, then load the game. The tape loading will pause partway through so press `F7` to continue loading, then `F10` to speed the emulator up to max speed.

The debugger will open when we hit the breakpoint. Press `Alt+W` to open the `Save data from memory...` box, then press `Enter` to select `to binary file`. Enter the filename `elite48_a.bin` or `elite48_b.bin` depending on whether we loaded the A-side or B-side version. Press `Enter` then provide the start address `4000`. Press `Enter` again then provide the end address `FFA8`. Press `Enter` to save the file.

Once both `elite48_a.bin` and `elite48_b.bin` have been dumped, move the files to the working directory (ie. this one).

## Writing a loader

[`loader.asm`](loader.asm) is a simple loader which will headerlessly load the block of code we just dumped. After loading, it will apply some patches.

## Patching the game

We apply 3 patches, as defined in [`patches.asm`](patches.asm):
- Patch out Lenslok by writing a `ret` instruction at the very start of the Lenslok routine;
- [As suggested by patters on the Spectrum Computing forum](https://spectrumcomputing.co.uk/forums/viewtopic.php?p=73719#p73719), we apply 2 gameplay bugfixes.

### A word on Lenslok

It's become something of a meme that Lenslok was a bad attempt at protection because of the various usability issues, but it turns out that it wasn't even implemented effectively here! At the very least, they could have made the check routine essential to running the game. For example, Driller does this by having two bytes in the game corrupted, and the "enter a word from the manual" routine patches them back to what they should have been (it patches one byte when you enter the routine, and the other when you exit it). These bytes are essential to the game and it will crash immediately without them. An sneakier method of protection is in the game ACE, where the corrupted byte isn't needed until you reach the second level. So if you patch out the "enter the code" check, you might think you've cracked the protection if you just give it a quick test, but play it for any length of time and you'll realise you haven't!

## Relocating the loader.

Just for shits and/or giggles, we're going to embed our loader in a small BASIC program, rather than having it saved in a separate file preceded by a BASIC program that loads then runs it. In order to do this, we need to write a short routine to relocate the loader to where it needs to be. This is done in [`relocate.asm`](relocate.asm).

## Putting it all together

`make both` will do everything needed to assemble the tap files:
- Compile the loader
- Compile the relocator, which also imports the loader;
- Embed this loader and relocation bundle in a BASIC program;
- Convert the dumped binary data to a tap file;
- Convert the tap to a TZX file (as the TZX tools are more versatile);
- Glue everything together then remove the unneeded header introduced in the dumped binary data tap;
- Convert this TZX to our final tap file;
- Delete the interim files.

It will do this for both `elite48_a.bin` and `elite48_b.bin`. If you only want to do one, simply call `make TARGET=file`. For example, if you exported the data to `elite.bin`:

```
make TARGET=elite
```

This will produce a file `elite.tap`.
