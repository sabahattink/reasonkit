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
    'dist/reasonkit.md',
    'dist/reasonkit-min.md',
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
    'evals/benchmark.json',
    'evals/debugging/TASK-001.md',
    'evals/debugging/fixtures/task-001/parser.js',
    'evals/debugging/fixtures/task-001/parser.test.js',
    'evals/creative/TASK-002.md',
    'scripts/build-dist.ps1',
    'scripts/run-benchmark.ps1'
  )

  $missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath $_ -PathType Leaf)
  })
  if ($missing.Count -gt 0) {
    throw ('Missing required files: ' + ($missing -join ', '))
  }

  $contentFiles = Get-ChildItem -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\.git\\' -and
    $_.FullName -notmatch '\\evals\\runs\\'
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

  & .\scripts\build-dist.ps1 -Check
  if (-not $?) {
    throw 'Generated distribution is stale.'
  }

  $null = @(
    & node 'evals/debugging/fixtures/task-001/parser.test.js' 2>&1 |
      ForEach-Object { $_.ToString() }
  )
  $baselineExit = $LASTEXITCODE
  if ($baselineExit -eq 0) {
    throw 'TASK-001 fixture must remain red before the participant fix.'
  }

  Write-Output 'ReasonKit validation passed'
}
finally {
  Pop-Location
}
