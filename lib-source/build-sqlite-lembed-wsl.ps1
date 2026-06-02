param(
  [string] $Configuration = "Release",
  [string] $BuildDir = "build-wsl",
  [string] $LinuxArch = "aarch64-linux"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SourceDir = Join-Path $ScriptDir "sqlite-lembed"
$LibDir = Join-Path $RepoRoot "lib\sqlite-lembed\$LinuxArch"

$WindowsSourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
if ($WindowsSourceDir -notmatch '^([A-Za-z]):\\(.*)$') {
  throw "Cannot convert Windows path to WSL path: $WindowsSourceDir"
}
$Drive = $Matches[1].ToLower()
$Rest = $Matches[2] -replace '\\', '/'
$WslSourceDir = "/mnt/$Drive/$Rest"

$buildCommand = @"
set -euo pipefail
cd "$WslSourceDir"
cmake -S . -B "$BuildDir" -G Ninja -DCMAKE_BUILD_TYPE=$Configuration
cmake --build "$BuildDir" --config $Configuration --target sqlite_lembed
"@

Write-Host "Building sqlite-lembed for Linux via WSL ($LinuxArch/$Configuration)..."
wsl bash -lc $buildCommand
if ($LASTEXITCODE -ne 0) {
  throw "WSL build failed with exit code $LASTEXITCODE"
}

$RuntimeDir = Join-Path $SourceDir "$BuildDir\bin"
$RuntimeFiles = @(
  "lembed0.so",
  "libllama.so",
  "libggml.so",
  "libggml-base.so",
  "libggml-cpu.so"
)

New-Item -ItemType Directory -Force -Path $LibDir | Out-Null
foreach ($file in $RuntimeFiles) {
  $sourceFile = Join-Path $RuntimeDir $file
  if (-not (Test-Path $sourceFile)) {
    throw "Missing Linux runtime file: $sourceFile"
  }
  Copy-Item -LiteralPath $sourceFile -Destination $LibDir -Force
}

Write-Host ""
Write-Host "sqlite-lembed Linux runtime files:"
Get-ChildItem -Path $LibDir |
  Where-Object { $RuntimeFiles -contains $_.Name } |
  Select-Object Name, Length, LastWriteTime
