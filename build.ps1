# Builds dist\TrackTrim.exe — one self-contained file you can share.
#
#   powershell -ExecutionPolicy Bypass -File build.ps1 -FFmpegBin <folder with ffmpeg.exe + ffprobe.exe (+ DLLs)> [-Dotnet <path to dotnet.exe>]
#
# Recommended engine: an LGPL "shared" build from https://github.com/BtbN/FFmpeg-Builds/releases
# (e.g. ffmpeg-n8.1-latest-win64-lgpl-shared-8.1.zip) — pass its "bin" folder.
param(
    [Parameter(Mandatory = $true)][string]$FFmpegBin,
    [string]$Dotnet = "dotnet",
    [string]$Out = "dist"
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Join-Path $here "src\TrackTrim\TrackTrim.csproj"
$engineDir = Join-Path $here "src\TrackTrim\engine"
$zip = Join-Path $engineDir "ffmpeg-engine.zip"

foreach ($exe in "ffmpeg.exe", "ffprobe.exe") {
    if (-not (Test-Path (Join-Path $FFmpegBin $exe))) { throw "$exe not found in $FFmpegBin" }
}

# 1. Pack the engine: ffmpeg, ffprobe, their DLLs and the FFmpeg license.
$stage = Join-Path ([IO.Path]::GetTempPath()) ("tracktrim-engine-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item (Join-Path $FFmpegBin "ffmpeg.exe"), (Join-Path $FFmpegBin "ffprobe.exe") $stage
Get-ChildItem $FFmpegBin -Filter *.dll | Copy-Item -Destination $stage
$license = Get-ChildItem (Split-Path -Parent $FFmpegBin) -Filter "LICENSE*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($license) { Copy-Item $license.FullName (Join-Path $stage "FFMPEG-LICENSE.txt") }

New-Item -ItemType Directory -Force $engineDir | Out-Null
if (Test-Path $zip) { Remove-Item $zip }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
Remove-Item -Recurse -Force $stage
Write-Host ("engine packed: {0:N1} MB" -f ((Get-Item $zip).Length / 1MB))

# 2. Build.
$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"; $env:DOTNET_NOLOGO = "1"
$buildOut = Join-Path $here "build\bin"
& $Dotnet build $proj -c Release -o $buildOut -v q
if ($LASTEXITCODE -ne 0) { throw "build failed" }

# 3. Copy the single exe to dist.
$dist = Join-Path $here $Out
New-Item -ItemType Directory -Force $dist | Out-Null
Copy-Item (Join-Path $buildOut "TrackTrim.exe") $dist -Force
$exeOut = Get-Item (Join-Path $dist "TrackTrim.exe")
Write-Host ("built: {0}  ({1:N1} MB)" -f $exeOut.FullName, ($exeOut.Length / 1MB))
Write-Host ("SHA-256: " + (Get-FileHash $exeOut.FullName -Algorithm SHA256).Hash)
