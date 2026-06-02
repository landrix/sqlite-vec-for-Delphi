param(
  [ValidateSet("all", "x64", "arm64")]
  [string] $Platform = "all"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SourceDir = Join-Path $ScriptDir "sqlite-vec"
$BuildRoot = Join-Path $ScriptDir ".build\sqlite-vec"

$Builds = @(
  @{
    Platform = "x64"
    VsVars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    BuildDir = Join-Path $BuildRoot "msvc-x64"
    LibDir = Join-Path $RepoRoot "lib\sqlite-vec\x86_64-win64"
  },
  @{
    Platform = "arm64"
    VsVars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsarm64.bat"
    BuildDir = Join-Path $BuildRoot "msvc-arm64"
    LibDir = Join-Path $RepoRoot "lib\sqlite-vec\aarch64-win64"
  }
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

if (-not (Test-Path $SourceDir)) {
  throw "sqlite-vec submodule not found: $SourceDir"
}

foreach ($build in $Builds) {
  if ($Platform -ne "all" -and $Platform -ne $build.Platform) {
    continue
  }

  if (-not (Test-Path $build.VsVars)) {
    throw "Visual Studio environment not found: $($build.VsVars)"
  }

  $buildDir = $build.BuildDir
  $dllPath = Join-Path $buildDir "vec0.dll"
  $objPath = Join-Path $buildDir "sqlite-vec.obj"
  $pdbPath = Join-Path $buildDir "vec0.pdb"
  $implibPath = Join-Path $buildDir "vec0.lib"
  $command =
    "call ""$($build.VsVars)"" >nul && " +
    "if not exist ""$buildDir"" mkdir ""$buildDir"" && " +
    "cl /nologo /O2 /LD /Ivendor sqlite-vec.c " +
    "/Fo""$objPath"" /Fd""$pdbPath"" /Fe""$dllPath"" " +
    "/link /NOLOGO /IMPLIB:""$implibPath"" /PDB:""$pdbPath"""

  Write-Host "Building sqlite-vec for Windows $($build.Platform)..."
  Invoke-Cmd -WorkingDirectory $SourceDir -Command $command

  if (-not (Test-Path $dllPath)) {
    throw "Missing runtime DLL: $dllPath"
  }

  New-Item -ItemType Directory -Force -Path $build.LibDir | Out-Null
  Copy-Item -LiteralPath $dllPath -Destination $build.LibDir -Force

  Write-Host "Copied vec0.dll to $($build.LibDir)"
}

Write-Host ""
Write-Host "sqlite-vec Windows runtime files:"
Get-ChildItem -Path (Join-Path $RepoRoot "lib\sqlite-vec") -Recurse -Filter "vec0.dll" |
  Select-Object Name, DirectoryName, Length, LastWriteTime
