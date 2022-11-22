# Floppy Rockers

> "Kinda sad there is drag drop file size limit. Or one could make music player that you dropped wav file onto to play."
> ~ [Wojbie, November 1st, 2022][]

Well, it's not WAV files, but it's drag and drop music!

## How to use

### To create Floppy Rockers files

```
lua fr_conv.lua <input> [output] [size]
```

Arguments:

 - `input`: The music file to use. Supported formats include WAV (DFPWM, ADPCM, PCM, or float PCM), raw DFPWM (mono 48KHz), AIFF, AU, and FLAC.
 - `output`: The name of the output file. Defaults to the input file plus `.fr`.
 - `size`: The intended size of the output file. Defaults to 512KiB (the file upload limit in ComputerCraft). Sizes can be given in KB, KiB, MB, or MiB (a unit of bytes is assumed otherwise), as well as `drag-and-drop` (512KiB, the default) and `floppy` (125KB, the default floppy size).

### To play Floppy Rockers files

Copy `fr.lua` to a ComputerCraft computer, and attach a speaker. Also, install `aukit.lua`, either by copying it from this repository (the version here has glue code to run on CC or base PUC-Rio Lua) or through a normal method, such as from [the upstream repository][].

```
fr [disk-or-file]
```

Arguments:

 - `disk-or-file`: Either a disk drive or a path to a Floppy Rockers file. To specify a disk drive, either specify the side it is attached on or the path it is mounted on. To specify a file, simply specify a path.

## How it works

Floppy Rockers files have a minimal header, in order to preserve as much space as possible for audio data. The first byte is a version, and the second byte is a divider/info byte. The rest of the file is DFPWM mono audio.

|Offset|Meaning     |
|------|------------|
|0     |Version     |
|1     |Divider/Info|

The current version is 0, which defines no flags. The reason flags can be defined in the divider byte is because, to be frank, we do not need a full divider byte. The largest possible even divider in a full byte, 250, would result in 192Hz audio; even the largest divider the converter will output, 64, gives awful-sounding 750Hz audio. As such, later versions will sacrifice high-order bits of the divider for flags.

The divider byte (minus any flags that a given version defines) is used to divide the base samplerate of 48KHz. For instance, a version byte of 0 and a divider byte of 3 indicates a 16KHz sample rate for the contained DFPWM audio. How the 16KHz audio is converted to 48KHz audio for ComputerCraft speakers is left as a detail to the implementer (the reference implementation simply uses AUKit, a wonderful library by JackMacWindows, to resample with cubic interpolation).

[Wojbie, November 1st, 2022]: https://discord.com/channels/477910221872824320/477911902152949771/1037124672900321341
[the upstream repository]: https://github.com/MCJack123/AUKit