param(
  [string] $LinuxArch = "aarch64-linux",
  [string] $BuildDir = "aarch64-linux"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SourceDir = Join-Path $ScriptDir "sqlite-vec"
$LibDir = Join-Path $RepoRoot "lib\sqlite-vec\$LinuxArch"
$BuildOutputDir = Join-Path $ScriptDir ".build\sqlite-vec\$BuildDir"

if (-not (Test-Path $SourceDir)) {
  throw "sqlite-vec submodule not found: $SourceDir"
}

$WindowsSourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
if ($WindowsSourceDir -notmatch '^([A-Za-z]):\\(.*)$') {
  throw "Cannot convert Windows path to WSL path: $WindowsSourceDir"
}
$Drive = $Matches[1].ToLower()
$Rest = $Matches[2] -replace '\\', '/'
$WslSourceDir = "/mnt/$Drive/$Rest"

$WindowsBuildOutputDir = (New-Item -ItemType Directory -Force -Path $BuildOutputDir).FullName
if ($WindowsBuildOutputDir -notmatch '^([A-Za-z]):\\(.*)$') {
  throw "Cannot convert Windows path to WSL path: $WindowsBuildOutputDir"
}
$BuildDrive = $Matches[1].ToLower()
$BuildRest = $Matches[2] -replace '\\', '/'
$WslBuildOutputDir = "/mnt/$BuildDrive/$BuildRest"

$buildCommand = @"
set -euo pipefail
cd "$WslSourceDir"
mkdir -p "$WslBuildOutputDir"
cc -fPIC -shared -Wall -Wextra -O3 -Ivendor sqlite-vec.c -o "$WslBuildOutputDir/vec0.so" -lm
"@

Write-Host "Building sqlite-vec for Linux via WSL ($LinuxArch)..."
wsl bash -lc $buildCommand
if ($LASTEXITCODE -ne 0) {
  throw "WSL build failed with exit code $LASTEXITCODE"
}

$RuntimeFile = Join-Path $BuildOutputDir "vec0.so"
if (-not (Test-Path $RuntimeFile)) {
  throw "Missing Linux runtime file: $RuntimeFile"
}

New-Item -ItemType Directory -Force -Path $LibDir | Out-Null
Copy-Item -LiteralPath $RuntimeFile -Destination $LibDir -Force

Write-Host ""
Write-Host "sqlite-vec Linux runtime file:"
Get-ChildItem -Path $LibDir -Filter "vec0.so" |
  Select-Object Name, Length, LastWriteTime
