[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [switch]$RequireFinalCandidate,
  [Parameter(Mandatory = $false)]
  [string]$ExpectedCandidateSourceCommit
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$newLine = [string][char]10
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('reasonkit-phase6-' + [Guid]::NewGuid().ToString('N'))
$outputRootName = 'evals/phase6-test-runs-' + [Guid]::NewGuid().ToString('N')
$outputRoot = Join-Path $root ($outputRootName -replace '/', '\')

function Get-PropertyValue {
  param([object]$Object, [string]$Name)

  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Assert-Throws {
  param([scriptblock]$Script, [string]$Name)

  $threw = $false
  try { & $Script } catch { $threw = $true }
  if (-not $threw) { throw ('Expected rejection did not occur: ' + $Name) }
}

function Get-FileSha256 {
  param([string]$RelativePath)

  $path = Join-Path $root ($RelativePath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw ('Missing Phase 6 file: ' + $RelativePath)
  }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
}

function Get-DirectorySha256 {
  param([string]$RelativePath)

  $directory = Join-Path $root ($RelativePath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    throw ('Missing Phase 6 workspace: ' + $RelativePath)
  }
  $records = [System.Collections.Generic.List[string]]::new()
  foreach ($file in (Get-ChildItem -LiteralPath $directory -Recurse -File | Sort-Object FullName)) {
    $relative = [IO.Path]::GetRelativePath($directory, $file.FullName).Replace('\', '/')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
    $null = $records.Add(($relative + ':' + $hash))
  }
  $payload = [string]::Join($newLine, $records)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return (([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($payload))) -replace '-', '').ToLowerInvariant())
  }
  finally { $sha.Dispose() }
}

function Write-JsonFile {
  param([string]$Path, [object]$Value)

  [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 80), $utf8NoBom)
}

function New-SyntheticCandidate {
  param([string]$Path)

  Import-Module -Name (Join-Path $root 'scripts/reasonkit-v02.psm1') -Force
  $sourceCommit = @(& git '-c' 'safe.directory=*' '-C' $root rev-parse HEAD 2>&1 | ForEach-Object { $_.ToString().Trim() })[0]
  if ([string]::IsNullOrWhiteSpace($sourceCommit)) { throw 'Unable to resolve the Phase 6 test source commit.' }
  $manifest = New-ReasonKitCandidateManifest `
    -CandidateId 'rk2-phase6-test' `
    -CandidateVersion '0.2.0-test' `
    -SourceCommit $sourceCommit `
    -RepositoryRoot $root
  $text = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $manifest
  [IO.File]::WriteAllText($Path, $text, $utf8NoBom)
  return $manifest
}

function Invoke-Runner {
  param([hashtable]$Parameters)

  $runner = Join-Path $root 'scripts/run-benchmark.ps1'
  try {
    $lines = @(& $runner @Parameters 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
  }
  catch {
    $lines = @($_.Exception.Message)
    $exitCode = 1
  }
  return [pscustomobject]@{
    ExitCode = $exitCode
    Lines = $lines
  }
}

function Get-PreparedPacket {
  param([object]$Result)

  if ($Result.ExitCode -ne 0) {
    throw ('Benchmark runner failed: ' + ($Result.Lines -join ' '))
  }
  $line = @($Result.Lines | Where-Object { $_.StartsWith('prepared ') } | Select-Object -Last 1)
  if ($line.Count -ne 1) { throw 'Benchmark runner did not return one prepared packet.' }
  $relative = $line[0].Substring('prepared '.Length).Trim()
  $path = Join-Path $root ($relative -replace '/', '\')
  if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw ('Missing prepared packet: ' + $relative) }
  return Get-Item -LiteralPath $path
}

function Save-ManifestVariant {
  param([object]$Manifest, [string]$Path)

  Write-JsonFile -Path $Path -Value $Manifest
}

function Invoke-GitText {
  param(
    [string]$RepositoryRoot,
    [string[]]$Arguments
  )

  $global:LASTEXITCODE = 0
  $lines = @(
    & git '-c' 'safe.directory=*' '-C' $RepositoryRoot @Arguments 2>&1 |
      ForEach-Object { $_.ToString().Trim() }
  )
  if ($LASTEXITCODE -ne 0) {
    throw ('Git command failed: ' + ($Arguments -join ' '))
  }
  return ($lines -join $newLine).Trim()
}

function Invoke-FinalCandidateAcceptance {
  $candidatePath = Join-Path $root 'dist/v0.2/candidate-manifest.json'
  if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
    throw 'Final candidate manifest is missing.'
  }

  $manifestBytes = [IO.File]::ReadAllBytes($candidatePath)
  if ($manifestBytes.Length -lt 2 -or $manifestBytes[$manifestBytes.Length - 1] -ne 0x0A) {
    throw 'Final candidate manifest must end with exactly one LF.'
  }
  if ($manifestBytes.Length -ge 3 -and
      $manifestBytes[0] -eq 0xEF -and
      $manifestBytes[1] -eq 0xBB -and
      $manifestBytes[2] -eq 0xBF) {
    throw 'Final candidate manifest must be UTF-8 without BOM.'
  }
  if (@($manifestBytes | Where-Object { $_ -eq 0x0D }).Count -ne 0) {
    throw 'Final candidate manifest must use LF line endings.'
  }

  $manifestText = $utf8NoBom.GetString($manifestBytes)
  $manifest = Get-Content -Raw -LiteralPath $candidatePath | ConvertFrom-Json -Depth 80
  if ($manifest.candidate_id -cne 'rk2-0.2.0' -or
      $manifest.candidate_version -cne '0.2.0') {
    throw 'Final candidate identity is not canonical.'
  }

  $expectedSourceCommit = $ExpectedCandidateSourceCommit
  if ([string]::IsNullOrWhiteSpace($expectedSourceCommit)) {
    $headCommit = Invoke-GitText -RepositoryRoot $root -Arguments @('rev-parse', 'HEAD')
    $parentCommit = Invoke-GitText -RepositoryRoot $root -Arguments @('rev-parse', 'HEAD^')
    if ($manifest.source_commit -eq $headCommit) {
      $expectedSourceCommit = $headCommit
    }
    elseif ($manifest.source_commit -eq $parentCommit) {
      $expectedSourceCommit = $parentCommit
    }
    else {
      throw 'Final candidate source_commit is neither the current nor the parent commit.'
    }
  }
  $expectedSourceCommit = $expectedSourceCommit.ToLowerInvariant()
  if ($manifest.source_commit -cne $expectedSourceCommit) {
    throw 'Final candidate source_commit does not identify the frozen source commit.'
  }

  Import-Module -Name (Join-Path $root 'scripts/reasonkit-v02.psm1') -Force
  $generated = New-ReasonKitCandidateManifest `
    -CandidateId 'rk2-0.2.0' `
    -CandidateVersion '0.2.0' `
    -SourceCommit $expectedSourceCommit `
    -RepositoryRoot $root
  $generatedText = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $generated
  $repeat = New-ReasonKitCandidateManifest `
    -CandidateId 'rk2-0.2.0' `
    -CandidateVersion '0.2.0' `
    -SourceCommit $expectedSourceCommit `
    -RepositoryRoot $root
  $repeatText = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $repeat
  $digestProjection = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $generated -ForDigest
  if ($manifestText -cne $generatedText -or
      $generatedText -cne $repeatText -or
      $manifest.candidate_manifest_sha256 -cne $generated.candidate_manifest_sha256 -or
      $generated.candidate_manifest_sha256 -cne $repeat.candidate_manifest_sha256 -or
      $digestProjection -match 'candidate_manifest_sha256' -or
      $manifestText -match '(?i)timestamp|hostname|run_id|[A-Za-z]:\\|"/[^/]') {
    throw 'Final candidate manifest is not deterministic or contains forbidden identity data.'
  }

  $null = Assert-ReasonKitCandidateManifest `
    -Manifest $manifest `
    -RepositoryRoot $root `
    -ExpectedSourceCommit $expectedSourceCommit `
    -SchemaPath (Join-Path $root 'core/candidate-manifest.schema.json') `
    -ManifestText $manifestText

  $mutationRoot = Join-Path $testRoot 'final-candidate-mutation-repo'
  New-Item -ItemType Directory -Force -Path $mutationRoot | Out-Null
  foreach ($entry in @($manifest.covered_files)) {
    $relative = [string]$entry.repository_relative_path
    $sourcePath = Join-Path $root ($relative -replace '/', '\')
    $destinationPath = Join-Path $mutationRoot ($relative -replace '/', '\')
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationPath) | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
  }
  $null = Invoke-GitText -RepositoryRoot $mutationRoot -Arguments @('init', '--quiet')
  $null = Invoke-GitText -RepositoryRoot $mutationRoot -Arguments @('config', 'user.email', 'candidate-test@example.invalid')
  $null = Invoke-GitText -RepositoryRoot $mutationRoot -Arguments @('config', 'user.name', 'ReasonKit Candidate Test')
  $null = Invoke-GitText -RepositoryRoot $mutationRoot -Arguments @('add', '-A')
  $null = Invoke-GitText -RepositoryRoot $mutationRoot -Arguments @('commit', '--quiet', '-m', 'candidate mutation fixture')
  $mutationCommit = Invoke-GitText -RepositoryRoot $mutationRoot -Arguments @('rev-parse', 'HEAD')
  $mutationManifest = New-ReasonKitCandidateManifest `
    -CandidateId 'rk2-0.2.0' `
    -CandidateVersion '0.2.0' `
    -SourceCommit $mutationCommit `
    -RepositoryRoot $mutationRoot
  $mutationKernelPath = Join-Path $mutationRoot 'core/tiny-kernel.md'
  $mutationBytes = [IO.File]::ReadAllBytes($mutationKernelPath)
  if ($mutationBytes.Length -eq 0) { throw 'Mutation fixture kernel is empty.' }
  $mutationBytes[0] = if ($mutationBytes[0] -eq 0x23) { [byte]0x2D } else { [byte]0x23 }
  [IO.File]::WriteAllBytes($mutationKernelPath, $mutationBytes)
  Assert-Throws -Name 'final candidate covered-byte mutation' -Script {
    Assert-ReasonKitCandidateManifest `
      -Manifest $mutationManifest `
      -RepositoryRoot $mutationRoot `
      -ExpectedSourceCommit $mutationCommit
  }
}

Push-Location $root
try {
  New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
  New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
  $manifestPath = Join-Path $root 'evals/benchmark-v0.2.json'
  $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json -Depth 80
  if ($manifest.version -ne '0.2' -or $manifest.profile -ne 'v0.2' -or @($manifest.cases).Count -ne 3) {
    throw 'v0.2 benchmark manifest shape is invalid.'
  }
  if ((@($manifest.cases) | ForEach-Object { $_.id }) -join ',' -cne 'TASK-001,TASK-002,TASK-003') {
    throw 'v0.2 benchmark case order is invalid.'
  }
  if ((Get-FileSha256 -RelativePath 'evals/benchmark.json') -cne 'a07c829a115470c09ee8254eb5d3084dcd1e3855c7f7adaa31874639b5530829') {
    throw 'Frozen v0.1 benchmark manifest changed.'
  }

  $task3 = @($manifest.cases | Where-Object id -eq 'TASK-003')[0]
  $expectedTask3Files = [ordered]@{
    'evals/debugging/TASK-003.md' = '3da482fa15a8ef0a15b997a8f48009fc52d38324fb983ce6866d48b8da0f2fce'
    'evals/debugging/TASK-003.acceptance.md' = '4ee526a7f9ce1c50853dbc739cfae909fb9c30d65ade6d30628dad8d32b4bcce'
    'evals/debugging/fixtures/task-003/package.json' = '1508d475494d01d9f04ee4855e2fc479fe4ea03b55c0c111c8fedcf61e6da4c3'
    'evals/debugging/fixtures/task-003/fixtures/jobs.json' = '4764b9b94c77f57938a7e7e240e57a0346d16532bb3b41c45b9bc5754ad18f21'
    'evals/debugging/fixtures/task-003/logs/README.md' = 'a34acae3bb17305890258fa86661c6cdfaae5a1db84b774f907f8183f0163229'
    'evals/debugging/fixtures/task-003/logs/retry.log' = '65334d529451a89a44eff788e3d89e96624aef080f67b9e6b1a6c1e535499686'
    'evals/debugging/fixtures/task-003/logs/worker.log' = '3f9ba176dc12dd171cf01ca0a9b49c654c35f02b714c135eddf08453d9ee7655'
    'evals/debugging/fixtures/task-003/src/idempotency.js' = 'b9cc9a5deb096a31e9d1d4e4cc51dd2e82ba99c1fe4b9fb4bfbe348cfc3e0152'
    'evals/debugging/fixtures/task-003/src/queue.js' = 'd6ea7dc08aa149cfd32de277fc3b2a36ffd8ed73c7ea09501db55342c93a66e9'
    'evals/debugging/fixtures/task-003/src/repository.js' = '1b4c43c56b952f9a0ce3a55d87100bc509222b83a93307a636d606811b1e72d6'
    'evals/debugging/fixtures/task-003/src/transaction.js' = '082cf82902dbea83560bd68585e6a01d9367736015ce91da63540d4bf33f0085'
    'evals/debugging/fixtures/task-003/src/worker.js' = '59785faf7aed22cdd398812b11a587f5f45046edf7f8967913cfef4af4541502'
    'evals/debugging/fixtures/task-003/tests/concurrency.test.js' = '7b4316cf3abe4388ccadbf4c5075df9fe58032df7ca42737d6be950231a83dd0'
    'evals/debugging/fixtures/task-003/tests/retry.test.js' = '19eb0058fd78e2bb881953beed252fbae0f2e5741eb3e54349c223b9d4259285'
    'evals/debugging/fixtures/task-003/tests/worker.test.js' = '4c74a1ab0e58d670cd264f012aff172ef13f288c0c8a2dd4b658531a0e87d8fe'
    'evals/debugging/evaluator-only/TASK-003/hidden-concurrency-regression.js' = 'fa0c9b0e62be6a5c3b1d60c0878730be4d2ceb62a641a715444951604708edef'
    'evals/debugging/evaluator-only/TASK-003/verify-task-003.ps1' = 'be84d8fff21e302fcd6d76dfd1cf02c5886a155d5bd8f0e8c9128366dc7b47b1'
    'evals/debugging/evaluator-only/TASK-003/reference-fixed/src/idempotency.js' = 'f7459aed8bdb1d9554de2b74793757dad58264d74df5bed3475c25ac1d86798e'
    'evals/debugging/evaluator-only/TASK-003/reference-fixed/src/queue.js' = 'cd6eae0d6698999dc6c056bdaf3fcf8ea90b0e6749af79717ba43726e75d6135'
    'evals/debugging/evaluator-only/TASK-003/reference-fixed/src/repository.js' = 'c979f5c6f1014fcd7a6725c2d96ffe2b046500d2f8367fccc6665f097d34a69e'
    'evals/debugging/evaluator-only/TASK-003/reference-fixed/src/transaction.js' = '082cf82902dbea83560bd68585e6a01d9367736015ce91da63540d4bf33f0085'
    'evals/debugging/evaluator-only/TASK-003/reference-fixed/src/worker.js' = '23cb14af7dc31baeec6f3730eb019a362ad82c80b6d3cf315c0786c2c6951117'
  }
  foreach ($entry in $expectedTask3Files.GetEnumerator()) {
    if ((Get-FileSha256 -RelativePath $entry.Key) -cne $entry.Value) {
      throw ('TASK-003 promoted hash mismatch: ' + $entry.Key)
    }
  }
  if ((Get-DirectorySha256 -RelativePath $task3.workspaceSource) -cne $task3.workspaceSha256) {
    throw 'TASK-003 public workspace hash mismatch.'
  }
  $evaluatorPaths = @($task3.materials.evaluatorOnly)
  $modelPaths = @($task3.materials.modelVisible)
  if (@($evaluatorPaths | Where-Object { $modelPaths -contains $_ }).Count -ne 0) {
    throw 'TASK-003 material visibility declarations overlap.'
  }

  $candidatePath = Join-Path $testRoot 'synthetic-candidate.json'
  $candidate = New-SyntheticCandidate -Path $candidatePath

  $baseRunParameters = @{
    Profile = 'v0.2'
    CandidateManifestPath = $candidatePath
    BenchmarkManifestPath = $manifestPath
    OutputRoot = $outputRootName
  }
  $preparedA = Get-PreparedPacket -Result (Invoke-Runner -Parameters ($baseRunParameters + @{ Case = 'TASK-003'; Arm = 'A' }))
  $preparedMetadata = Get-Content -Raw -LiteralPath (Join-Path $preparedA.FullName 'run.json') | ConvertFrom-Json -Depth 80
  $preparedPlanText = [IO.File]::ReadAllText((Join-Path $preparedA.FullName 'context-plan.json'))
  if (-not (Test-Path -LiteralPath (Join-Path $preparedA.FullName 'workspace/acceptance.md') -PathType Leaf) -or
      $preparedMetadata.acceptance_sha256 -cne $task3.acceptanceSha256 -or
      $preparedPlanText -match '(?i)evaluator|hidden-concurrency') {
    throw 'TASK-003 acceptance binding or hidden-evaluator separation failed.'
  }
  if (@(Get-ChildItem -LiteralPath (Join-Path $preparedA.FullName 'workspace') -Recurse -File | Where-Object { $_.FullName -match '(?i)evaluator-only|hidden-concurrency' }).Count -ne 0) {
    throw 'Hidden evaluator material entered the model workspace.'
  }

  $preparedTask2 = Get-PreparedPacket -Result (Invoke-Runner -Parameters ($baseRunParameters + @{ Case = 'TASK-002'; Arm = 'A' }))
  if ((Get-FileSha256 -RelativePath 'evals/creative/fixtures/task-002/acceptance.md') -cne
      (Get-Content -Raw -LiteralPath (Join-Path $preparedTask2.FullName 'workspace/acceptance.md') | ForEach-Object {
        $bytes = $utf8NoBom.GetBytes($_); $sha = [Security.Cryptography.SHA256]::Create(); try { ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() } finally { $sha.Dispose() }
      })) {
    throw 'TASK-002 acceptance material was not preserved in the v0.2 packet.'
  }

  $preparedC1 = Get-PreparedPacket -Result (Invoke-Runner -Parameters ($baseRunParameters + @{ Case = 'TASK-003'; Arm = 'C' }))
  $preparedC2 = Get-PreparedPacket -Result (Invoke-Runner -Parameters ($baseRunParameters + @{ Case = 'TASK-003'; Arm = 'C' }))
  $cMetadata = Get-Content -Raw -LiteralPath (Join-Path $preparedC1.FullName 'run.json') | ConvertFrom-Json -Depth 80
  $cPlan = Get-Content -Raw -LiteralPath (Join-Path $preparedC1.FullName 'context-plan.json')
  $cPlanRepeat = Get-Content -Raw -LiteralPath (Join-Path $preparedC2.FullName 'context-plan.json')
  if ($cMetadata.instruction_file -ne 'dist/v0.2/reasonkit-kernel.md' -or
      $cMetadata.instruction_sha256 -ne $task3.v02Binding.kernelSha256 -or
      $cMetadata.v02_binding.adapter_path -ne 'adapters/generic/SYSTEM.md' -or
      $cMetadata.v02_binding.full_bundle_fallback -ne $false -or
      $cPlan -cne $cPlanRepeat -or
      $cPlan -match 'dist/reasonkit-debugging\.md') {
    throw 'v0.2 Arm C binding is not explicit or deterministic.'
  }

  $legacyC = Get-PreparedPacket -Result (Invoke-Runner -Parameters @{ Case = 'TASK-001'; Arm = 'C'; OutputRoot = $outputRootName })
  $legacyMetadata = Get-Content -Raw -LiteralPath (Join-Path $legacyC.FullName 'run.json') | ConvertFrom-Json -Depth 80
  if ($legacyMetadata.instruction_file -ne 'dist/reasonkit-debugging.md' -or
      $legacyMetadata.instruction_sha256 -ne '5f586dadc2b013c7d67409e7a098bbf94a3ce9af509e223da9ef18ad8a680985') {
    throw 'v0.1 Arm C compatibility changed.'
  }

  $mutations = @(
    [pscustomobject]@{ Name = 'missing acceptance'; Mutate = { param($m); $m.cases[2].acceptanceFile = 'evals/debugging/TASK-003.acceptance-missing.md' } }
    [pscustomobject]@{ Name = 'acceptance hash mismatch'; Mutate = { param($m); $m.cases[2].acceptanceSha256 = ('0' * 64) } }
    [pscustomobject]@{ Name = 'missing evaluator'; Mutate = { param($m); $m.cases[2].evaluator.hiddenRegressionPath = 'evals/debugging/evaluator-only/TASK-003/missing.js' } }
    [pscustomobject]@{ Name = 'evaluator hash mismatch'; Mutate = { param($m); $m.cases[2].evaluator.hiddenRegressionSha256 = ('0' * 64) } }
  )
  foreach ($mutation in $mutations) {
    $variant = ($manifest | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
    & $mutation.Mutate $variant
    $variantPath = Join-Path $testRoot (($mutation.Name -replace '[^A-Za-z0-9]+', '-') + '.json')
    Save-ManifestVariant -Manifest $variant -Path $variantPath
    $invalidResult = Invoke-Runner -Parameters @{
      Profile = 'v0.2'
      CandidateManifestPath = $candidatePath
      BenchmarkManifestPath = $variantPath
      Case = 'TASK-003'
      Arm = 'A'
      OutputRoot = $outputRootName
    }
    if ($invalidResult.ExitCode -eq 0) { throw ('runner unexpectedly accepted invalid provenance: ' + $mutation.Name) }
  }

  $hostScript = Join-Path $testRoot 'phase6-provider.ps1'
  $hostText = @'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$metricsPath = $env:REASONKIT_METRICS_FILE
$metrics = Get-Content -Raw -LiteralPath $metricsPath | ConvertFrom-Json -Depth 80
$metrics.provider_status = 'COMPLETED'
$metrics.model_completion_status = 'COMPLETED'
$metrics.task_success = $null
$metrics.evaluator_validity = 'UNKNOWN'
$metrics.scope_violation = $null
$metrics.failure_class = $null
$metrics.verification = [ordered]@{ result = 'NOT_RUN'; evidence = @() }
$metrics.stop = [ordered]@{ decision = 'CONTINUE'; reason = 'Awaiting evaluator.' }
[IO.File]::WriteAllText($metricsPath, ($metrics | ConvertTo-Json -Depth 80), $utf8NoBom)
$environment = [Environment]::GetEnvironmentVariables('Process').GetEnumerator() |
  Where-Object { $_.Key -match '(?i)evaluator|hidden' } |
  ForEach-Object { [string]$_.Key + '=' + [string]$_.Value }
$observation = [ordered]@{
  acceptance_file = $env:REASONKIT_ACCEPTANCE_FILE
  adapter_file = $env:REASONKIT_V02_ADAPTER_FILE
  hidden_or_evaluator_environment = @($environment)
}
[IO.File]::WriteAllText((Join-Path $env:REASONKIT_WORKSPACE 'host-observation.json'), ($observation | ConvertTo-Json -Depth 20), $utf8NoBom)
Write-Output 'phase6-provider-output'
'@
  [IO.File]::WriteAllText($hostScript, $hostText, $utf8NoBom)
  $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
  $completed = Invoke-Runner -Parameters ($baseRunParameters + @{
      Case = 'TASK-003'
      Arm = 'A'
      Command = $pwsh
      ArgumentList = @('-NoProfile', '-File', $hostScript)
    })
  if ($completed.ExitCode -ne 0) { throw ('Provider lifecycle test failed: ' + ($completed.Lines -join ' ')) }
  $ranLine = @($completed.Lines | Where-Object { $_.StartsWith('ran ') } | Select-Object -Last 1)
  if ($ranLine.Count -ne 1) { throw 'Provider lifecycle test did not return a run packet.' }
  $ranRelative = $ranLine[0].Substring('ran '.Length).Split(' (exit=')[0]
  $ranPath = Join-Path $root ($ranRelative -replace '/', '\')
  $ranMetadata = Get-Content -Raw -LiteralPath (Join-Path $ranPath 'run.json') | ConvertFrom-Json -Depth 80
  $observation = Get-Content -Raw -LiteralPath (Join-Path $ranPath 'workspace/host-observation.json') | ConvertFrom-Json -Depth 20
  if ($null -eq $ranMetadata.evaluator_result -or
      $ranMetadata.evaluator_result.status -notin @('PASS', 'FAIL', 'ERROR') -or
      @($observation.hidden_or_evaluator_environment).Count -ne 0 -or
      $observation.acceptance_file -ne (Join-Path $ranPath 'workspace/acceptance.md') -or
      (Test-Path -LiteralPath (Join-Path $ranPath 'workspace/evaluator-stage') -PathType Container)) {
    throw 'Post-run evaluator separation or acceptance environment contract failed.'
  }
  if (-not (Test-Path -LiteralPath (Join-Path $ranPath 'evaluator-stage') -PathType Container)) {
    throw 'Post-run evaluator did not create its separate stage after provider output.'
  }

  if ($RequireFinalCandidate) {
    Invoke-FinalCandidateAcceptance
  }

  Write-Output 'phase6_task003_provenance=PASS'
  Write-Output 'phase6_manifest_binding=PASS'
  Write-Output 'phase6_negative_provenance_tests=PASS'
  Write-Output 'phase6_visibility_separation=PASS'
  Write-Output 'phase6_arm_c_binding=PASS'
  Write-Output 'phase6_runner_postrun_evaluator=PASS'
  if ($RequireFinalCandidate) {
    Write-Output 'phase6_candidate_freeze_acceptance=PASS'
  }
}
finally {
  Pop-Location
  if (Test-Path -LiteralPath $outputRoot -PathType Container) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath $testRoot -PathType Container) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}
