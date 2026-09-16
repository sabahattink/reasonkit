[CmdletBinding()]
param(
  [ValidateSet('TASK-001', 'TASK-002')]
  [string]$Case,

  [ValidateSet('A', 'B', 'C', 'D')]
  [string]$Arm,

  [string]$Command,

  [string[]]$ArgumentList = @(),

  [string]$OutputRoot = 'evals/runs',

  [switch]$PrepareAll
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $root 'evals/benchmark.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

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

  $item = @($Items | Where-Object { $_.id -eq $Id }) | Select-Object -First 1
  if ($null -eq $item) {
    throw "Unknown $Kind id: $Id"
  }
  return $item
}

function New-BenchmarkPacket {
  param(
    [object]$CaseItem,
    [object]$ArmItem
  )

  $timestamp = Get-Date -AsUTC -Format 'yyyyMMdd-HHmmss-fff'
  $runId = $timestamp + '-' + $ArmItem.id + '-' + $CaseItem.id
  $relativeOutput = Join-Path $OutputRoot $runId
  $runPath = Join-Path $root $relativeOutput
  New-Item -ItemType Directory -Force -Path $runPath | Out-Null

  $promptPath = Resolve-RepoPath $CaseItem.promptFile
  $instructionPath = Resolve-RepoPath $ArmItem.instructionFile
  Copy-Item -LiteralPath $promptPath -Destination (Join-Path $runPath 'task.md')
  if ($instructionPath) {
    Copy-Item -LiteralPath $instructionPath -Destination (Join-Path $runPath 'instructions.md')
  }

  $metrics = [ordered]@{}
  foreach ($metric in $CaseItem.metrics) {
    $metrics[$metric] = $null
  }
  $metrics['notes'] = 'Fill only after deterministic or human verification.'

  $metadata = [ordered]@{
    run_id = $runId
    created_at_utc = (Get-Date -AsUTC).ToString('o')
    case_id = $CaseItem.id
    case_title = $CaseItem.title
    arm_id = $ArmItem.id
    arm_name = $ArmItem.name
    model = $ArmItem.model
    condition = $ArmItem.condition
    instruction_file = $ArmItem.instructionFile
    verification_command = $CaseItem.verificationCommand
    status = 'prepared'
    command = $Command
    arguments = $ArgumentList
    raw_output_file = $null
    metrics_file = (Join-Path $relativeOutput 'metrics.json').Replace('\', '/')
  }

  $jsonOptions = @{ Depth = 8; Compress = $false }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText(
    (Join-Path $runPath 'run.json'),
    ($metadata | ConvertTo-Json @jsonOptions),
    $utf8NoBom
  )
  [IO.File]::WriteAllText(
    (Join-Path $runPath 'metrics.json'),
    ($metrics | ConvertTo-Json @jsonOptions),
    $utf8NoBom
  )

  if ([string]::IsNullOrWhiteSpace($Command)) {
    Write-Output "prepared $relativeOutput"
    return
  }

  $rawOutputPath = Join-Path $runPath 'model-output.txt'
  $metadata.status = 'running'
  $metadata.raw_output_file = (Join-Path $relativeOutput 'model-output.txt').Replace('\', '/')
  [IO.File]::WriteAllText(
    (Join-Path $runPath 'run.json'),
    ($metadata | ConvertTo-Json @jsonOptions),
    $utf8NoBom
  )

  $oldEnvironment = @{}
  $environment = @{
    'REASONKIT_CASE_ID' = $CaseItem.id
    'REASONKIT_ARM_ID' = $ArmItem.id
    'REASONKIT_PROMPT_FILE' = (Join-Path $runPath 'task.md')
    'REASONKIT_INSTRUCTION_FILE' = $(if ($instructionPath) { Join-Path $runPath 'instructions.md' } else { '' })
    'REASONKIT_OUTPUT_FILE' = $rawOutputPath
  }
  foreach ($name in $environment.Keys) {
    $oldEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
    [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process')
  }

  $started = Get-Date
  try {
    $lines = @(& $Command @ArgumentList 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    $output = $lines -join [Environment]::NewLine
    [IO.File]::WriteAllText($rawOutputPath, $output + [Environment]::NewLine, $utf8NoBom)
    $metadata.status = if ($exitCode -eq 0) { 'completed' } else { 'failed' }
    $metadata.exit_code = $exitCode
    $metadata.duration_seconds = ((Get-Date) - $started).TotalSeconds
  }
  finally {
    foreach ($name in $environment.Keys) {
      [Environment]::SetEnvironmentVariable($name, $oldEnvironment[$name], 'Process')
    }
  }

  [IO.File]::WriteAllText(
    (Join-Path $runPath 'run.json'),
    ($metadata | ConvertTo-Json @jsonOptions),
    $utf8NoBom
  )
  Write-Output "ran $relativeOutput (exit=$($metadata.exit_code))"
}

if ($PrepareAll) {
  foreach ($caseItem in $manifest.cases) {
    foreach ($armItem in $manifest.arms) {
      New-BenchmarkPacket -CaseItem $caseItem -ArmItem $armItem
    }
  }
  return
}

if ([string]::IsNullOrWhiteSpace($Case) -or [string]::IsNullOrWhiteSpace($Arm)) {
  throw 'Provide -Case and -Arm, or use -PrepareAll.'
}

$selectedCase = Get-ManifestItem -Items $manifest.cases -Id $Case -Kind 'case'
$selectedArm = Get-ManifestItem -Items $manifest.arms -Id $Arm -Kind 'arm'
New-BenchmarkPacket -CaseItem $selectedCase -ArmItem $selectedArm
