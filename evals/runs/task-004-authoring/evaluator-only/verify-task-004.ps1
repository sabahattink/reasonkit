[CmdletBinding()]
param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).ProviderPath,
  [switch]$KeepTemp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packageRoot = Join-Path $RepoRoot 'evals\runs\task-004-authoring'
$fixtureRoot = Join-Path $packageRoot 'fixture-public'
$hiddenTest = Join-Path $packageRoot 'evaluator-only\hidden-regression.js'
$referenceLoader = Join-Path $packageRoot 'evaluator-only\reference-fixed\src\config-loader.js'
$naiveLoader = Join-Path $packageRoot 'evaluator-only\naive-fixed\src\config-loader.js'
$candidateManifestPath = Join-Path $RepoRoot 'dist\v0.2\candidate-manifest.json'
$expectedCandidateFileSha = 'd92130b16185e4f21af3223e51a8ea38269d3fd76b5e4462f7d33d8d53ee1621'
$expectedCandidateCanonicalSha = '17f66740655adf279b217c6288b521212c579fc631dbc1fd44646cebd8cb1948'

function Invoke-Node {
  param(
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  $previousLocation = Get-Location
  try {
    Set-Location -LiteralPath $WorkingDirectory
    $output = (& node @Arguments 2>&1 | Out-String -Width 240)
    $exitCode = $LASTEXITCODE
  }
  finally {
    Set-Location -LiteralPath $previousLocation
  }

  [pscustomobject]@{
    ExitCode = $exitCode
    Output = $output.Trim()
  }
}

function New-IsolatedFixture {
  param(
    [Parameter(Mandatory = $true)][string]$Destination,
    [Parameter(Mandatory = $true)][string]$ReplacementLoader
  )

  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  Copy-Item -Path (Join-Path $fixtureRoot '*') -Destination $Destination -Recurse -Force
  Copy-Item -LiteralPath $ReplacementLoader -Destination (Join-Path $Destination 'src\config-loader.js') -Force
}

function Require-NonZero {
  param([Parameter(Mandatory = $true)]$Result, [Parameter(Mandatory = $true)][string]$Label)
  if ($Result.ExitCode -eq 0) {
    throw "$Label unexpectedly passed"
  }
}

function Require-Zero {
  param([Parameter(Mandatory = $true)]$Result, [Parameter(Mandatory = $true)][string]$Label)
  if ($Result.ExitCode -ne 0) {
    throw "$Label failed with exit code $($Result.ExitCode)`n$($Result.Output)"
  }
}

function Get-Codes {
  param([Parameter(Mandatory = $true)]$Results)
  return @($Results | ForEach-Object { $_.ExitCode })
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('reasonkit-task-004-' + [guid]::NewGuid().ToString('N'))
$candidateFileShaBefore = $null
$candidateCanonicalBefore = $null
$summary = $null

try {
  if (-not (Test-Path -LiteralPath $candidateManifestPath -PathType Leaf)) {
    throw "Frozen candidate manifest not found: $candidateManifestPath"
  }

  $candidateFileShaBefore = (Get-FileHash -LiteralPath $candidateManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
  $candidateJson = Get-Content -LiteralPath $candidateManifestPath -Raw | ConvertFrom-Json
  $candidateCanonicalBefore = [string]$candidateJson.candidate_manifest_sha256
  if ($candidateFileShaBefore -ne $expectedCandidateFileSha) {
    throw "Frozen candidate manifest file hash mismatch: $candidateFileShaBefore"
  }
  if ($candidateCanonicalBefore -ne $expectedCandidateCanonicalSha) {
    throw "Frozen candidate canonical digest mismatch: $candidateCanonicalBefore"
  }

  $coveredPaths = @($candidateJson.covered_files | ForEach-Object { $_.repository_relative_path })
  if ($coveredPaths -contains 'evals/runs/task-004-authoring/task.md') {
    throw 'TASK-004 package unexpectedly appears in frozen candidate coverage'
  }

  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  $referenceRoot = Join-Path $tempRoot 'reference'
  $naiveRoot = Join-Path $tempRoot 'naive'
  New-IsolatedFixture -Destination $referenceRoot -ReplacementLoader $referenceLoader
  New-IsolatedFixture -Destination $naiveRoot -ReplacementLoader $naiveLoader

  $publicBaseline = Invoke-Node -WorkingDirectory $fixtureRoot -Arguments @('--test')
  $hiddenBaseline = Invoke-Node -WorkingDirectory $packageRoot -Arguments @($hiddenTest, $fixtureRoot)
  $publicReference = Invoke-Node -WorkingDirectory $referenceRoot -Arguments @('--test')
  $hiddenReference = Invoke-Node -WorkingDirectory $packageRoot -Arguments @($hiddenTest, $referenceRoot)
  $publicNaive = Invoke-Node -WorkingDirectory $naiveRoot -Arguments @('--test')
  $hiddenNaive = Invoke-Node -WorkingDirectory $packageRoot -Arguments @($hiddenTest, $naiveRoot)

  Require-NonZero $publicBaseline 'public baseline'
  Require-NonZero $hiddenBaseline 'hidden baseline'
  Require-Zero $publicReference 'reference public validation'
  Require-Zero $hiddenReference 'reference hidden validation'
  Require-Zero $publicNaive 'incomplete-fix public validation'
  Require-NonZero $hiddenNaive 'incomplete-fix hidden sensitivity'

  $repeatPublicBaseline = Invoke-Node -WorkingDirectory $fixtureRoot -Arguments @('--test')
  $repeatHiddenBaseline = Invoke-Node -WorkingDirectory $packageRoot -Arguments @($hiddenTest, $fixtureRoot)
  $repeatPublicReference = Invoke-Node -WorkingDirectory $referenceRoot -Arguments @('--test')
  $repeatHiddenReference = Invoke-Node -WorkingDirectory $packageRoot -Arguments @($hiddenTest, $referenceRoot)
  $repeatPublicNaive = Invoke-Node -WorkingDirectory $naiveRoot -Arguments @('--test')
  $repeatHiddenNaive = Invoke-Node -WorkingDirectory $packageRoot -Arguments @($hiddenTest, $naiveRoot)

  $deterministic = (
    $publicBaseline.ExitCode -eq $repeatPublicBaseline.ExitCode -and
    $hiddenBaseline.ExitCode -eq $repeatHiddenBaseline.ExitCode -and
    $publicReference.ExitCode -eq $repeatPublicReference.ExitCode -and
    $hiddenReference.ExitCode -eq $repeatHiddenReference.ExitCode -and
    $publicNaive.ExitCode -eq $repeatPublicNaive.ExitCode -and
    $hiddenNaive.ExitCode -eq $repeatHiddenNaive.ExitCode
  )
  if (-not $deterministic) {
    throw 'Repeated authoring validation outcomes were not deterministic'
  }

  $candidateFileShaAfter = (Get-FileHash -LiteralPath $candidateManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
  $candidateJsonAfter = Get-Content -LiteralPath $candidateManifestPath -Raw | ConvertFrom-Json
  $candidateCanonicalAfter = [string]$candidateJsonAfter.candidate_manifest_sha256
  if ($candidateFileShaAfter -ne $candidateFileShaBefore -or $candidateCanonicalAfter -ne $candidateCanonicalBefore) {
    throw 'Frozen candidate manifest changed during TASK-004 validation'
  }

  $summary = [ordered]@{
    task_id = 'TASK-004'
    candidate_used = $false
    candidate_manifest_file_sha256_before = $candidateFileShaBefore
    candidate_manifest_file_sha256_after = $candidateFileShaAfter
    candidate_canonical_digest_before = $candidateCanonicalBefore
    candidate_canonical_digest_after = $candidateCanonicalAfter
    public_baseline = [ordered]@{ result = 'INTENTIONAL_FAIL'; exit_codes = @( $publicBaseline.ExitCode, $repeatPublicBaseline.ExitCode ) }
    hidden_baseline = [ordered]@{ result = 'INTENTIONAL_FAIL'; exit_codes = @( $hiddenBaseline.ExitCode, $repeatHiddenBaseline.ExitCode ) }
    reference_fix = [ordered]@{ public = @( $publicReference.ExitCode, $repeatPublicReference.ExitCode ); hidden = @( $hiddenReference.ExitCode, $repeatHiddenReference.ExitCode ) }
    incomplete_fix_sensitivity = [ordered]@{ public = @( $publicNaive.ExitCode, $repeatPublicNaive.ExitCode ); hidden = @( $hiddenNaive.ExitCode, $repeatHiddenNaive.ExitCode ) }
    determinism = 'PASS'
    status = 'PASS'
  }
}
finally {
  if (-not $KeepTemp -and (Test-Path -LiteralPath $tempRoot)) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

$summary | ConvertTo-Json -Depth 8
