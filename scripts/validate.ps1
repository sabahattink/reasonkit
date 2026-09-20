[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
try {
  $required = @(
    'README.md',
    'LICENSE',
    'CONTRIBUTING.md',
    'CHANGELOG.md',
    'skill/SKILL.md',
    'dist/reasonkit-min.md',
    'dist/reasonkit-coding.md',
    'dist/reasonkit-debugging.md',
    'dist/reasonkit-design.md',
    'dist/reasonkit-research.md',
    'dist/reasonkit-full.md',
    'core/constitution.md',
    'core/task-router.md',
    'core/complexity-governor.md',
    'core/token-governor.md',
    'core/agent-composer.md',
    'core/tool-router.md',
    'core/computer-use-policy.md',
    'core/verification-policy.md',
    'core/stop-policy.md',
    'adapters/chatgpt/SKILL.md',
    'adapters/codex/SKILL.md',
    'adapters/claude-code/SKILL.md',
    'adapters/generic/SYSTEM.md',
    'evals/arms/reliable-engineering-v0.1.md',
    'evals/benchmark.json',
    'evals/benchmark-v0.2.json',
    'evals/debugging/TASK-001.md',
    'evals/debugging/fixtures/task-001/parser.js',
    'evals/debugging/fixtures/task-001/parser.test.js',
    'evals/creative/TASK-002.md',
    'evals/creative/fixtures/task-002/package.json',
    'evals/creative/fixtures/task-002/app/layout.js',
    'evals/creative/fixtures/task-002/app/page.js',
    'evals/creative/fixtures/task-002/app/globals.css',
    'evals/creative/fixtures/task-002/content.json',
    'evals/creative/fixtures/task-002/public/mark.svg',
    'evals/creative/fixtures/task-002/public/README.md',
    'evals/creative/fixtures/task-002/acceptance.md',
    'evals/debugging/TASK-003.md',
    'evals/debugging/TASK-003.acceptance.md',
    'evals/debugging/fixtures/task-003/package.json',
    'evals/debugging/fixtures/task-003/src/worker.js',
    'evals/debugging/fixtures/task-003/tests/worker.test.js',
    'evals/debugging/evaluator-only/TASK-003/hidden-concurrency-regression.js',
    'evals/debugging/evaluator-only/TASK-003/verify-task-003.ps1',
    'evals/debugging/evaluator-only/TASK-003/reference-fixed/src/worker.js',
    'docs/REASONKIT-V0.2-DESIGN-RESEARCH-SPEC.md',
    'core/telemetry.schema.json',
    'core/candidate-manifest.schema.json',
    'core/tiny-kernel.md',
    'dist/v0.2/reasonkit-kernel.md',
    'scripts/build-dist.ps1',
    'scripts/run-benchmark.ps1',
    'scripts/test-v02.ps1'
  )

  function Resolve-PreparedRun {
    param([object[]]$Output)

    $preparedLine = @(
      $Output |
        Where-Object { $_.ToString().StartsWith('prepared ') } |
        Select-Object -Last 1
    )
    if ($preparedLine.Count -ne 1) {
      throw 'Benchmark runner did not return a prepared run path.'
    }

    $relativePath = $preparedLine[0].ToString().Substring('prepared '.Length).Trim()
    $absolutePath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Container)) {
      throw ('Prepared run directory is missing: ' + $relativePath)
    }
    return Get-Item -LiteralPath $absolutePath
  }

  $missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath $_ -PathType Leaf)
  })
  if ($missing.Count -gt 0) {
    throw ('Missing required files: ' + ($missing -join ', '))
  }

  $contentFiles = Get-ChildItem -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\.git\\' -and
    $_.FullName -notmatch '\\evals\\runs\\' -and
    $_.FullName -notmatch '[\\/]docs[\\/]REASONKIT-V0.2-DESIGN-RESEARCH-SPEC\.md$'
  }
  foreach ($file in $contentFiles) {
    $content = [IO.File]::ReadAllText($file.FullName)
    if ($content -match '(?m)[ \t]+$') {
      throw ('Trailing whitespace: ' + $file.FullName)
    }
    if ($content -match '(\r?\n){2,}$') {
      throw ('Extra blank line at EOF: ' + $file.FullName)
    }
  }

  $manifest = Get-Content -Raw -LiteralPath 'evals/benchmark.json' |
    ConvertFrom-Json
  if (@($manifest.arms).Count -ne 4) {
    throw 'Benchmark manifest must contain four arms.'
  }
  if (@($manifest.cases).Count -ne 2) {
    throw 'Benchmark manifest must contain two cases.'
  }
  $armIds = @($manifest.arms | ForEach-Object { $_.id })
  if (($armIds -join ',') -ne 'A,B,C,D') {
    throw 'Benchmark arms must be ordered A,B,C,D.'
  }
  foreach ($caseItem in $manifest.cases) {
    if ([string]::IsNullOrWhiteSpace($caseItem.workspaceSource)) {
      throw ('Missing workspace source for ' + $caseItem.id)
    }
    $workspaceSource = Join-Path $root $caseItem.workspaceSource
    if (-not (Test-Path -LiteralPath $workspaceSource -PathType Container)) {
      throw ('Missing workspace source: ' + $caseItem.workspaceSource)
    }
    foreach ($armId in $armIds) {
      $instructionPath = $caseItem.instructionFiles.PSObject.Properties[$armId].Value
      $expectedHash = $caseItem.instructionSha256.PSObject.Properties[$armId].Value
      if ([string]::IsNullOrWhiteSpace($instructionPath)) {
        if ($null -ne $expectedHash) {
          throw ('Instruction hash exists without a file for ' + $caseItem.id + '/' + $armId)
        }
        continue
      }
      $absoluteInstructionPath = Join-Path $root $instructionPath
      if (-not (Test-Path -LiteralPath $absoluteInstructionPath -PathType Leaf)) {
        throw ('Missing instruction file: ' + $instructionPath)
      }
      if ([string]::IsNullOrWhiteSpace($expectedHash)) {
        throw ('Missing instruction hash: ' + $instructionPath)
      }
      $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $absoluteInstructionPath).Hash
      if ($actualHash.ToLowerInvariant() -ne $expectedHash.ToLowerInvariant()) {
        throw ('Instruction hash mismatch: ' + $instructionPath)
      }
    }
  }

  & .\scripts\build-dist.ps1 -Check
  if (-not $?) {
    throw 'Generated distribution is stale.'
  }

  & .\scripts\build-dist.ps1 -V02Kernel -Check
  if (-not $?) {
    throw 'Generated v0.2 Tiny Kernel is stale.'
  }

  $null = @(
    & node 'evals/debugging/fixtures/task-001/parser.test.js' 2>&1 |
      ForEach-Object { $_.ToString() }
  )
  $baselineExit = $LASTEXITCODE
  if ($baselineExit -eq 0) {
    throw 'TASK-001 fixture must remain red before the participant fix.'
  }

  $runAOutput = @(& .\scripts\run-benchmark.ps1 -Case TASK-001 -Arm A)
  if (-not $?) {
    throw 'Benchmark runner could not prepare arm A.'
  }
  $runA = Resolve-PreparedRun -Output $runAOutput

  $runBOutput = @(& .\scripts\run-benchmark.ps1 -Case TASK-001 -Arm B)
  if (-not $?) {
    throw 'Benchmark runner could not prepare arm B.'
  }
  $runB = Resolve-PreparedRun -Output $runBOutput

  if ($null -eq $runA -or $null -eq $runB) {
    throw 'Benchmark runner did not create isolated run directories.'
  }
  $metadataA = Get-Content -Raw -LiteralPath (Join-Path $runA.FullName 'run.json') |
    ConvertFrom-Json
  $metadataB = Get-Content -Raw -LiteralPath (Join-Path $runB.FullName 'run.json') |
    ConvertFrom-Json
  if ($metadataA.fixture_sha256 -ne $metadataB.fixture_sha256) {
    throw 'Isolated runs have different fixture hashes.'
  }
  if ($metadataA.source_commit -ne $metadataB.source_commit) {
    throw 'Isolated runs have different source commits.'
  }
  foreach ($runPath in @($runA.FullName, $runB.FullName)) {
    if (-not (Test-Path -LiteralPath (Join-Path $runPath 'workspace') -PathType Container)) {
      throw ('Isolated workspace is missing: ' + $runPath)
    }
  }
  foreach ($metadata in @($metadataA, $metadataB)) {
    if ($metadata.workspace -ne 'workspace/') {
      throw 'Run metadata does not expose the isolated workspace contract.'
    }
    if ($null -eq $metadata.instruction_bytes -or
        $null -eq $metadata.fixture_sha256) {
      throw 'Run metadata is missing instruction or fixture provenance.'
    }
  }

  & .\scripts\test-v02.ps1
  if (-not $?) {
    throw 'Phase 0 v0.2 synthetic tests failed.'
  }

  & .\scripts\test-phase6.ps1
  if (-not $?) {
    throw 'Phase 6 provenance and binding tests failed.'
  }

  $global:LASTEXITCODE = 0
  Write-Output 'ReasonKit validation passed'
}
finally {
  Pop-Location
}
