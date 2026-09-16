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
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$newLine = [string][char]10

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

function Write-JsonFile {
  param(
    [string]$Path,
    [object]$Value
  )

  [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 10), $utf8NoBom)
}

function New-BenchmarkPacket {
  param(
    [object]$CaseItem,
    [object]$ArmItem
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
  $instruction = Get-InstructionProvenance -CaseItem $CaseItem -ArmItem $ArmItem
  $fixtureSha256 = Get-DirectorySha256 -Directory $workspaceSourcePath
  $sourceCommit = Get-SourceCommit
  $sourceDirty = Get-SourceDirty

  Copy-Item -LiteralPath $promptPath -Destination (Join-Path $runPath 'task.md')
  if ($instruction.AbsolutePath) {
    Copy-Item -LiteralPath $instruction.AbsolutePath -Destination (Join-Path $runPath 'instructions.md')
  }
  Copy-FrozenWorkspace -SourcePath $workspaceSourcePath -TargetPath $workspacePath

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

  Write-JsonFile -Path (Join-Path $runPath 'run.json') -Value $metadata
  Write-JsonFile -Path (Join-Path $runPath 'metrics.json') -Value $metrics

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
  }
  finally {
    foreach ($name in $environment.Keys) {
      [Environment]::SetEnvironmentVariable($name, $oldEnvironment[$name], 'Process')
    }
  }

  Write-JsonFile -Path (Join-Path $runPath 'run.json') -Value $metadata
  $global:LASTEXITCODE = 0
  Write-Output ('ran ' + $relativeOutput + ' (exit=' + $exitCode + ')')
}

if ($PrepareAll) {
  foreach ($caseItem in $manifest.cases) {
    foreach ($armItem in $manifest.arms) {
      New-BenchmarkPacket -CaseItem $caseItem -ArmItem $armItem
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
New-BenchmarkPacket -CaseItem $selectedCase -ArmItem $selectedArm
