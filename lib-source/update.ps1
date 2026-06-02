param(
  [string] $Branch = "main",
  [string] $SqliteVecBranch = "main",
  [string] $MormotBranch = "master",
  [switch] $NoPull
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

$Submodules = @(
  @{
    Name = "sqlite-lembed"
    Path = Join-Path $ScriptDir "sqlite-lembed"
    Branch = $Branch
    Recursive = $true
  },
  @{
    Name = "sqlite-vec"
    Path = Join-Path $ScriptDir "sqlite-vec"
    Branch = $SqliteVecBranch
    Recursive = $false
  },
  @{
    Name = "mORMot2"
    Path = Join-Path $ScriptDir "mORMot2"
    Branch = $MormotBranch
    Recursive = $false
  }
)

function Invoke-Git {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $Arguments,
    [string] $WorkingDirectory = $RepoRoot
  )

  & git -C $WorkingDirectory @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
}

function Test-CleanGitWorktree {
  param(
    [Parameter(Mandatory = $true)]
    [string] $WorkingDirectory
  )

  $status = & git -C $WorkingDirectory status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw "git status failed in $WorkingDirectory"
  }

  return [string]::IsNullOrWhiteSpace(($status -join ""))
}

Write-Host "Repository: $RepoRoot"

Write-Host "Initializing submodules..."
Invoke-Git -Arguments @("submodule", "update", "--init", "--recursive")

foreach ($submodule in $Submodules) {
  if (-not (Test-Path $submodule.Path)) {
    throw "$($submodule.Name) submodule not found: $($submodule.Path)"
  }
}

if (-not $NoPull) {
  foreach ($submodule in $Submodules) {
    if (-not (Test-CleanGitWorktree -WorkingDirectory $submodule.Path)) {
      throw "$($submodule.Name) has local changes. Commit, stash, or run with -NoPull."
    }

    Write-Host "Updating $($submodule.Name) from origin/$($submodule.Branch)..."
    Invoke-Git -WorkingDirectory $submodule.Path -Arguments @("fetch", "origin", $submodule.Branch)
    Invoke-Git -WorkingDirectory $submodule.Path -Arguments @("checkout", $submodule.Branch)
    Invoke-Git -WorkingDirectory $submodule.Path -Arguments @("pull", "--ff-only", "origin", $submodule.Branch)
  }
}

Write-Host "Updating nested submodules..."
foreach ($submodule in $Submodules) {
  if ($submodule.Recursive) {
    Invoke-Git -WorkingDirectory $submodule.Path -Arguments @("submodule", "update", "--init", "--recursive")
  }
}

Write-Host ""
Write-Host "Current submodule status:"
Invoke-Git -Arguments @("submodule", "status", "--recursive")
