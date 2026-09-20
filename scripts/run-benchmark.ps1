[CmdletBinding()]
param(
  [string]$Case,

  [ValidateSet('A', 'B', 'C', 'D')]
  [string]$Arm,

  [string]$Command,

  [string[]]$ArgumentList = @(),

  [string]$OutputRoot = 'evals/runs',

  [string]$BenchmarkManifestPath,

  [ValidateSet('v0.1', 'v0.2')]
  [string]$Profile = 'v0.1',

  [string]$CandidateManifestPath,

  [string]$RecoveryOf,

  [string[]]$AdapterPath = @(),

  [switch]$PrepareAll
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$defaultManifestPath = if ($Profile -eq 'v0.2') {
  Join-Path $root 'evals/benchmark-v0.2.json'
}
else {
  Join-Path $root 'evals/benchmark.json'
}
if ($Profile -eq 'v0.1' -and -not [string]::IsNullOrWhiteSpace($BenchmarkManifestPath)) {
  throw 'Benchmark manifest selection requires -Profile v0.2.'
}
$manifestPath = if ([string]::IsNullOrWhiteSpace($BenchmarkManifestPath)) {
  $defaultManifestPath
}
elseif ([IO.Path]::IsPathRooted($BenchmarkManifestPath)) {
  $BenchmarkManifestPath
}
else {
  Join-Path $root $BenchmarkManifestPath
}
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  throw ('Benchmark manifest is missing: ' + $manifestPath)
}
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$newLine = [string][char]10
$candidateBinding = $null

if ($Profile -eq 'v0.1' -and (
    -not [string]::IsNullOrWhiteSpace($CandidateManifestPath) -or
    @($AdapterPath).Count -gt 0 -or
    -not [string]::IsNullOrWhiteSpace($RecoveryOf))) {
  throw 'Candidate binding parameters require -Profile v0.2.'
}

function Resolve-RepoPath {
  param([string]$RelativePath)

  if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    return $null
  }
  return (Join-Path $root $RelativePath)
}

function Get-ManifestItem {
  param(
    [object[]]$Items,
    [string]$Id,
    [string]$Kind
  )

  $item = @($Items | Where-Object { $_.id -eq $Id }) |
    Select-Object -First 1
  if ($null -eq $item) {
    throw "Unknown $Kind id: $Id"
  }
  return $item
}

function Get-ManifestProperty {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function Get-FileProvenance {
  param(
    [string]$RelativePath,
    [string]$ExpectedHash,
    [string]$Label
  )

  if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
      throw ('Manifest has a ' + $Label + ' hash without a file.')
    }
    return [pscustomobject][ordered]@{
      RelativePath = $null
      AbsolutePath = $null
      Sha256 = $null
      Bytes = 0
      Verified = $true
    }
  }
  if ([IO.Path]::IsPathRooted($RelativePath) -or
      $RelativePath -match '(^|[\\/])\.\.([\\/]|$)') {
    throw ($Label + ' must be a repository-relative path: ' + $RelativePath)
  }
  if ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
    throw ('Manifest is missing the ' + $Label + ' hash: ' + $RelativePath)
  }

  $absolutePath = Resolve-RepoPath $RelativePath
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    throw ('Missing ' + $Label + ': ' + $RelativePath)
  }
  $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $absolutePath).Hash.ToLowerInvariant()
  if ($actualHash -ne $ExpectedHash.ToLowerInvariant()) {
    throw ($Label + ' hash mismatch: ' + $RelativePath)
  }

  return [pscustomobject][ordered]@{
    RelativePath = $RelativePath.Replace('\\', '/')
    AbsolutePath = $absolutePath
    Sha256 = $actualHash
    Bytes = (Get-Item -LiteralPath $absolutePath).Length
    Verified = $true
  }
}

function Get-SourceCommit {
  $global:LASTEXITCODE = 0
  $commit = @(
    & git -C $root rev-parse HEAD 2>$null |
      ForEach-Object { $_.ToString().Trim() } |
      Select-Object -First 1
  )
  $exitCode = $LASTEXITCODE
  $global:LASTEXITCODE = 0
  if ($commit.Count -eq 0) {
    return $null
  }
  return $commit[0]
}

function Get-SourceDirty {
  $global:LASTEXITCODE = 0
  $status = @(
    & git -C $root status --porcelain 2>$null |
      ForEach-Object { $_.ToString() }
  )
  $global:LASTEXITCODE = 0
  return ($status.Count -gt 0)
}

function Resolve-InputPath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }
  if ([IO.Path]::IsPathRooted($Path)) {
    return $Path
  }
  return Join-Path $root $Path
}

function Read-Utf8NoBomText {
  param([string]$Path)

  $bytes = [IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -ge 3 -and
      $bytes[0] -eq 0xEF -and
      $bytes[1] -eq 0xBB -and
      $bytes[2] -eq 0xBF) {
    throw 'Candidate manifest must be UTF-8 without a BOM.'
  }
  $encoding = New-Object System.Text.UTF8Encoding($false, $true)
  try {
    return $encoding.GetString($bytes)
  }
  catch {
    throw ('Candidate manifest is not valid UTF-8: ' + $_.Exception.Message)
  }
}

function Get-CandidateCoveredEntry {
  param(
    [object]$CandidateManifest,
    [string]$Path
  )

  $canonical = $Path.Replace('\', '/')
  return @(
    $CandidateManifest.covered_files |
      Where-Object { $_.repository_relative_path -eq $canonical }
  ) | Select-Object -First 1
}

function Read-V02CandidateBinding {
  if ([string]::IsNullOrWhiteSpace($CandidateManifestPath)) {
    throw 'Profile v0.2 requires -CandidateManifestPath.'
  }
  $modulePath = Join-Path $root 'scripts/reasonkit-v02.psm1'
  Import-Module -Name $modulePath -Force

  $manifestAbsolutePath = Resolve-InputPath -Path $CandidateManifestPath
  if (-not (Test-Path -LiteralPath $manifestAbsolutePath -PathType Leaf)) {
    throw ('Candidate manifest is missing: ' + $CandidateManifestPath)
  }
  $manifestText = Read-Utf8NoBomText -Path $manifestAbsolutePath
  $candidateManifest = $manifestText | ConvertFrom-Json -Depth 80
  $sourceCommit = Get-SourceCommit
  if ([string]::IsNullOrWhiteSpace($sourceCommit)) {
    throw 'Cannot bind a candidate without a source commit.'
  }
  $null = Assert-ReasonKitCandidateManifest `
    -Manifest $candidateManifest `
    -RepositoryRoot $root `
    -ExpectedSourceCommit $sourceCommit `
    -SchemaPath (Join-Path $root 'core/candidate-manifest.schema.json') `
    -ManifestText $manifestText

  $adapterEntries = @(
    $candidateManifest.covered_files |
      Where-Object { $_.role -eq 'adapter' }
  )
  if (@($AdapterPath).Count -gt 1 -or $adapterEntries.Count -gt 1) {
    throw 'The telemetry schema has one adapter_sha256; bind at most one selected adapter.'
  }
  if (@($AdapterPath).Count -eq 1) {
    $adapterEntry = Get-CandidateCoveredEntry -CandidateManifest $candidateManifest -Path $AdapterPath[0]
    if ($null -eq $adapterEntry -or $adapterEntry.role -ne 'adapter') {
      throw ('Selected adapter is not covered by the candidate manifest: ' + $AdapterPath[0])
    }
  }
  elseif ($adapterEntries.Count -eq 1) {
    $adapterEntry = $adapterEntries[0]
  }
  else {
    $adapterEntry = $null
  }

  $runnerEntry = Get-CandidateCoveredEntry -CandidateManifest $candidateManifest -Path 'scripts/run-benchmark.ps1'
  $runnerSha = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'scripts/run-benchmark.ps1')).Hash.ToLowerInvariant()
  if ($null -eq $runnerEntry -or $runnerEntry.sha256 -cne $runnerSha) {
    throw 'Candidate manifest runner hash does not match scripts/run-benchmark.ps1.'
  }

  return [pscustomobject][ordered]@{
    manifest = $candidateManifest
    candidate_id = $candidateManifest.candidate_id
    candidate_version = $candidateManifest.candidate_version
    candidate_manifest_sha256 = $candidateManifest.candidate_manifest_sha256.ToLowerInvariant()
    source_commit = $candidateManifest.source_commit.ToLowerInvariant()
    kernel_sha256 = $candidateManifest.kernel_sha256.ToLowerInvariant()
    module_manifest_sha256 = $candidateManifest.module_manifest_sha256.ToLowerInvariant()
    runner_sha256 = $runnerSha
    adapter_sha256 = if ($null -eq $adapterEntry) { $null } else { $adapterEntry.sha256.ToLowerInvariant() }
  }
}

function Assert-V02TelemetryBinding {
  param(
    [object]$Telemetry,
    [object]$CandidateBinding
  )

  $identity = $Telemetry.identity
  $provenance = $Telemetry.provenance
  $checks = @(
    [pscustomobject]@{ actual = $identity.candidate_id; expected = $CandidateBinding.candidate_id; name = 'candidate_id' }
    [pscustomobject]@{ actual = $identity.candidate_version; expected = $CandidateBinding.candidate_version; name = 'candidate_version' }
    [pscustomobject]@{ actual = $identity.candidate_manifest_sha256; expected = $CandidateBinding.candidate_manifest_sha256; name = 'candidate_manifest_sha256' }
    [pscustomobject]@{ actual = $provenance.source_commit; expected = $CandidateBinding.source_commit; name = 'source_commit' }
    [pscustomobject]@{ actual = $provenance.kernel_sha256; expected = $CandidateBinding.kernel_sha256; name = 'kernel_sha256' }
    [pscustomobject]@{ actual = $provenance.module_manifest_sha256; expected = $CandidateBinding.module_manifest_sha256; name = 'module_manifest_sha256' }
    [pscustomobject]@{ actual = $provenance.runner_sha256; expected = $CandidateBinding.runner_sha256; name = 'runner_sha256' }
    [pscustomobject]@{ actual = $provenance.adapter_sha256; expected = $CandidateBinding.adapter_sha256; name = 'adapter_sha256' }
  )
  foreach ($check in $checks) {
    if ([string]$check.actual -cne [string]$check.expected) {
      throw ('Immutable telemetry provenance was changed: ' + $check.name)
    }
  }
}

function Get-MetricValue {
  param(
    [object]$Metrics,
    [string]$Name
  )

  if ($null -eq $Metrics) {
    return $null
  }
  $property = $Metrics.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function Get-V02ProviderMeasurements {
  param([object]$Metrics)

  $source = if ($null -ne $Metrics.PSObject.Properties['provider_measurements']) {
    $Metrics.provider_measurements
  }
  else {
    $Metrics
  }
  return [ordered]@{
    input_tokens = Get-MetricValue -Metrics $source -Name 'input_tokens'
    cached_input_tokens = Get-MetricValue -Metrics $source -Name 'cached_input_tokens'
    output_tokens = Get-MetricValue -Metrics $source -Name 'output_tokens'
    reasoning_tokens = Get-MetricValue -Metrics $source -Name 'reasoning_tokens'
    total_tokens = Get-MetricValue -Metrics $source -Name 'total_tokens'
    tool_calls = Get-MetricValue -Metrics $source -Name 'tool_calls'
    agent_count = Get-MetricValue -Metrics $source -Name 'agent_count'
    duration_seconds = Get-MetricValue -Metrics $source -Name 'duration_seconds'
  }
}

function Get-V02Outcome {
  param([object]$Metrics)

  $source = if ($null -ne $Metrics.PSObject.Properties['outcome']) {
    $Metrics.outcome
  }
  else {
    $Metrics
  }
  return [ordered]@{
    verification = Get-MetricValue -Metrics $source -Name 'verification'
    stop = Get-MetricValue -Metrics $source -Name 'stop'
    provider_status = Get-MetricValue -Metrics $source -Name 'provider_status'
    model_completion_status = Get-MetricValue -Metrics $source -Name 'model_completion_status'
    task_success = Get-MetricValue -Metrics $source -Name 'task_success'
    scope_violation = Get-MetricValue -Metrics $source -Name 'scope_violation'
    evaluator_validity = Get-MetricValue -Metrics $source -Name 'evaluator_validity'
    changed_files = Get-MetricValue -Metrics $source -Name 'changed_files'
    tests_weakened = Get-MetricValue -Metrics $source -Name 'tests_weakened'
    dependencies_changed = Get-MetricValue -Metrics $source -Name 'dependencies_changed'
    failure_class = Get-MetricValue -Metrics $source -Name 'failure_class'
  }
}

function Update-V02TelemetryFromMetrics {
  param(
    [string]$TelemetryPath,
    [string]$MetricsPath,
    [object]$CandidateBinding,
    [bool]$SourceDirty
  )

  $telemetry = Get-Content -Raw -LiteralPath $TelemetryPath | ConvertFrom-Json -Depth 80
  $null = Assert-ReasonKitTelemetryRecord -Document $telemetry
  Assert-V02TelemetryBinding -Telemetry $telemetry -CandidateBinding $CandidateBinding
  $metrics = Get-Content -Raw -LiteralPath $MetricsPath | ConvertFrom-Json -Depth 80
  $integrity = [ordered]@{
    source_dirty = $SourceDirty
    raw_packet_sha256 = $null
    telemetry_sha256 = $null
    historical_materials_unchanged = $null
    integrity_status = 'UNVERIFIED'
  }
  return Update-ReasonKitTelemetryRecord `
    -Document $telemetry `
    -Outcome (Get-V02Outcome -Metrics $metrics) `
    -ProviderMeasurements (Get-V02ProviderMeasurements -Metrics $metrics) `
    -Integrity $integrity
}

function Get-DirectorySha256 {
  param([string]$Directory)

  $records = [System.Collections.Generic.List[string]]::new()
  $files = Get-ChildItem -LiteralPath $Directory -Recurse -File |
    Sort-Object FullName
  foreach ($file in $files) {
    $relative = [IO.Path]::GetRelativePath($Directory, $file.FullName).Replace('\', '/')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    $null = $records.Add(($relative + ':' + $hash.ToLowerInvariant()))
  }

  $payload = $records -join $newLine
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $digest = $sha.ComputeHash($bytes)
    return ([BitConverter]::ToString($digest) -replace '-', '').ToLowerInvariant()
  }
  finally {
    $sha.Dispose()
  }
}

function Get-InstructionProvenance {
  param(
    [object]$CaseItem,
    [object]$ArmItem
  )

  $instructionRelativePath = Get-ManifestProperty -Object $CaseItem.instructionFiles -Name $ArmItem.id
  $expectedHash = Get-ManifestProperty -Object $CaseItem.instructionSha256 -Name $ArmItem.id

  if ([string]::IsNullOrWhiteSpace($instructionRelativePath)) {
    if ($null -ne $expectedHash) {
      throw ('Manifest has an instruction hash without a file for arm ' + $ArmItem.id)
    }
    return [PSCustomObject]@{
      RelativePath = $null
      AbsolutePath = $null
      Sha256 = $null
      Bytes = 0
    }
  }

  $absolutePath = Resolve-RepoPath $instructionRelativePath
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    throw "Missing instruction file: $instructionRelativePath"
  }
  if ([string]::IsNullOrWhiteSpace($expectedHash)) {
    throw "Missing instruction hash for $instructionRelativePath"
  }

  $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $absolutePath).Hash.ToLowerInvariant()
  if ($actualHash -ne $expectedHash.ToLowerInvariant()) {
    throw ('Instruction hash mismatch: ' + $instructionRelativePath)
  }

  return [PSCustomObject]@{
    RelativePath = $instructionRelativePath
    AbsolutePath = $absolutePath
    Sha256 = $actualHash
    Bytes = (Get-Item -LiteralPath $absolutePath).Length
  }
}

function Get-TaskProvenance {
  param([object]$CaseItem)

  if ($Profile -ne 'v0.2') {
    return $null
  }
  $expectedHash = Get-ManifestProperty -Object $CaseItem -Name 'taskSha256'
  if ([string]::IsNullOrWhiteSpace([string]$expectedHash)) {
    return [pscustomobject][ordered]@{
      RelativePath = $CaseItem.promptFile
      AbsolutePath = Resolve-RepoPath $CaseItem.promptFile
      Sha256 = $null
      Bytes = 0
      Verified = $false
    }
  }
  return Get-FileProvenance `
    -RelativePath ([string]$CaseItem.promptFile) `
    -ExpectedHash ([string]$expectedHash) `
    -Label 'task prompt'
}

function Get-AcceptanceProvenance {
  param([object]$CaseItem)

  return Get-FileProvenance `
    -RelativePath ([string](Get-ManifestProperty -Object $CaseItem -Name 'acceptanceFile')) `
    -ExpectedHash ([string](Get-ManifestProperty -Object $CaseItem -Name 'acceptanceSha256')) `
    -Label 'acceptance material'
}

function Get-EvaluatorProvenance {
  param([object]$CaseItem)

  $evaluator = Get-ManifestProperty -Object $CaseItem -Name 'evaluator'
  if ($null -eq $evaluator) {
    return [pscustomobject][ordered]@{
      Type = $null
      Verifier = Get-FileProvenance -RelativePath $null -ExpectedHash $null -Label 'evaluator verifier'
      HiddenRegression = Get-FileProvenance -RelativePath $null -ExpectedHash $null -Label 'hidden regression'
      ReferenceFiles = @()
      Verified = $true
    }
  }

  $referenceFiles = @(
    foreach ($reference in @($evaluator.referenceFiles)) {
      $path = [string](Get-ManifestProperty -Object $reference -Name 'path')
      $hash = [string](Get-ManifestProperty -Object $reference -Name 'sha256')
      Get-FileProvenance -RelativePath $path -ExpectedHash $hash -Label 'evaluator reference'
    }
  )
  return [pscustomobject][ordered]@{
    Type = [string](Get-ManifestProperty -Object $evaluator -Name 'type')
    Verifier = Get-FileProvenance `
      -RelativePath ([string](Get-ManifestProperty -Object $evaluator -Name 'verifierPath')) `
      -ExpectedHash ([string](Get-ManifestProperty -Object $evaluator -Name 'verifierSha256')) `
      -Label 'evaluator verifier'
    HiddenRegression = Get-FileProvenance `
      -RelativePath ([string](Get-ManifestProperty -Object $evaluator -Name 'hiddenRegressionPath')) `
      -ExpectedHash ([string](Get-ManifestProperty -Object $evaluator -Name 'hiddenRegressionSha256')) `
      -Label 'hidden regression'
    ReferenceFiles = $referenceFiles
    Verified = $true
  }
}

function Get-V02BindingProvenance {
  param(
    [object]$CaseItem,
    [object]$ArmItem,
    [object]$CandidateBinding
  )

  if ($Profile -ne 'v0.2' -or $ArmItem.id -ne 'C') {
    return $null
  }

  $binding = Get-ManifestProperty -Object $CaseItem -Name 'v02Binding'
  if ($null -eq $binding) {
    throw ('v0.2 Arm C binding is missing for ' + $CaseItem.id)
  }
  if ((Get-ManifestProperty -Object $binding -Name 'fullBundleFallback') -ne $false) {
    throw ('v0.2 Arm C must disable full-bundle fallback for ' + $CaseItem.id)
  }

  $adapter = Get-FileProvenance `
    -RelativePath ([string](Get-ManifestProperty -Object $binding -Name 'adapterPath')) `
    -ExpectedHash ([string](Get-ManifestProperty -Object $binding -Name 'adapterSha256')) `
    -Label 'v0.2 adapter'
  $kernel = Get-FileProvenance `
    -RelativePath ([string](Get-ManifestProperty -Object $binding -Name 'kernelPath')) `
    -ExpectedHash ([string](Get-ManifestProperty -Object $binding -Name 'kernelSha256')) `
    -Label 'v0.2 kernel artifact'
  $registry = Get-FileProvenance `
    -RelativePath ([string](Get-ManifestProperty -Object $binding -Name 'registryPath')) `
    -ExpectedHash ([string](Get-ManifestProperty -Object $binding -Name 'registrySha256')) `
    -Label 'v0.2 module registry'
  $implementation = Get-FileProvenance `
    -RelativePath ([string](Get-ManifestProperty -Object $binding -Name 'implementationPath')) `
    -ExpectedHash ([string](Get-ManifestProperty -Object $binding -Name 'implementationSha256')) `
    -Label 'v0.2 loader implementation'

  if ([string]$kernel.RelativePath -eq 'dist/reasonkit-debugging.md' -or
      [string]$adapter.RelativePath -eq 'dist/reasonkit-debugging.md') {
    throw 'v0.2 Arm C cannot bind the frozen v0.1 debugging bundle.'
  }
  if ($null -ne $CandidateBinding) {
    $adapterEntry = Get-CandidateCoveredEntry -CandidateManifest $CandidateBinding.manifest -Path $adapter.RelativePath
    if ($null -eq $adapterEntry -or $adapterEntry.role -ne 'adapter') {
      throw ('v0.2 adapter is not covered by the candidate manifest: ' + $adapter.RelativePath)
    }
    if ($CandidateBinding.adapter_sha256 -cne $adapter.Sha256) {
      throw 'Candidate adapter binding does not match the v0.2 Arm C adapter.'
    }
    if ($CandidateBinding.kernel_sha256 -cne $kernel.Sha256 -or
        $CandidateBinding.module_manifest_sha256 -cne $registry.Sha256) {
      throw 'Candidate kernel or module registry does not match the v0.2 Arm C binding.'
    }
  }

  return [pscustomobject][ordered]@{
    Adapter = $adapter
    Kernel = $kernel
    Registry = $registry
    Implementation = $implementation
    Route = [string](Get-ManifestProperty -Object $binding -Name 'route')
    FullBundleFallback = $false
  }
}

function Copy-FrozenWorkspace {
  param(
    [string]$SourcePath,
    [string]$TargetPath
  )

  if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "Missing workspace source: $SourcePath"
  }

  New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null
  $children = Get-ChildItem -LiteralPath $SourcePath -Force
  foreach ($child in $children) {
    Copy-Item -LiteralPath $child.FullName -Destination $TargetPath -Recurse -Force
  }
}

function Get-ExecutableCommand {
  param([string[]]$Names)

  foreach ($name in $Names) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
      return $command.Source
    }
  }
  return $null
}

function Invoke-Task003PostRunEvaluator {
  param(
    [object]$Evaluator,
    [string]$WorkspacePath,
    [string]$RunPath
  )

  if ($Evaluator.Type -ne 'task-003-held-out-concurrency') {
    throw ('Unsupported post-run evaluator type: ' + $Evaluator.Type)
  }

  $stagePath = Join-Path $RunPath 'evaluator-stage'
  $stageFixturePath = Join-Path $stagePath 'fixture-public'
  $stageEvaluatorPath = Join-Path $stagePath 'evaluator-only'
  New-Item -ItemType Directory -Force -Path $stageEvaluatorPath | Out-Null
  Copy-FrozenWorkspace -SourcePath $WorkspacePath -TargetPath $stageFixturePath

  $hiddenTarget = Join-Path $stageEvaluatorPath 'hidden-concurrency-regression.js'
  Copy-Item -LiteralPath $Evaluator.HiddenRegression.AbsolutePath -Destination $hiddenTarget -Force
  $referenceTarget = Join-Path $stageEvaluatorPath 'reference-fixed/src'
  New-Item -ItemType Directory -Force -Path $referenceTarget | Out-Null
  foreach ($reference in @($Evaluator.ReferenceFiles)) {
    $evaluatorSourceRoot = Split-Path -Parent (
      Split-Path -Parent (
        Split-Path -Parent $reference.AbsolutePath
      )
    )
    $relative = [IO.Path]::GetRelativePath(
      $evaluatorSourceRoot,
      $reference.AbsolutePath
    ).Replace('\\', '/')
    $destination = Join-Path $stagePath ('evaluator-only/' + $relative)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-Item -LiteralPath $reference.AbsolutePath -Destination $destination -Force
  }

  $node = Get-ExecutableCommand -Names @('node.exe', 'node')
  $npm = Get-ExecutableCommand -Names @('npm.cmd', 'npm.exe', 'npm')
  if ([string]::IsNullOrWhiteSpace($node) -or [string]::IsNullOrWhiteSpace($npm)) {
    throw 'TASK-003 post-run evaluator requires node and npm.'
  }

  $lines = [System.Collections.Generic.List[string]]::new()
  $publicExit = 1
  $hiddenExit = 1
  Push-Location $stageFixturePath
  try {
    $publicLines = @(
      & $npm test 2>&1 |
        ForEach-Object { $_.ToString() }
    )
    $publicExit = $LASTEXITCODE
    foreach ($line in $publicLines) { $null = $lines.Add(('public: ' + $line)) }
  }
  finally {
    Pop-Location
  }

  if ($publicExit -eq 0) {
    $hiddenLines = @(
      & $node $hiddenTarget $stagePath public 2>&1 |
        ForEach-Object { $_.ToString() }
    )
    $hiddenExit = $LASTEXITCODE
    foreach ($line in $hiddenLines) { $null = $lines.Add(('held_out: ' + $line)) }
  }

  $outputPath = Join-Path $RunPath 'evaluator-output.txt'
  [IO.File]::WriteAllText(
    $outputPath,
    (($lines -join [Environment]::NewLine) + [Environment]::NewLine),
    $utf8NoBom
  )
  return [pscustomobject][ordered]@{
    status = if ($publicExit -eq 0 -and $hiddenExit -eq 0) { 'PASS' } else { 'FAIL' }
    public_tests = if ($publicExit -eq 0) { 'PASS' } else { 'FAIL' }
    held_out_regression = if ($hiddenExit -eq 0) { 'PASS' } else { 'FAIL' }
    public_exit_code = $publicExit
    held_out_exit_code = $hiddenExit
    output_file = 'evaluator-output.txt'
    evaluator_stage = 'evaluator-stage/'
  }
}

function Write-JsonFile {
  param(
    [string]$Path,
    [object]$Value
  )

  [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 10), $utf8NoBom)
}

function New-V02ContextPlan {
  param(
    [object]$CaseItem,
    [object]$ArmItem,
    [object]$Instruction,
    [object]$CandidateBinding,
    [object]$V02Binding
  )

  return [ordered]@{
    schema_version = '0.2'
    plan_type = 'context-plan'
    task_id = $CaseItem.id
    arm_id = $ArmItem.id
    instruction_sha256 = $Instruction.Sha256
    instruction_bytes = [int64]$Instruction.Bytes
    kernel_sha256 = $CandidateBinding.kernel_sha256
    module_manifest_sha256 = $CandidateBinding.module_manifest_sha256
    adapter_sha256 = $CandidateBinding.adapter_sha256
    binding = if ($null -eq $V02Binding) {
      $null
    }
    else {
      [ordered]@{
        adapter_path = $V02Binding.Adapter.RelativePath
        adapter_sha256 = $V02Binding.Adapter.Sha256
        kernel_path = $V02Binding.Kernel.RelativePath
        kernel_sha256 = $V02Binding.Kernel.Sha256
        registry_path = $V02Binding.Registry.RelativePath
        registry_sha256 = $V02Binding.Registry.Sha256
        implementation_path = $V02Binding.Implementation.RelativePath
        implementation_sha256 = $V02Binding.Implementation.Sha256
        route = $V02Binding.Route
        full_bundle_fallback = $V02Binding.FullBundleFallback
      }
    }
    route = $null
    selected_complexity = $null
    modules_loaded = @()
    status = 'PENDING_HOST_EVIDENCE'
  }
}

function Read-RecoveryReference {
  param([string]$Reference)

  if ([string]::IsNullOrWhiteSpace($Reference)) {
    return $null
  }

  $candidatePaths = [System.Collections.Generic.List[string]]::new()
  if ([IO.Path]::IsPathRooted($Reference)) {
    $null = $candidatePaths.Add($Reference)
  }
  else {
    $null = $candidatePaths.Add((Join-Path $root $Reference))
    $null = $candidatePaths.Add((Join-Path (Join-Path $root $OutputRoot) $Reference))
  }

  $packetPath = $null
  foreach ($candidatePath in @($candidatePaths)) {
    if ((Test-Path -LiteralPath $candidatePath -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $candidatePath 'run.json') -PathType Leaf)) {
      $packetPath = (Resolve-Path -LiteralPath $candidatePath).Path
      break
    }
  }
  if ([string]::IsNullOrWhiteSpace($packetPath)) {
    throw ('Recovery packet is missing: ' + $Reference)
  }

  $metadata = Get-Content -Raw -LiteralPath (Join-Path $packetPath 'run.json') | ConvertFrom-Json -Depth 80
  if ([string]::IsNullOrWhiteSpace([string]$metadata.run_id)) {
    throw ('Recovery packet has no run_id: ' + $Reference)
  }
  return [pscustomobject][ordered]@{
    path = $packetPath
    run_id = [string]$metadata.run_id
  }
}

function New-BenchmarkPacket {
  param(
    [object]$CaseItem,
    [object]$ArmItem,
    [object]$CandidateBinding,
    [object]$RecoveryReference
  )

  $timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
  $suffix = [Guid]::NewGuid().ToString('N').Substring(0, 8)
  $runId = $timestamp + '-' + $suffix + '-' + $ArmItem.id + '-' + $CaseItem.id
  $relativeOutput = Join-Path $OutputRoot $runId
  $runPath = Join-Path $root $relativeOutput
  $workspacePath = Join-Path $runPath 'workspace'

  New-Item -ItemType Directory -Force -Path $runPath | Out-Null

  $promptPath = Resolve-RepoPath $CaseItem.promptFile
  $workspaceSourcePath = Resolve-RepoPath $CaseItem.workspaceSource
  $taskProvenance = Get-TaskProvenance -CaseItem $CaseItem
  $acceptance = Get-AcceptanceProvenance -CaseItem $CaseItem
  $evaluator = Get-EvaluatorProvenance -CaseItem $CaseItem
  $v02Binding = Get-V02BindingProvenance `
    -CaseItem $CaseItem `
    -ArmItem $ArmItem `
    -CandidateBinding $CandidateBinding
  $instruction = Get-InstructionProvenance -CaseItem $CaseItem -ArmItem $ArmItem
  $fixtureSha256 = Get-DirectorySha256 -Directory $workspaceSourcePath
  $expectedFixtureHash = Get-ManifestProperty -Object $CaseItem -Name 'workspaceSha256'
  if ($Profile -eq 'v0.2' -and
      -not [string]::IsNullOrWhiteSpace([string]$expectedFixtureHash) -and
      [string]$fixtureSha256 -cne [string]$expectedFixtureHash) {
    throw ('Workspace hash mismatch: ' + $CaseItem.workspaceSource)
  }
  $sourceCommit = Get-SourceCommit
  $sourceDirty = Get-SourceDirty

  Copy-Item -LiteralPath $promptPath -Destination (Join-Path $runPath 'task.md')
  if ($instruction.AbsolutePath) {
    Copy-Item -LiteralPath $instruction.AbsolutePath -Destination (Join-Path $runPath 'instructions.md')
  }
  Copy-FrozenWorkspace -SourcePath $workspaceSourcePath -TargetPath $workspacePath
  $acceptancePacketPath = $null
  if ($acceptance.AbsolutePath) {
    $acceptancePacketPath = Join-Path $workspacePath 'acceptance.md'
    if ([IO.Path]::GetFullPath($acceptance.AbsolutePath) -ne
        [IO.Path]::GetFullPath($acceptancePacketPath)) {
      Copy-Item -LiteralPath $acceptance.AbsolutePath -Destination $acceptancePacketPath -Force
    }
  }
  $adapterPacketPath = $null
  if ($null -ne $v02Binding) {
    $adapterPacketPath = Join-Path $runPath 'adapter.md'
    Copy-Item -LiteralPath $v02Binding.Adapter.AbsolutePath -Destination $adapterPacketPath -Force
  }

  $metrics = [ordered]@{
    input_tokens = $null
    cached_input_tokens = $null
    output_tokens = $null
    reasoning_tokens = $null
    total_tokens = $null
    instruction_bytes = $instruction.Bytes
    tool_calls = $null
    agent_count = $null
    task_success = $null
    verification_status = $null
    notes = 'Fill only after deterministic or human verification.'
  }
  foreach ($metric in $CaseItem.metrics) {
    if (-not $metrics.Contains($metric)) {
      $metrics[$metric] = $null
    }
  }
  if ($Profile -eq 'v0.2') {
    $metrics['provider_status'] = $null
    $metrics['model_completion_status'] = $null
    $metrics['scope_violation'] = $null
    $metrics['evaluator_validity'] = 'UNKNOWN'
    $metrics['changed_files'] = @()
    $metrics['tests_weakened'] = $null
    $metrics['dependencies_changed'] = $null
    $metrics['failure_class'] = $null
    $metrics['verification'] = [ordered]@{
      result = 'NOT_RUN'
      evidence = @()
    }
    $metrics['stop'] = [ordered]@{
      decision = 'CONTINUE'
      reason = 'Awaiting host and evaluator evidence.'
    }
  }

  $metadata = [ordered]@{
    schema_version = '0.2'
    run_id = $runId
    created_at_utc = [DateTime]::UtcNow.ToString('o')
    case_id = $CaseItem.id
    case_title = $CaseItem.title
    arm_id = $ArmItem.id
    arm_name = $ArmItem.name
    model = $ArmItem.model
    condition = $ArmItem.condition
    source_commit = $sourceCommit
    source_dirty = $sourceDirty
    workspace_source = $CaseItem.workspaceSource
    workspace = 'workspace/'
    fixture_sha256 = $fixtureSha256
    instruction_file = $instruction.RelativePath
    instruction_sha256 = $instruction.Sha256
    instruction_bytes = $instruction.Bytes
    verification_command = $CaseItem.verificationCommand
    status = 'prepared'
    command = $Command
    arguments = $ArgumentList
    raw_output_file = $null
    metrics_file = (Join-Path $relativeOutput 'metrics.json').Replace('\', '/')
  }
  $telemetryPath = $null
  if ($Profile -eq 'v0.2') {
    $telemetryPath = Join-Path $runPath 'telemetry.json'
    $metadata['profile'] = 'v0.2'
    $metadata['candidate_id'] = $CandidateBinding.candidate_id
    $metadata['candidate_version'] = $CandidateBinding.candidate_version
    $metadata['candidate_manifest_sha256'] = $CandidateBinding.candidate_manifest_sha256
    $metadata['kernel_sha256'] = $CandidateBinding.kernel_sha256
    $metadata['module_manifest_sha256'] = $CandidateBinding.module_manifest_sha256
    $metadata['runner_sha256'] = $CandidateBinding.runner_sha256
    $metadata['adapter_sha256'] = $CandidateBinding.adapter_sha256
    $metadata['task_sha256'] = $taskProvenance.Sha256
    $metadata['acceptance_file'] = if ($null -eq $acceptancePacketPath) { $null } else { 'workspace/acceptance.md' }
    $metadata['acceptance_sha256'] = $acceptance.Sha256
    $metadata['acceptance_bytes'] = $acceptance.Bytes
    $metadata['evaluator'] = if ($evaluator.Verifier.RelativePath) {
      [ordered]@{
        type = $evaluator.Type
        run_after_provider = $true
        verifier = [ordered]@{
          path = $evaluator.Verifier.RelativePath
          expected_sha256 = $evaluator.Verifier.Sha256
          verified_sha256 = $evaluator.Verifier.Sha256
          verified = $evaluator.Verifier.Verified
        }
        hidden_regression = [ordered]@{
          path = $evaluator.HiddenRegression.RelativePath
          expected_sha256 = $evaluator.HiddenRegression.Sha256
          verified_sha256 = $evaluator.HiddenRegression.Sha256
          verified = $evaluator.HiddenRegression.Verified
        }
        reference_files = @(
          foreach ($reference in @($evaluator.ReferenceFiles)) {
            [ordered]@{
              path = $reference.RelativePath
              expected_sha256 = $reference.Sha256
              verified_sha256 = $reference.Sha256
              verified = $reference.Verified
            }
          }
        )
      }
    }
    else {
      $null
    }
    $metadata['v02_binding'] = if ($null -eq $v02Binding) { $null } else {
      [ordered]@{
        adapter_path = $v02Binding.Adapter.RelativePath
        adapter_sha256 = $v02Binding.Adapter.Sha256
        kernel_path = $v02Binding.Kernel.RelativePath
        kernel_sha256 = $v02Binding.Kernel.Sha256
        registry_path = $v02Binding.Registry.RelativePath
        registry_sha256 = $v02Binding.Registry.Sha256
        implementation_path = $v02Binding.Implementation.RelativePath
        implementation_sha256 = $v02Binding.Implementation.Sha256
        route = $v02Binding.Route
        full_bundle_fallback = $v02Binding.FullBundleFallback
      }
    }
    $metadata['telemetry_schema_version'] = '0.2'
    $metadata['telemetry_file'] = (Join-Path $relativeOutput 'telemetry.json').Replace('\', '/')
    $metadata['recovery_of'] = if ($null -eq $RecoveryReference) { $null } else { $RecoveryReference.run_id }
    $metadata['context_plan_file'] = (Join-Path $relativeOutput 'context-plan.json').Replace('\', '/')
    $contextPlanPath = Join-Path $runPath 'context-plan.json'
    $contextPlan = New-V02ContextPlan `
      -CaseItem $CaseItem `
      -ArmItem $ArmItem `
      -Instruction $instruction `
      -CandidateBinding $CandidateBinding `
      -V02Binding $v02Binding
    Write-JsonFile -Path $contextPlanPath -Value $contextPlan
  }

  Write-JsonFile -Path (Join-Path $runPath 'run.json') -Value $metadata
  Write-JsonFile -Path (Join-Path $runPath 'metrics.json') -Value $metrics
  if ($Profile -eq 'v0.2') {
    $taskHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $promptPath).Hash.ToLowerInvariant()
    $telemetry = New-ReasonKitTelemetryRecord `
      -RunId $runId `
      -TaskId $CaseItem.id `
      -Arm $ArmItem.id `
      -CandidateManifest $CandidateBinding.manifest `
      -SourceCommit $sourceCommit `
      -TaskHash $taskHash `
      -FixtureHash $fixtureSha256 `
      -KernelId 'core.tiny-kernel' `
      -KernelSha256 $CandidateBinding.kernel_sha256 `
      -ModuleManifestSha256 $CandidateBinding.module_manifest_sha256 `
      -RunnerSha256 $CandidateBinding.runner_sha256 `
      -AdapterSha256 $CandidateBinding.adapter_sha256 `
      -Context ([ordered]@{ instruction_bytes = $instruction.Bytes }) `
      -Integrity ([ordered]@{
        source_dirty = $sourceDirty
        raw_packet_sha256 = $null
        telemetry_sha256 = $null
        historical_materials_unchanged = $null
        integrity_status = 'UNVERIFIED'
      })
    Write-JsonFile -Path $telemetryPath -Value $telemetry
  }

  if ([string]::IsNullOrWhiteSpace($Command)) {
    $global:LASTEXITCODE = 0
    Write-Output ('prepared ' + $relativeOutput)
    return
  }

  $rawOutputPath = Join-Path $runPath 'model-output.txt'
  $metadata.status = 'running'
  $metadata.raw_output_file = (Join-Path $relativeOutput 'model-output.txt').Replace('\', '/')
  Write-JsonFile -Path (Join-Path $runPath 'run.json') -Value $metadata

  $oldEnvironment = @{}
  $environment = @{
    'REASONKIT_CASE_ID' = $CaseItem.id
    'REASONKIT_ARM_ID' = $ArmItem.id
    'REASONKIT_RUN_DIR' = $runPath
    'REASONKIT_WORKSPACE' = $workspacePath
    'REASONKIT_FIXTURE_SHA256' = $fixtureSha256
    'REASONKIT_SOURCE_COMMIT' = $sourceCommit
    'REASONKIT_INSTRUCTION_SHA256' = $instruction.Sha256
    'REASONKIT_INSTRUCTION_BYTES' = [string]$instruction.Bytes
    'REASONKIT_PROMPT_FILE' = (Join-Path $runPath 'task.md')
    'REASONKIT_INSTRUCTION_FILE' = $(if ($instruction.AbsolutePath) {
      Join-Path $runPath 'instructions.md'
    } else {
      ''
    })
    'REASONKIT_OUTPUT_FILE' = $rawOutputPath
    'REASONKIT_METRICS_FILE' = (Join-Path $runPath 'metrics.json')
  }
  if ($Profile -eq 'v0.2') {
    $environment['REASONKIT_PROFILE'] = 'v0.2'
    $environment['REASONKIT_TELEMETRY_FILE'] = $telemetryPath
    $environment['REASONKIT_CONTEXT_PLAN_FILE'] = $contextPlanPath
    $environment['REASONKIT_RECOVERY_OF'] = if ($null -eq $RecoveryReference) { '' } else { $RecoveryReference.run_id }
    $environment['REASONKIT_ACCEPTANCE_FILE'] = if ($null -eq $acceptancePacketPath) { '' } else { $acceptancePacketPath }
    $environment['REASONKIT_V02_ADAPTER_FILE'] = if ($null -eq $adapterPacketPath) { '' } else { $adapterPacketPath }
    $environment['REASONKIT_V02_KERNEL_FILE'] = if ($null -eq $v02Binding) { '' } else { Join-Path $runPath 'instructions.md' }
    $environment['REASONKIT_V02_ROUTE'] = if ($null -eq $v02Binding) { '' } else { $v02Binding.Route }
    $environment['REASONKIT_V02_FULL_BUNDLE_FALLBACK'] = if ($null -eq $v02Binding) { '' } else { [string]$v02Binding.FullBundleFallback }
  }

  foreach ($name in $environment.Keys) {
    $oldEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
    [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process')
  }

  $started = Get-Date
  $exitCode = 1
  $lines = @()
  try {
    Push-Location $workspacePath
    try {
      $lines = @(
        & $Command @ArgumentList 2>&1 |
          ForEach-Object { $_.ToString() }
      )
      $exitCode = $LASTEXITCODE
      if ($null -eq $exitCode) {
        $exitCode = if ($?) { 0 } else { 1 }
      }
    }
    catch {
      $lines = @($_.ToString())
      $exitCode = 127
    }
    finally {
      Pop-Location
    }

    $output = $lines -join [Environment]::NewLine
    [IO.File]::WriteAllText($rawOutputPath, $output + [Environment]::NewLine, $utf8NoBom)
    $metadata.status = if ($exitCode -eq 0) { 'completed' } else { 'failed' }
    $metadata.exit_code = $exitCode
    $metadata.duration_seconds = ((Get-Date) - $started).TotalSeconds

    if ($Profile -eq 'v0.2' -and
        $exitCode -eq 0 -and
        $null -ne $evaluator.Verifier.RelativePath) {
      try {
        $evaluatorResult = Invoke-Task003PostRunEvaluator `
          -Evaluator $evaluator `
          -WorkspacePath $workspacePath `
          -RunPath $runPath
        $metadata['evaluator_result'] = $evaluatorResult
        if ($evaluatorResult.status -ne 'PASS') {
          $metadata.status = 'failed'
        }
      }
      catch {
        $evaluatorResult = [ordered]@{
          status = 'ERROR'
          error = $_.Exception.Message
        }
        $metadata['evaluator_result'] = $evaluatorResult
        $metadata.status = 'failed'
      }
    }
  }
  finally {
    foreach ($name in $environment.Keys) {
      [Environment]::SetEnvironmentVariable($name, $oldEnvironment[$name], 'Process')
    }
  }

  if ($Profile -eq 'v0.2') {
    try {
      $updatedTelemetry = Update-V02TelemetryFromMetrics `
        -TelemetryPath $telemetryPath `
        -MetricsPath (Join-Path $runPath 'metrics.json') `
        -CandidateBinding $CandidateBinding `
        -SourceDirty $sourceDirty
      Write-JsonFile -Path $telemetryPath -Value $updatedTelemetry
    }
    catch {
      $metadata.status = 'failed'
      $metadata.telemetry_error = $_.Exception.Message
      Write-JsonFile -Path (Join-Path $runPath 'run.json') -Value $metadata
      throw
    }
  }

  Write-JsonFile -Path (Join-Path $runPath 'run.json') -Value $metadata
  $global:LASTEXITCODE = 0
  Write-Output ('ran ' + $relativeOutput + ' (exit=' + $exitCode + ')')
}

if ($Profile -eq 'v0.2') {
  $candidateBinding = Read-V02CandidateBinding
}

$recoveryReference = $null
if (-not [string]::IsNullOrWhiteSpace($RecoveryOf)) {
  if ($Profile -ne 'v0.2') {
    throw 'Recovery linkage requires -Profile v0.2.'
  }
  if ($PrepareAll) {
    throw 'Recovery linkage requires one selected case and arm, not -PrepareAll.'
  }
  $recoveryReference = Read-RecoveryReference -Reference $RecoveryOf
}

if ($PrepareAll) {
  foreach ($caseItem in $manifest.cases) {
    foreach ($armItem in $manifest.arms) {
      New-BenchmarkPacket `
        -CaseItem $caseItem `
        -ArmItem $armItem `
        -CandidateBinding $candidateBinding `
        -RecoveryReference $recoveryReference
    }
  }
  $global:LASTEXITCODE = 0
  return
}

if ([string]::IsNullOrWhiteSpace($Case) -or [string]::IsNullOrWhiteSpace($Arm)) {
  throw 'Provide -Case and -Arm, or use -PrepareAll.'
}

$selectedCase = Get-ManifestItem -Items $manifest.cases -Id $Case -Kind 'case'
$selectedArm = Get-ManifestItem -Items $manifest.arms -Id $Arm -Kind 'arm'
New-BenchmarkPacket `
  -CaseItem $selectedCase `
  -ArmItem $selectedArm `
  -CandidateBinding $candidateBinding `
  -RecoveryReference $recoveryReference
