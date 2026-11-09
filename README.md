# TrackTrim

Remove the audio languages you don't need from a movie or episode, and keep everything else exactly as it is.

Drop in a video and TrackTrim lists every audio track (language, codec, channels, bitrate and size). Untick the ones you don't want and press **Export**. You get a smaller copy with the same video, the same quality and the same chapters, made in seconds because nothing is re-encoded.

**[⬇ Download TrackTrim.exe](https://github.com/Alen101/TrackTrim/releases/latest)**: Windows 10 and 11, one portable file, nothing to install.

![Tracks view](docs/tracks-dark.png)

## Using it

1. Open **TrackTrim.exe** and drop in one or more videos, or a whole folder. You can also drag files onto the .exe icon.
2. Untick the audio tracks (and, if you want, subtitles) you don't need.
   - Use the **language chips** above the list to remove every track of one language at once.
   - Press ▶ on a track to hear 15 seconds of it, which helps when a track is unlabelled or labelled wrong.
   - **Make default** chooses which track players start with.
3. Press **Export**. The footer shows how much space you'll save before you start.

Several files at once (a season, for example): set up the first episode, then click **Use these languages for all files**. TrackTrim keeps the same languages in every file, and leaves a file untouched if it has none of those languages.

![Batch view](docs/batch-light.png)

## Where the new file goes

Use the **Save** button next to Export:

| Option | What happens |
|---|---|
| Next to the original *(default)* | Saves `Movie (trimmed).mkv` beside the original. The original is never touched. |
| In a folder I choose | Saves all new files to one folder. |
| Replace the original | Writes the new file and checks it. Only then does the original go to the **Recycle Bin**, so you can still get it back. On drives without a Recycle Bin (USB, network), the original is kept as `Movie (original).mkv` instead. |

## What's shown

- **File:** container, size, length and chapter count. Video: resolution, codec, 10‑bit, HDR10/HLG/Dolby Vision, frame rate and bitrate.
- **Each audio track:** language (full name, e.g. *Malayalam*; read from the track title when the file doesn't say), title, codec (AAC, Dolby Digital, Dolby Digital Plus/Atmos, TrueHD/Atmos, DTS, DTS‑HD MA, FLAC, Opus, PCM…), channels (Stereo, 5.1, 7.1), sample rate, bitrate, size, and flags (Default, Lossless, Commentary, Audio description, Forced).
- **Subtitles:** language, format (SRT, ASS, PGS…), and Forced/SDH flags.
- **Before you export:** an estimate of the space saved and the new file size (accurate to about 1–2%).

## Why it's fast and safe

- **Lossless:** streams are copied byte for byte with FFmpeg (`-c copy`). Nothing is decoded or re-encoded, so speed depends only on your disk (about 0.8–1 GB per second on the laptop it was tested on).
- **Everything else is kept:** video, subtitles, chapters, fonts and attachments, cover art, titles and metadata.
- **Every output is checked:** after writing, TrackTrim reads the new file back and checks its track counts and length. If anything is off, the new file is discarded and the original is left alone.
- **Disk space check:** it won't start if the drive doesn't have room, so you never end up with a half-written file.
- **Automatic MKV fallback:** if the original container can't hold the remaining tracks, TrackTrim saves as `.mkv` and tells you why.
- **Clean cancel:** cancelling, or closing the app mid-export, deletes the unfinished file.
- **Formats:** MKV, MP4, M4V, MOV, AVI, TS, M2TS/MTS, MPG/VOB, WebM, WMV/ASF, FLV, OGV and more. The output keeps the original format, and M2TS keeps its Blu-ray packet layout.
- **Private:** it runs fully offline, and nothing is uploaded.
- Follows Windows light/dark mode, shows progress on the taskbar icon, and flashes the taskbar when a long export finishes.

## Installing and sharing

Download **TrackTrim.exe** from the [Releases page](https://github.com/Alen101/TrackTrim/releases/latest) and run it. It's a single file and needs nothing installed (Windows 10 and 11 already include .NET Framework 4.8). To share it, send friends that link or the .exe itself.

- Because the app isn't code-signed, Windows SmartScreen may say *"Windows protected your PC"*. Click **More info → Run anyway**.
- The very first launch on a new PC can take about 10 seconds while Windows Defender scans the file. After that it opens in under a second.
- On first run, TrackTrim unpacks its FFmpeg engine to `%LOCALAPPDATA%\TrackTrim\engine` (about 160 MB).
- To remove it: delete the .exe, plus `%LOCALAPPDATA%\TrackTrim` and `%APPDATA%\TrackTrim`.

Keyboard: `Ctrl+O` add videos · `Ctrl+E` export · `Esc` cancel export · `Delete` remove the selected file from the list · `Space` tick/untick the focused track.

## Building from source

Requirements: the .NET SDK (8 or newer; it builds a .NET Framework 4.8 app) and an FFmpeg build.

```powershell
# 1. Get an LGPL FFmpeg "shared" build, e.g. ffmpeg-n8.1-latest-win64-lgpl-shared-8.1.zip
#    from https://github.com/BtbN/FFmpeg-Builds/releases, and unzip it.
# 2. Build dist\TrackTrim.exe with the engine embedded:
powershell -ExecutionPolicy Bypass -File build.ps1 -FFmpegBin "C:\path\to\ffmpeg-...-lgpl-shared-8.1\bin"
```

`build.ps1` packs FFmpeg into `src\TrackTrim\engine\ffmpeg-engine.zip` (not in the repo because of its size) and embeds it in the .exe. A plain `dotnet build src\TrackTrim -c Release` also works without it, but that build uses the FFmpeg on your PATH instead of a bundled one.

### Tests

```powershell
# generate multi-language sample videos (needs ffmpeg on PATH; about 1.8 GB including a large file for the cancel/speed tests)
powershell -ExecutionPolicy Bypass -File tests\make-samples.ps1 -Out C:\temp\tt-samples
dotnet build tests\TrackTrim.Tests -c Release -o C:\temp\tt-tests
C:\temp\tt-tests\TrackTrim.Tests.exe C:\temp\tt-samples C:\temp\tt-work [--engine <folder with ffmpeg.exe + ffprobe.exe>]
```

The suite has 31 tests. It covers probing every format, exporting MKV/MP4/AVI/TS/M2TS/WebM/MOV, keeping chapters, attachments and forced flags, reassigning the default track, the MKV fallback, Unicode paths, size-estimate accuracy, audio preview for every codec, progress, cancel cleanup, the disk-full refusal, both replace-original paths, output-folder naming and argument quoting. `tests\ui-driver.ps1` has UI Automation helpers for driving the real window.

## Project layout

```
src/TrackTrim/Core/        engine: probing, languages, export, verification, preview (no UI code)
src/TrackTrim/ViewModels/  app logic: files, tracks, defaults, batch, footer summary
src/TrackTrim/UI/, Themes/ theme handling, styles, folder picker, settings
tests/                     sample generator, engine test suite, UI automation helpers
build.ps1                  packs FFmpeg and builds dist/TrackTrim.exe
```

## License

TrackTrim is released under the [MIT License](LICENSE).

The .exe embeds an unmodified FFmpeg build (LGPL version 3) from https://github.com/BtbN/FFmpeg-Builds. FFmpeg's license text is unpacked next to the engine as `FFMPEG-LICENSE.txt`, and the FFmpeg source is available at https://ffmpeg.org.
