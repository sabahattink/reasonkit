[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script:PhaseRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
$script:BaselineCommit = '4229cc36d4ad90596b1da64bf7ce7fb953ed5ed9'
$script:BaselineTag = 'v0.1.0'
$script:FrozenDesignPath = 'docs/REASONKIT-V0.2-DESIGN-RESEARCH-SPEC.md'
$script:FrozenDesignSha256 = 'c473bb3e15eb2f607f8aaa206821282b788e35e38dd7f027220dc58ec5b33e36'
$script:TokenizerPackage = 'tiktoken'
$script:TokenizerVersion = '0.14.0'
$script:TokenizerEncoding = 'cl100k_base'
$script:TokenizerInstallation = 'python -m pip install --disable-pip-version-check --no-input tiktoken==0.14.0'
$script:TokenizerNormalization = 'UTF-8 without BOM; LF; trailing horizontal whitespace removed; exactly one final LF'
$script:TokenizerMeasurementKind = 'build_estimate'

$script:FrozenV01Hashes = [ordered]@{
        '.editorconfig' = 'ea3d46f76380a5f059c4b1387e528ae6690c9444a077f4004775a9278ace0d01'
        '.gitattributes' = 'a1b15fe6988a667c31709be141a45a3b9252813261637a8b257d42e09febdd51'
        '.gitignore' = '2166c8ff1cd690e2861d90f902163124374f665b35970c30f9b9fb2bc51d914a'
        'CHANGELOG.md' = 'd0f54079e48242470de46ad7e35c5c7af681e320d92b10e731ab08108f710185'
        'CONTRIBUTING.md' = '6e979e831a2067dd381ec2227fab2cc999f12ac972d04391f557eaa946220590'
        'LICENSE' = 'b28874cf0f738f138b609e0f97bbb0c7a5093fc8cdff66ca78f302a905ef6fe8'
        'README.md' = 'dbf11ed11db6d9a48ed8d904afd3c48e14a7df5f54d61f9ad577d73363849fee'
        'adapters/chatgpt/README.md' = '7090a8092a9e076ebfab5d0490477718bb249a27a4fae96bfca7b4eeceb0c714'
        'adapters/chatgpt/SKILL.md' = 'bd7cda721606e7e5566333414d29ce149091549d5baae0927940daea53db95f7'
        'adapters/claude-code/README.md' = '8ca9d86f17a18078062517c185277c6bf32132254644ee978ac75406fc4ecf2b'
        'adapters/claude-code/SKILL.md' = 'c80f66769c61dfe1cc62e7ebdc3057639349cdddc1e40983c298a61fc4aee906'
        'adapters/codex/README.md' = '328c335ae1ea09eedc694e3f6e7c058c214b77306f2ec7b2e71839ad13b5ec72'
        'adapters/codex/SKILL.md' = '3da4200d5218ddeaecad2169c41028df8754eb04ea6c68c6cfa4450450a03b1a'
        'adapters/generic/README.md' = 'f190b882f3084019434be9a2da6a6f23208a6a1031f51f57134b4c2d2c66c5c5'
        'adapters/generic/SYSTEM.md' = '15cb7d805605f4a7326bbad925be89c7d5000e389677757e16cc7c447b42b251'
        'agents/adversarial-reviewer.md' = '91e75a898849bcec8d9a0e2459bdd2b8e6054d5864fa047bf15ef0fd4c0ab6cf'
        'agents/art-director.md' = 'df2c068bd970214ae6e925b7ec64d181c0ebaa06c47cf65822c29d3b56c3fc73'
        'agents/creative-technologist.md' = '2984a9857910093c00426ee82e95ccacdf9d33a4baa5422be5c6c9312338bbcc'
        'agents/design-critic.md' = '98fe557f4f1dbb6b1ca46d60ac7268b238dccd2bcc363946d1078dd60ad320a7'
        'agents/dissent.md' = 'aa2a58f80da086f6d433faabc708afe4dc34655f321e663b8615b2d6283a8fd8'
        'agents/implementer.md' = 'db3b4697a3d5e3a28cb3c629ab9cd832bc466eec9899296aa729cc39a5071ffb'
        'agents/investigator.md' = '75c0d3e71fc08f86d89de977e98b945b2be4c21e5a7a71f4938f57584a31aeda'
        'agents/reference-researcher.md' = '49a282f0589a1c53a4cf00633e6252fedf616d93c9f6781d37096b3db5a3be94'
        'agents/user-journey-tester.md' = 'fafa418c1fdfd4e71c2afbb53c9f5380e60b0ac03b9e30b96e2798615191b395'
        'agents/verifier.md' = 'daf7153dbf168409a062bee1179aaad9d98d441822c7c8c442d6713a1ed8ec4e'
        'agents/visual-inspector.md' = '9d71d98f37f78b701cdb7251d72c0cdbdd2ff0ae6d944f64ce5d15568a5d6dca'
        'core/agent-composer.md' = '950dc1e5e28f956f1cd60dffc1409ed9ad6dd75599ee1ee2f18ef017b5548e5c'
        'core/complexity-governor.md' = 'abcb58d679f5d80b32f12da7335aa3b7824cac22c09d14c20ed8089955ff1509'
        'core/computer-use-policy.md' = '59f95edbe7fd1e4ce0c51324334776979e033a31f9c7ab7b084f50670c5b0cda'
        'core/constitution.md' = 'f270c286a8d7a1a161d576f3b0c209e89acaab266f44617a61de2454c2beaf01'
        'core/stop-policy.md' = '61a566d076e56d129d58406f0a266ef39f022db536e2f6e4f8d3da65e41970e8'
        'core/task-router.md' = '711945d4343a1858a94d0387950d64ee31d7d710240ab4127d8c089507a4b0b9'
        'core/token-governor.md' = '23bed925fea58be44f91edb0b801c5e36c52c024b236e02c886b2804174da60f'
        'core/tool-router.md' = '6c7aeb94f67019511e6dbeaf3044abf6658385cf0319d7c1ed6dd48bbac6df02'
        'core/verification-policy.md' = 'fc459cec167072b072139a28a24ea6b6c3e3b95c0ba87d49c1322f85b36902b1'
        'dist/README.md' = '0d3af3ea4c9e093124eea153845a8b189d07f0ffef3cbb517621797ca2d8f88d'
        'dist/reasonkit-coding.md' = '237b79e5959e889c434a446b625769606d63f447e05508d2fdf5caf9efa985e3'
        'dist/reasonkit-debugging.md' = '5f586dadc2b013c7d67409e7a098bbf94a3ce9af509e223da9ef18ad8a680985'
        'dist/reasonkit-design.md' = 'f700fe2876b0a296d556904fc514b13a692e869a04efd172e5d9b3eb879667df'
        'dist/reasonkit-full.md' = '5a54a45a4a421c21d5f72d0a46069e0a7f8028dd8d30dcba7e0e643916acf3ae'
        'dist/reasonkit-min.md' = 'ebb32a24a414d04dc10a870a0c8b6a068b2eb34f115e0d31f0edc347aaed7266'
        'dist/reasonkit-research.md' = '3b6e3f96d6d383720cb9216950c4a97178d067dfadadf0b3d82246ca2c7abdc8'
        'evals/README.md' = '6c2b11ff859b21d0954680fba0f44c09994b6defa5cfc4ece69d2bc06c97c3d1'
        'evals/architecture/README.md' = 'ebd128b21b56e2405505ac926fba8bc07c9ac78ecd9bdcaa7ca8c69e7c3ea5f0'
        'evals/arms/README.md' = 'b5c39149d849770af65d1c731454ff28a874cf2e83f0d8974a79fe2cf03da6b2'
        'evals/arms/reliable-engineering-v0.1.md' = '67dbb7a8f276ea6f803ab7ffbd6bd56423be9cc8130db492ed4528fd5b4f98d6'
        'evals/benchmark.json' = 'a07c829a115470c09ee8254eb5d3084dcd1e3855c7f7adaa31874639b5530829'
        'evals/coding/README.md' = 'de997c95eaebace4f60c3d5f9a708241fd709c12808b19f84f89aee518b64cad'
        'evals/creative/README.md' = 'e75fead3404a328bf3ede7b49440095d417154feef836eed9172fe3d1cbccf1b'
        'evals/creative/TASK-002.md' = '3c67e875f0628f1b34d734653862119d0a9b4502ed66672cca133f848ef2d2a2'
        'evals/creative/fixtures/task-002/acceptance.md' = '7f3da9a71c6b8f0011e4be19b80f954886c45e4574942a33cedce56d07ef9c61'
        'evals/creative/fixtures/task-002/app/globals.css' = 'ef4e25fb0e5a3b098081f726a3f07688d6e1dcb2376db9ab795a4f29a4b5ff7c'
        'evals/creative/fixtures/task-002/app/layout.js' = '30cfd2233c6d992af2457af0cd68502c0db945346f0138307817e3e4d2164640'
        'evals/creative/fixtures/task-002/app/page.js' = '3ec1f718a29cdcd72be353792e8f8043d609bdc5ee7539b72ffd43dcbb18b554'
        'evals/creative/fixtures/task-002/content.json' = 'ac7b946d01bff5446b37d7fb902ac4b966059459040deddf4bf6629418dd2974'
        'evals/creative/fixtures/task-002/package.json' = 'a9a227d5cdb5cab81627593cba9349348f255c7c963020fbb7d6458b81d52bff'
        'evals/creative/fixtures/task-002/public/README.md' = '2162065bdd57ccc241d62fccce6d2b590a01a6a8a2edfe5e75014db163c6e733'
        'evals/creative/fixtures/task-002/public/mark.svg' = 'f8be72938910ac8ab57b520fe224cf0fc1d08b6bdaee18a098f4c0125f410b77'
        'evals/debugging/README.md' = '02744a0d35b80ae9e0ef63e5121571cb4c1154511aa2ef5c81df03035d16fb3e'
        'evals/debugging/TASK-001.md' = 'e857532205e543bbfb2585035c7b6cfe164b08b4aba4f958b5308f6f5fb6756a'
        'evals/debugging/fixtures/task-001/parser.js' = 'b5904d98c0236d3aa0f2530dda970d7df53b2d28ed5c2218716a184ada9ab4ad'
        'evals/debugging/fixtures/task-001/parser.test.js' = 'ff720ce4ae79df831e36b1d520749dba2502711e4d84eb4b077c8d7359f66cd2'
        'protocols/architecture.md' = '2077081286fc638c9db54c1f0c8afe77e798b00b09f564799052ea5ff16640f2'
        'protocols/coding.md' = '6bba9439fe3a4c0e24a3a22bd379e53ea164f4fa74f9d2309bd9fc79c38cc01b'
        'protocols/computer-use.md' = 'bef03d45499330183d49739356f37101a77961e7743fd31c07fb9a8ebd3092b9'
        'protocols/debugging.md' = 'de15149fc362bc1b66ddb354a1a36be1853ed504b80e2ba4f5ff2d5fa7f4b766'
        'protocols/design.md' = 'f319108a6cfd60f5b5e8c862d32d57f37cc21268d84b280c72b1569b94c09bba'
        'protocols/research.md' = '1f8bb6d755c78d390a25c075c1035688c87584f7914ceb6b584931d66b018bb9'
        'scripts/build-dist.ps1' = '01fcec23ff0796018b4355981705faaa68408bf2834d31c4e54fd8ed487a4663'
        'scripts/run-benchmark.ps1' = '5ebfae0efa14d6e18aedf9099defdf1854ff85d20e334a51536a5726883ef65c'
        'skill/SKILL.md' = '7a7eda910c21de45a9f62cb79d66a038b589d81808fe1cb1444217e732767a18'
        'taste/anti-generic.md' = 'a0f95fe42f2dfd1cd7d2849d9b4bfdc48ecb4b643d4d0b151acf0cc38d44c30b'
        'taste/critique.md' = 'd1a8643b4bcc17090c108394ac2ce37131a10322c558b3e08e4611f262dd4f3b'
        'taste/visual-reasoning.md' = 'a92c8b09a6ca04ffe9e7e19b0d4eadaf4c3251df36fc1ba867922cc5051499ca'
}

function Get-PropertyValue {
  param(
    [Parameter(Mandatory = $false)]
    [object]$Object,
    [Parameter(Mandatory = $true)]
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

function Test-HasProperty {
  param(
    [Parameter(Mandatory = $false)]
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if ($null -eq $Object) {
    return $false
  }
  return ($null -ne $Object.PSObject.Properties[$Name])
}

function Invoke-GitText {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  $output = @(
    & git '-c' 'safe.directory=*' '-C' $script:PhaseRoot @Arguments 2>&1 |
      ForEach-Object { $_.ToString() }
  )
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    throw ('git command failed: ' + ($Arguments -join ' ') + ': ' + ($output -join ' '))
  }
  return (($output -join [Environment]::NewLine).Trim())
}

function Get-FileSha256 {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $absolutePath = Join-Path $script:PhaseRoot ($RelativePath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    throw ('Missing file: ' + $RelativePath)
  }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $absolutePath).Hash.ToLowerInvariant()
}

function Normalize-RepoPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $normalized = $Path.Replace('\', '/')
  while ($normalized.StartsWith('./', [StringComparison]::Ordinal)) {
    $normalized = $normalized.Substring(2)
  }
  if ([string]::IsNullOrWhiteSpace($normalized) -or
      $normalized.StartsWith('/') -or
      $normalized -match '^[A-Za-z]:/' -or
      $normalized -match '(^|/)\.\.?(/|$)' -or
      $normalized -match '//') {
    throw ('Non-canonical repository path: ' + $Path)
  }
  return $normalized
}

function ConvertTo-CanonicalValue {
  param(
    [Parameter(Mandatory = $false)]
    [object]$Value
  )

  if ($null -eq $Value) {
    return $null
  }

  if ($Value -is [System.Collections.IDictionary]) {
    $ordered = [ordered]@{}
    foreach ($key in @($Value.Keys | Sort-Object)) {
      $ordered[$key] = ConvertTo-CanonicalValue -Value $Value[$key]
    }
    return $ordered
  }

  if ($Value -is [PSCustomObject]) {
    $ordered = [ordered]@{}
    foreach ($property in @($Value.PSObject.Properties.Name | Sort-Object)) {
      $ordered[$property] = ConvertTo-CanonicalValue -Value (Get-PropertyValue -Object $Value -Name $property)
    }
    return $ordered
  }

  if (($Value -is [System.Collections.IEnumerable]) -and
      -not ($Value -is [string])) {
    $items = @(
      foreach ($item in $Value) {
        ConvertTo-CanonicalValue -Value $item
      }
    )
    return ,$items
  }

  return $Value
}

function ConvertTo-CanonicalJson {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Value
  )

  $canonical = ConvertTo-CanonicalValue -Value $Value
  return (($canonical | ConvertTo-Json -Compress -Depth 50) + [string][char]10)
}

function Get-TextSha256 {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
  $bytes = $utf8NoBom.GetBytes($Text)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
  }
  finally {
    $sha.Dispose()
  }
}

function Normalize-AuthoredText {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $normalized = $Text.Replace(([string][char]13 + [string][char]10), [string][char]10)
  $normalized = $normalized.Replace([string][char]13, [string][char]10)
  $normalized = [Regex]::Replace($normalized, '[ \t]+(?=\n|$)', '')
  while ($normalized.EndsWith([string][char]10, [StringComparison]::Ordinal)) {
    $normalized = $normalized.Substring(0, $normalized.Length - 1)
  }
  return $normalized + [string][char]10
}

function Get-PythonExecutable {
  if (-not [string]::IsNullOrWhiteSpace($env:REASONKIT_PYTHON)) {
    if (-not (Test-Path -LiteralPath $env:REASONKIT_PYTHON -PathType Leaf)) {
      throw ('REASONKIT_PYTHON does not exist: ' + $env:REASONKIT_PYTHON)
    }
    return $env:REASONKIT_PYTHON
  }

  foreach ($name in @('python', 'python3', 'py')) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
      return $command.Source
    }
  }
  throw 'No Python executable is available for the pinned tokenizer.'
}

function Get-TokenizerVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Python
  )

  $output = @(
    & $Python -c "import importlib.metadata as m; print(m.version('tiktoken'))" 2>&1 |
      ForEach-Object { $_.ToString() }
  )
  if ($LASTEXITCODE -ne 0) {
    throw ('Pinned tokenizer package is unavailable: ' + ($output -join ' '))
  }
  return (($output | Select-Object -Last 1).ToString().Trim())
}

function Get-TokenizerEstimate {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [Parameter(Mandatory = $true)]
    [string]$Python
  )

  $normalized = Normalize-AuthoredText -Text $Text
  $temporaryPath = Join-Path ([IO.Path]::GetTempPath()) ('reasonkit-v02-token-' + [Guid]::NewGuid().ToString('N') + '.txt')
  $utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
  [IO.File]::WriteAllText($temporaryPath, $normalized, $utf8NoBom)
  try {
    $code = "import pathlib,sys,tiktoken; data=pathlib.Path(sys.argv[1]).read_bytes().decode('utf-8'); enc=tiktoken.get_encoding('cl100k_base'); print(len(enc.encode(data, disallowed_special=())))"
    $output = @(
      & $Python -c $code $temporaryPath 2>&1 |
        ForEach-Object { $_.ToString() }
    )
    if ($LASTEXITCODE -ne 0) {
      throw ('Tokenizer estimate failed: ' + ($output -join ' '))
    }
    $last = (($output | Select-Object -Last 1).ToString().Trim())
    if ($last -notmatch '^[0-9]+$') {
      throw ('Tokenizer returned a non-numeric estimate: ' + $last)
    }
    return [int]$last
  }
  finally {
    Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
  }
}

function Assert-TelemetryContract {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Document
  )

  foreach ($group in @('identity', 'provenance', 'context', 'specialists', 'outcome', 'provider_measurements', 'integrity')) {
    if (-not (Test-HasProperty -Object $Document -Name $group)) {
      throw ('Telemetry group is missing: ' + $group)
    }
  }

  $outcome = Get-PropertyValue -Object $Document -Name 'outcome'
  $failureClass = Get-PropertyValue -Object $outcome -Name 'failure_class'
  $allowedFailureClasses = @($null, 'MODEL_FAIL', 'EVALUATOR_INVALID', 'PROVIDER_ABORTED')
  if ($allowedFailureClasses -notcontains $failureClass) {
    throw ('Unknown failure class: ' + $failureClass)
  }

  $providerStatus = Get-PropertyValue -Object $outcome -Name 'provider_status'
  $taskSuccess = Get-PropertyValue -Object $outcome -Name 'task_success'
  $evaluatorValidity = Get-PropertyValue -Object $outcome -Name 'evaluator_validity'
  if ($failureClass -eq 'PROVIDER_ABORTED' -and $providerStatus -ne 'ABORTED') {
    throw 'PROVIDER_ABORTED requires provider_status=ABORTED.'
  }
  if ($failureClass -eq 'MODEL_FAIL' -and $taskSuccess -ne $false) {
    throw 'MODEL_FAIL requires task_success=false.'
  }
  if ($failureClass -eq 'EVALUATOR_INVALID' -and $evaluatorValidity -ne 'INVALID') {
    throw 'EVALUATOR_INVALID requires evaluator_validity=INVALID.'
  }

  $measurements = Get-PropertyValue -Object $Document -Name 'provider_measurements'
  foreach ($field in @('input_tokens', 'cached_input_tokens', 'output_tokens', 'reasoning_tokens', 'total_tokens', 'tool_calls', 'agent_count', 'duration_seconds')) {
    if (-not (Test-HasProperty -Object $measurements -Name $field)) {
      throw ('Provider measurement field is missing: ' + $field)
    }
  }

  $specialists = Get-PropertyValue -Object $Document -Name 'specialists'
  $specialistCount = Get-PropertyValue -Object $specialists -Name 'specialist_count'
  $reports = @(Get-PropertyValue -Object $specialists -Name 'specialist_reports')
  if ($specialistCount -gt 3 -or $reports.Count -gt 3) {
    throw 'Specialist cap exceeded.'
  }
}

function Assert-CandidateContract {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Document
  )

  foreach ($field in @('candidate_id', 'candidate_version', 'source_commit', 'candidate_manifest_sha256', 'kernel_sha256', 'module_manifest_sha256', 'covered_files')) {
    if (-not (Test-HasProperty -Object $Document -Name $field)) {
      throw ('Candidate field is missing: ' + $field)
    }
  }

  $paths = @(
    (Get-PropertyValue -Object $Document -Name 'covered_files') |
      ForEach-Object { Get-PropertyValue -Object $_ -Name 'repository_relative_path' }
  )
  $duplicates = @($paths | Group-Object | Where-Object Count -gt 1)
  if ($duplicates.Count -gt 0) {
    throw ('Duplicate candidate path: ' + ($duplicates[0].Name))
  }
  foreach ($path in $paths) {
    if ((Normalize-RepoPath -Path $path) -ne $path) {
      throw ('Candidate path is not canonical: ' + $path)
    }
  }
}

function Assert-SchemaContract {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,
    [Parameter(Mandatory = $true)]
    [string[]]$RequiredTopLevelFields
  )

  $absolutePath = Join-Path $script:PhaseRoot ($RelativePath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    throw ('Schema is missing: ' + $RelativePath)
  }
  $schema = Get-Content -Raw -LiteralPath $absolutePath | ConvertFrom-Json
  if (-not (Test-HasProperty -Object $schema -Name '$schema')) {
    throw ('Schema meta field is missing: ' + $RelativePath)
  }
  $required = @(Get-PropertyValue -Object $schema -Name 'required')
  foreach ($field in $RequiredTopLevelFields) {
    if ($required -notcontains $field) {
      throw ('Schema required field is missing: ' + $RelativePath + '/' + $field)
    }
  }
  return $schema
}

function Assert-Throws {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Script,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $threw = $false
  try {
    & $Script
  }
  catch {
    $threw = $true
  }
  if (-not $threw) {
    throw ('Expected rejection did not occur: ' + $Name)
  }
}

Push-Location $script:PhaseRoot
try {
  $resolvedBaseline = Invoke-GitText -Arguments @('rev-parse', ($script:BaselineCommit + '^{commit}'))
  if ($resolvedBaseline -ne $script:BaselineCommit) {
    throw 'The v0.1 baseline commit does not resolve to the expected object.'
  }

  $resolvedTag = Invoke-GitText -Arguments @('rev-parse', ($script:BaselineTag + '^{commit}'))
  if ($resolvedTag -ne $script:BaselineCommit) {
    throw 'The v0.1.0 tag no longer points to the frozen baseline commit.'
  }

  $ancestorOutput = @(
    & git '-c' 'safe.directory=*' '-C' $script:PhaseRoot merge-base --is-ancestor $script:BaselineCommit HEAD 2>&1
  )
  if ($LASTEXITCODE -ne 0) {
    throw 'The frozen v0.1 baseline is not an ancestor of the current checkout.'
  }

  $mirrorHash = Get-FileSha256 -RelativePath $script:FrozenDesignPath
  if ($mirrorHash -ne $script:FrozenDesignSha256) {
    throw ('Frozen design mirror hash mismatch. Expected ' + $script:FrozenDesignSha256 + ', got ' + $mirrorHash)
  }

  foreach ($entry in $script:FrozenV01Hashes.GetEnumerator()) {
    $actual = Get-FileSha256 -RelativePath $entry.Key
    if ($actual -ne $entry.Value) {
      throw ('Frozen v0.1 artifact changed: ' + $entry.Key + ' expected ' + $entry.Value + ' got ' + $actual)
    }
  }

  $task004Matches = @(
    Get-ChildItem -LiteralPath $script:PhaseRoot -Recurse -Force -ErrorAction SilentlyContinue |
      Where-Object {
        $_.FullName -notmatch '[\\\/]\.git([\\\/]|$)' -and
        $_.FullName -notmatch '[\\\/]evals[\\\/]runs([\\\/]|$)' -and
        $_.Name -match 'TASK-004'
      }
  )
  if ($task004Matches.Count -gt 0) {
    throw 'TASK-004 material exists.'
  }

  $candidateMatches = @(
    Get-ChildItem -LiteralPath $script:PhaseRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
      Where-Object {
        $_.FullName -notmatch '[\\\/]\.git([\\\/]|$)' -and
        $_.FullName -notmatch '[\\\/]evals[\\\/]runs([\\\/]|$)' -and
        $_.Name -match '^(candidate|candidate-manifest)([-_].*)?\.(json|yaml|yml)$' -and
        $_.Name -ne 'candidate-manifest.schema.json'
      }
  )
  if ($candidateMatches.Count -gt 0) {
    throw 'A v0.2 candidate instance exists.'
  }

  $telemetrySchema = Assert-SchemaContract -RelativePath 'core/telemetry.schema.json' -RequiredTopLevelFields @('schema_version', 'identity', 'provenance', 'context', 'specialists', 'outcome', 'provider_measurements', 'integrity')
  $candidateSchema = Assert-SchemaContract -RelativePath 'core/candidate-manifest.schema.json' -RequiredTopLevelFields @('candidate_id', 'candidate_version', 'source_commit', 'candidate_manifest_sha256', 'kernel_sha256', 'module_manifest_sha256', 'covered_files')

  $hash64 = ('0' * 64) -join ''
  $minimalTelemetry = [ordered]@{
    schema_version = '0.2'
    identity = [ordered]@{
      run_id = 'synthetic-phase-0'
      task_id = 'synthetic'
      arm = 'A'
      candidate_id = $null
      candidate_version = $null
      candidate_manifest_sha256 = $null
      telemetry_schema_version = '0.2'
    }
    provenance = [ordered]@{
      source_tag = $script:BaselineTag
      source_commit = $script:BaselineCommit
      task_hash = $hash64
      fixture_hash = $hash64
      host_fingerprint = $null
      kernel_id = $null
      kernel_sha256 = $null
      module_manifest_sha256 = $null
      runner_sha256 = $null
      adapter_sha256 = $null
    }
    context = [ordered]@{
      kernel_bytes = $null
      kernel_tokens = $null
      loader_index_bytes = $null
      loader_index_tokens = $null
      loader_request_count = 0
      loader_decision_duration_ms = $null
      route = $null
      selected_complexity = $null
      modules_loaded = @()
      omitted_context = [ordered]@{
        source_manifest_sha256 = $null
        module_ids = @()
        bytes = $null
        tokens = $null
        derivation = 'not applicable in Phase 0 synthetic packet'
        status = 'not_applicable'
      }
      full_bundle = [ordered]@{
        loaded = $false
        escalation_reason = $null
        requested_by = $null
        approved_by_or_gate = $null
        source_hash = $null
        loaded_bytes = $null
        loaded_tokens_if_deterministic = $null
      }
      instruction_bytes = 0
    }
    specialists = [ordered]@{
      specialist_gate = [ordered]@{
        considered = $false
        started = $false
        trigger = @()
        evidence_state = 'not_considered'
        competing_hypotheses = 0
        rejection_reason = 'Phase 0 synthetic packet'
        role = $null
      }
      specialist_roles = @()
      specialist_count = 0
      specialist_reports = @()
    }
    outcome = [ordered]@{
      verification = [ordered]@{
        result = 'NOT_RUN'
        evidence = @('synthetic Phase 0 packet')
      }
      stop = [ordered]@{
        decision = 'STOP'
        reason = 'synthetic packet complete'
      }
      provider_status = 'COMPLETED'
      model_completion_status = 'COMPLETED'
      task_success = $true
      scope_violation = $false
      evaluator_validity = 'NOT_APPLICABLE'
      changed_files = @()
      tests_weakened = $false
      dependencies_changed = $false
      failure_class = $null
    }
    provider_measurements = [ordered]@{
      input_tokens = $null
      cached_input_tokens = $null
      output_tokens = $null
      reasoning_tokens = $null
      total_tokens = $null
      tool_calls = $null
      agent_count = $null
      duration_seconds = $null
    }
    integrity = [ordered]@{
      source_dirty = $null
      raw_packet_sha256 = $null
      telemetry_sha256 = $null
      historical_materials_unchanged = $null
      integrity_status = 'UNVERIFIED'
    }
  }
  $minimalTelemetryJson = $minimalTelemetry | ConvertTo-Json -Depth 50
  $minimalTelemetryRoundTrip = $minimalTelemetryJson | ConvertFrom-Json
  Assert-TelemetryContract -Document $minimalTelemetryRoundTrip

  $malformedTelemetry = $minimalTelemetryJson | ConvertFrom-Json
  $malformedTelemetry.outcome.failure_class = 'NOT_A_FAILURE_CLASS'
  Assert-Throws -Name 'malformed failure class' -Script {
    Assert-TelemetryContract -Document $malformedTelemetry
  }

  $providerNullTelemetry = $minimalTelemetryJson | ConvertFrom-Json
  Assert-TelemetryContract -Document $providerNullTelemetry

  $syntheticCandidate = [ordered]@{
    candidate_id = 'rk2-synthetic-0001'
    candidate_version = '0.2.0-synthetic'
    source_commit = $script:BaselineCommit
    candidate_manifest_sha256 = $hash64
    kernel_sha256 = $hash64
    module_manifest_sha256 = $hash64
    covered_files = @(
      [ordered]@{
        repository_relative_path = 'core/telemetry.schema.json'
        sha256 = $hash64
        bytes = 1
        role = 'telemetry_schema'
        module_id = $null
      }
    )
  }
  $syntheticCandidateJson = $syntheticCandidate | ConvertTo-Json -Depth 20
  $syntheticCandidateRoundTrip = $syntheticCandidateJson | ConvertFrom-Json
  Assert-CandidateContract -Document $syntheticCandidateRoundTrip

  $duplicateCandidate = $syntheticCandidateJson | ConvertFrom-Json
  $duplicateCandidate.covered_files = @(
    $duplicateCandidate.covered_files
    [PSCustomObject]@{
      repository_relative_path = 'core/telemetry.schema.json'
      sha256 = $hash64
      bytes = 1
      role = 'telemetry_schema'
      module_id = $null
    }
  )
  Assert-Throws -Name 'duplicate candidate covered paths' -Script {
    Assert-CandidateContract -Document $duplicateCandidate
  }

  $normalizedPathA = Normalize-RepoPath -Path './core\telemetry.schema.json'
  $normalizedPathB = Normalize-RepoPath -Path 'core/telemetry.schema.json'
  if ($normalizedPathA -ne $normalizedPathB -or $normalizedPathA -ne 'core/telemetry.schema.json') {
    throw 'Repository path normalization is not deterministic.'
  }

  $canonicalA = [PSCustomObject]@{
    z = 2
    a = [PSCustomObject]@{
      b = 1
      a = 0
    }
  }
  $canonicalB = [PSCustomObject]@{
    a = [PSCustomObject]@{
      a = 0
      b = 1
    }
    z = 2
  }
  $canonicalJsonA = ConvertTo-CanonicalJson -Value $canonicalA
  $canonicalJsonB = ConvertTo-CanonicalJson -Value $canonicalB
  if ($canonicalJsonA -ne $canonicalJsonB) {
    throw 'Canonical serialization is not deterministic.'
  }

  $mutatedCandidate = $syntheticCandidateJson | ConvertFrom-Json
  $syntheticFileHashA = Get-TextSha256 -Text 'A'
  $syntheticFileHashB = Get-TextSha256 -Text 'B'
  $mutatedCandidate.covered_files[0].sha256 = $syntheticFileHashA
  $originalManifestHash = Get-TextSha256 -Text (ConvertTo-CanonicalJson -Value $mutatedCandidate)
  $mutatedCandidate.covered_files[0].sha256 = $syntheticFileHashB
  $mutatedManifestHash = Get-TextSha256 -Text (ConvertTo-CanonicalJson -Value $mutatedCandidate)
  if ($originalManifestHash -eq $mutatedManifestHash) {
    throw 'One-byte synthetic candidate-file mutation did not change the manifest hash.'
  }

  $python = Get-PythonExecutable
  $tokenizerVersion = Get-TokenizerVersion -Python $python
  if ($tokenizerVersion -ne $script:TokenizerVersion) {
    throw ('Tokenizer version mismatch. Expected ' + $script:TokenizerVersion + ', got ' + $tokenizerVersion)
  }
  $tokenSample = Normalize-AuthoredText -Text ('alpha  ' + [string][char]10 + ' beta' + [string][char]13 + [string][char]10)
  $tokenEstimateA = Get-TokenizerEstimate -Text $tokenSample -Python $python
  $tokenEstimateB = Get-TokenizerEstimate -Text $tokenSample -Python $python
  if ($tokenEstimateA -ne $tokenEstimateB) {
    throw 'Tokenizer estimates are not deterministic across repeated runs.'
  }
  if ($script:TokenizerMeasurementKind -ne 'build_estimate') {
    throw 'Tokenizer measurement is not labeled as a build estimate.'
  }

  Write-Output 'Phase 0 v0.2 synthetic tests passed'
  Write-Output ('baseline_commit=' + $script:BaselineCommit)
  Write-Output ('frozen_design_sha256=' + $mirrorHash)
  Write-Output ('tokenizer=' + $script:TokenizerPackage + '/' + $tokenizerVersion + '/' + $script:TokenizerEncoding)
  Write-Output ('tokenizer_measurement=' + $script:TokenizerMeasurementKind)
  Write-Output ('guarded_v01_files=' + $script:FrozenV01Hashes.Count)
}
finally {
  Pop-Location
}
