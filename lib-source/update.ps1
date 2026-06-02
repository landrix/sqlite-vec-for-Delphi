param(
  [string] $Branch = "main",
  [switch] $NoPull
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$LembedDir = Join-Path $ScriptDir "sqlite-lembed"

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

if (-not (Test-Path $LembedDir)) {
  throw "sqlite-lembed submodule not found: $LembedDir"
}

if (-not $NoPull) {
  if (-not (Test-CleanGitWorktree -WorkingDirectory $LembedDir)) {
    throw "sqlite-lembed has local changes. Commit, stash, or run with -NoPull."
  }

  Write-Host "Updating sqlite-lembed from origin/$Branch..."
  Invoke-Git -WorkingDirectory $LembedDir -Arguments @("fetch", "origin", $Branch)
  Invoke-Git -WorkingDirectory $LembedDir -Arguments @("checkout", $Branch)
  Invoke-Git -WorkingDirectory $LembedDir -Arguments @("pull", "--ff-only", "origin", $Branch)
}

Write-Host "Updating nested submodules..."
Invoke-Git -WorkingDirectory $LembedDir -Arguments @("submodule", "update", "--init", "--recursive")

Write-Host ""
Write-Host "Current submodule status:"
Invoke-Git -Arguments @("submodule", "status", "--recursive")
