param(
  [string] $Configuration = "Release",
  [string] $Platform = "x64",
  [string] $BuildDir = "build-vs-x64",
  [switch] $SkipDelphiOutput
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SourceDir = Join-Path $ScriptDir "sqlite-lembed"
$LibDir = Join-Path $RepoRoot "lib\sqlite-lembed\x86_64-win64"
$DelphiOutputDir = Join-Path $RepoRoot "examples\simple-delphi\Win64\Debug"
$VsVars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

$DllNames = @(
  "lembed0.dll",
  "llama.dll",
  "ggml.dll",
  "ggml-base.dll",
  "ggml-cpu.dll"
)

function Invoke-Cmd {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Command,
    [Parameter(Mandatory = $true)]
    [string] $WorkingDirectory
  )

  Push-Location $WorkingDirectory
  try {
    & cmd.exe /c $Command
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code $LASTEXITCODE"
    }
  }
  finally {
    Pop-Location
  }
}

function Copy-RuntimeDlls {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Source,
    [Parameter(Mandatory = $true)]
    [string] $Destination
  )

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  foreach ($dll in $DllNames) {
    $sourceFile = Join-Path $Source $dll
    if (-not (Test-Path $sourceFile)) {
      throw "Missing runtime DLL: $sourceFile"
    }
    Copy-Item -LiteralPath $sourceFile -Destination $Destination -Force
  }
}

if (-not (Test-Path $SourceDir)) {
  throw "sqlite-lembed submodule not found: $SourceDir"
}

if (-not (Test-Path $VsVars)) {
  throw "Visual Studio vcvars64.bat not found: $VsVars"
}

$buildCommand =
  "call ""$VsVars"" >nul && " +
  "cmake -S . -B $BuildDir -G ""Visual Studio 17 2022"" -A $Platform -DCMAKE_BUILD_TYPE=$Configuration && " +
  "cmake --build $BuildDir --config $Configuration --target sqlite_lembed -- /m"

Write-Host "Building sqlite-lembed ($Platform/$Configuration)..."
Invoke-Cmd -WorkingDirectory $SourceDir -Command $buildCommand

$RuntimeDir = Join-Path $SourceDir "$BuildDir\bin\$Configuration"

Write-Host "Copying runtime DLLs to $LibDir..."
Copy-RuntimeDlls -Source $RuntimeDir -Destination $LibDir

if (-not $SkipDelphiOutput) {
  Write-Host "Copying runtime DLLs to $DelphiOutputDir..."
  Copy-RuntimeDlls -Source $RuntimeDir -Destination $DelphiOutputDir
}

Write-Host ""
Write-Host "sqlite-lembed runtime DLLs:"
Get-ChildItem -Path $LibDir -Filter "*.dll" |
  Where-Object { $DllNames -contains $_.Name } |
  Select-Object Name, Length, LastWriteTime
