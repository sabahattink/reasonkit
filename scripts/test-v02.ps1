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
$script:KernelSourcePath = 'core/tiny-kernel.md'
$script:KernelArtifactPath = 'dist/v0.2/reasonkit-kernel.md'
$script:KernelSourceBytesMax = 8000
$script:KernelTokensMax = 2000
$script:RegistryPath = 'core/module-registry.json'
$script:RegistrySourceBytesMax = 2000
$script:RegistryTokensMax = 500
$script:Phase1MutableV01Seams = @('scripts/build-dist.ps1', 'scripts/run-benchmark.ps1')

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

function Assert-LoaderTelemetrySchema {
  param(
    [Parameter(Mandatory = $true)]
    [object]$BaseDocument,
    [Parameter(Mandatory = $true)]
    [object]$Plan,
    [Parameter(Mandatory = $true)]
    [string]$SchemaPath,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $document = ($BaseDocument | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
  $document.context = $Plan.telemetry
  $document.provider_measurements = $Plan.provider_measurements
  $json = $document | ConvertTo-Json -Depth 80 -Compress
  try {
    $valid = Test-Json -Json $json -SchemaFile $SchemaPath -ErrorAction Stop
  }
  catch {
    throw ('Actual loader telemetry schema validation failed: ' + $Name + ': ' + $_.Exception.Message)
  }
  if ($valid -ne $true) {
    throw ('Actual loader telemetry schema validation returned false: ' + $Name)
  }

  $allowedModuleFields = @(
    'module_id', 'module_sha256', 'module_bytes', 'module_tokens',
    'load_reason', 'load_phase', 'module_reuse', 'load_action',
    'previous_sha256', 'reload_reason', 'context_injected'
  )
  $allowedReuseFields = @('reused', 'count', 'scope', 'reason')
  $allowedPhases = @('classification', 'evidence', 'specialist', 'verification', 'other')
  foreach ($record in @($Plan.telemetry.modules_loaded)) {
    $unexpected = @($record.PSObject.Properties.Name | Where-Object { $allowedModuleFields -notcontains $_ })
    if ($unexpected.Count -gt 0) {
      throw ('Schema-bound module telemetry leaked internal fields: ' + ($unexpected -join ', '))
    }
    foreach ($field in $allowedModuleFields) {
      if ($null -eq $record.PSObject.Properties[$field]) {
        throw ('Schema-bound module telemetry field is missing: ' + $Name + '/' + $field)
      }
    }
    if ($allowedPhases -notcontains $record.load_phase) {
      throw ('Schema-bound module telemetry emitted an invalid load_phase: ' + $record.load_phase)
    }
    $reuseUnexpected = @($record.module_reuse.PSObject.Properties.Name | Where-Object { $allowedReuseFields -notcontains $_ })
    if ($reuseUnexpected.Count -gt 0) {
      throw ('Schema-bound module_reuse leaked internal fields: ' + ($reuseUnexpected -join ', '))
    }
    foreach ($field in $allowedReuseFields) {
      if ($null -eq $record.module_reuse.PSObject.Properties[$field]) {
        throw ('Schema-bound module_reuse field is missing: ' + $Name + '/' + $field)
      }
    }
  }
  return $document
}

function New-Phase3Request {
  param(
    [string[]]$ConsiderationSignals = @(),
    [string[]]$Hypotheses = @(),
    [string]$EvidenceState = 'not_attempted',
    [bool]$EvidenceAttempted = $false,
    [bool]$EvidenceResolved = $false,
    [bool]$MaterialUncertainty = $false,
    [string]$Risk = 'low',
    [string]$VerificationState = 'deterministic',
    [string]$SelectedComplexity = 'L1',
    [string]$CallerRole = 'hub',
    [string]$RequestKind = 'delegate',
    [string]$RequestedRole = $null,
    [string]$ExpectedValue = $null,
    [bool]$AdversarialReview = $false
  )

  return [pscustomobject][ordered]@{
    consideration_signals = @($ConsiderationSignals)
    hypotheses = @($Hypotheses)
    evidence_state = $EvidenceState
    evidence_attempted = $EvidenceAttempted
    evidence_resolved = $EvidenceResolved
    material_uncertainty = $MaterialUncertainty
    risk = $Risk
    verification_state = $VerificationState
    selected_complexity = $SelectedComplexity
    caller_role = $CallerRole
    request_kind = $RequestKind
    requested_role = $RequestedRole
    expected_value = $ExpectedValue
    adversarial_review = $AdversarialReview
  }
}

function Assert-Phase3Decision {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Decision,
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedDecision,
    [Parameter(Mandatory = $true)]
    [bool]$ExpectedConsidered
  )

  if ($Decision.decision -ne $ExpectedDecision -or
      $Decision.considered -ne $ExpectedConsidered -or
      $Decision.started -ne $false) {
    throw ('Unexpected Phase 3 decision: ' + $Name)
  }
  if ($null -eq $Decision.telemetry -or $null -eq $Decision.telemetry.specialist_gate) {
    throw ('Phase 3 decision telemetry is missing: ' + $Name)
  }
}

function Assert-Phase3TelemetrySchema {
  param(
    [Parameter(Mandatory = $true)]
    [object]$BaseDocument,
    [Parameter(Mandatory = $true)]
    [object]$Decision,
    [Parameter(Mandatory = $true)]
    [string]$SchemaPath,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $document = ($BaseDocument | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
  $document.specialists = $Decision.telemetry
  $document.provider_measurements = $Decision.provider_measurements
  $json = $document | ConvertTo-Json -Depth 80 -Compress
  try {
    $valid = Test-Json -Json $json -SchemaFile $SchemaPath -ErrorAction Stop
  }
  catch {
    throw ('Phase 3 telemetry schema validation failed: ' + $Name + ': ' + $_.Exception.Message)
  }
  if ($valid -ne $true) {
    throw ('Phase 3 telemetry schema validation returned false: ' + $Name)
  }
  $allowedGateFields = @('considered', 'started', 'trigger', 'evidence_state', 'competing_hypotheses', 'rejection_reason', 'role')
  $extraGateFields = @($Decision.telemetry.specialist_gate.PSObject.Properties.Name | Where-Object { $allowedGateFields -notcontains $_ })
  if ($extraGateFields.Count -gt 0) {
    throw ('Phase 3 schema-bound gate telemetry leaked fields: ' + ($extraGateFields -join ', '))
  }
  return $document
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
    if ($script:Phase1MutableV01Seams -contains $entry.Key) {
      $null = Invoke-GitText -Arguments @('rev-parse', ($script:BaselineCommit + ':' + $entry.Key))
      continue
    }
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

  $telemetrySchemaPath = Join-Path $script:PhaseRoot 'core\telemetry.schema.json'
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

  $kernelSourceAbsolutePath = Join-Path $script:PhaseRoot ($script:KernelSourcePath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $kernelSourceAbsolutePath -PathType Leaf)) {
    throw ('Tiny Kernel source is missing: ' + $script:KernelSourcePath)
  }
  $kernelRawText = [IO.File]::ReadAllText($kernelSourceAbsolutePath)
  $kernelText = Normalize-AuthoredText -Text $kernelRawText
  $kernelTextAgain = Normalize-AuthoredText -Text $kernelText
  if ($kernelText -cne $kernelTextAgain) {
    throw 'Tiny Kernel normalization is not deterministic.'
  }
  $kernelUtf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
  $kernelBytes = $kernelUtf8.GetBytes($kernelText)
  $kernelBytesAgain = $kernelUtf8.GetBytes($kernelText)
  if ([Convert]::ToBase64String($kernelBytes) -cne [Convert]::ToBase64String($kernelBytesAgain)) {
    throw 'Tiny Kernel byte measurement is not deterministic.'
  }
  if ($kernelBytes.Length -gt $script:KernelSourceBytesMax) {
    throw ('Tiny Kernel exceeds the UTF-8 byte budget: ' + $kernelBytes.Length)
  }
  $kernelTokens = Get-TokenizerEstimate -Text $kernelText -Python $python
  $kernelTokensAgain = Get-TokenizerEstimate -Text $kernelText -Python $python
  if ($kernelTokens -ne $kernelTokensAgain) {
    throw 'Tiny Kernel tokenizer estimates are not deterministic.'
  }
  if ($kernelTokens -gt $script:KernelTokensMax) {
    throw ('Tiny Kernel exceeds the build-estimate token budget: ' + $kernelTokens)
  }

  $forbiddenKernelMarkers = @(
    '1.25',
    'TASK-001',
    'TASK-002',
    'TASK-003',
    'TASK-004',
    'arm A',
    'arm B',
    'arm C',
    'arm D'
  )
  foreach ($marker in $forbiddenKernelMarkers) {
    if ($kernelText.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw ('Forbidden benchmark marker in Tiny Kernel: ' + $marker)
    }
  }

  $kernelArtifactAbsolutePath = Join-Path $script:PhaseRoot ($script:KernelArtifactPath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $kernelArtifactAbsolutePath -PathType Leaf)) {
    throw ('Generated Tiny Kernel artifact is missing: ' + $script:KernelArtifactPath)
  }
  $kernelArtifactBytes = [IO.File]::ReadAllBytes($kernelArtifactAbsolutePath)
  $expectedKernelBytes = $kernelUtf8.GetBytes($kernelText)
  if ([Convert]::ToBase64String($kernelArtifactBytes) -cne [Convert]::ToBase64String($expectedKernelBytes)) {
    throw 'Generated Tiny Kernel is not byte-identical to the normalized source.'
  }
  $kernelSha256 = Get-TextSha256 -Text $kernelText
  $generatedKernelSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $kernelArtifactAbsolutePath).Hash.ToLowerInvariant()
  if ($kernelSha256 -ne $generatedKernelSha256) {
    throw 'Generated Tiny Kernel SHA-256 does not match the normalized source.'
  }
  if ($kernelSha256 -ne (Get-TextSha256 -Text $kernelText)) {
    throw 'Tiny Kernel SHA-256 is not deterministic.'
  }
  $unexpectedV02Artifacts = @(
    Get-ChildItem -LiteralPath (Join-Path $script:PhaseRoot 'dist/v0.2') -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -ne 'reasonkit-kernel.md' }
  )
  if ($unexpectedV02Artifacts.Count -gt 0) {
    throw 'Unexpected v0.2 bundle artifact exists.'
  }

  $registrySourceAbsolutePath = Join-Path $script:PhaseRoot ($script:RegistryPath -replace '/', '\')
  if (-not (Test-Path -LiteralPath $registrySourceAbsolutePath -PathType Leaf)) {
    throw ('Module registry source is missing: ' + $script:RegistryPath)
  }
  $registryRawText = [IO.File]::ReadAllText($registrySourceAbsolutePath)
  $registryText = Normalize-AuthoredText -Text $registryRawText
  $registryTextAgain = Normalize-AuthoredText -Text $registryText
  if ($registryText -cne $registryTextAgain) {
    throw 'Module registry normalization is not deterministic.'
  }
  $registryUtf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
  $registryBytes = $registryUtf8.GetBytes($registryText)
  $registryBytesAgain = $registryUtf8.GetBytes($registryText)
  if ([Convert]::ToBase64String($registryBytes) -cne [Convert]::ToBase64String($registryBytesAgain)) {
    throw 'Module registry byte measurement is not deterministic.'
  }
  if ($registryBytes.Length -gt $script:RegistrySourceBytesMax) {
    throw ('Module registry exceeds the UTF-8 byte budget: ' + $registryBytes.Length)
  }
  $registryTokens = Get-TokenizerEstimate -Text $registryText -Python $python
  $registryTokensAgain = Get-TokenizerEstimate -Text $registryText -Python $python
  if ($registryTokens -ne $registryTokensAgain) {
    throw 'Module registry tokenizer estimates are not deterministic.'
  }
  if ($registryTokens -gt $script:RegistryTokensMax) {
    throw ('Module registry exceeds the build-estimate token budget: ' + $registryTokens)
  }
  $registryDocument = $registryText | ConvertFrom-Json -Depth 30
  foreach ($field in @('schema_version', 'registry_id', 'modules', 'routes')) {
    if (-not (Test-HasProperty -Object $registryDocument -Name $field)) {
      throw ('Module registry field is missing: ' + $field)
    }
  }
  $registryModuleItems = @(Get-PropertyValue -Object $registryDocument -Name 'modules')
  if ($registryModuleItems.Count -eq 0) {
    throw 'Module registry must contain at least one module.'
  }
  $registryModuleIds = @($registryModuleItems | ForEach-Object { Get-PropertyValue -Object $_ -Name 'module_id' })
  if (@($registryModuleIds | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
    throw 'Module registry contains duplicate module IDs.'
  }
  $registryModuleById = @{}
  foreach ($module in $registryModuleItems) {
    $moduleId = Get-PropertyValue -Object $module -Name 'module_id'
    $sourcePath = Get-PropertyValue -Object $module -Name 'source_path'
    if ([string]::IsNullOrWhiteSpace($moduleId) -or [string]::IsNullOrWhiteSpace($sourcePath)) {
      throw 'Every registry module needs a module_id and source_path.'
    }
    if ((Normalize-RepoPath -Path $sourcePath) -ne $sourcePath) {
      throw ('Registry module source path is not canonical: ' + $sourcePath)
    }
    $registryModuleById[$moduleId] = $sourcePath
  }
  $registryRouteItems = @(Get-PropertyValue -Object $registryDocument -Name 'routes')
  if ($registryRouteItems.Count -eq 0) {
    throw 'Module registry must contain at least one route.'
  }
  $registryRouteIds = @($registryRouteItems | ForEach-Object { Get-PropertyValue -Object $_ -Name 'route_id' })
  if (@($registryRouteIds | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
    throw 'Module registry contains duplicate route IDs.'
  }
  foreach ($routeItem in $registryRouteItems) {
    $routeId = Get-PropertyValue -Object $routeItem -Name 'route_id'
    $routeModules = @(Get-PropertyValue -Object $routeItem -Name 'module_ids')
    $triggerSummary = Get-PropertyValue -Object $routeItem -Name 'trigger_summary'
    if ([string]::IsNullOrWhiteSpace($routeId) -or
        [string]::IsNullOrWhiteSpace($triggerSummary) -or
        $routeModules.Count -eq 0) {
      throw 'Every registry route needs a route_id, trigger_summary, and module_ids.'
    }
    foreach ($moduleId in $routeModules) {
      if (-not $registryModuleById.ContainsKey($moduleId)) {
        throw ('Registry route references an unresolved module: ' + $moduleId)
      }
    }
    foreach ($conditional in @(
      Get-PropertyValue -Object $routeItem -Name 'conditional_modules' |
        Where-Object { $null -ne $_ }
    )) {
      $conditionalId = Get-PropertyValue -Object $conditional -Name 'module_id'
      $capability = Get-PropertyValue -Object $conditional -Name 'capability'
      if (-not $registryModuleById.ContainsKey($conditionalId) -or [string]::IsNullOrWhiteSpace($capability)) {
        throw ('Registry conditional module is invalid on route: ' + $routeId)
      }
    }
  }
  foreach ($marker in @('TASK-001', 'TASK-002', 'TASK-003', 'TASK-004', 'Reliable Engineering', 'benchmark')) {
    if ($registryText.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw ('Forbidden benchmark marker in module registry: ' + $marker)
    }
  }
  $registrySha256 = Get-TextSha256 -Text $registryText
  if ($registrySha256 -ne (Get-TextSha256 -Text $registryText)) {
    throw 'Module registry SHA-256 is not deterministic.'
  }
  $registryBuildOutput = @(
    & .\scripts\build-dist.ps1 -V02Registry -Check 2>&1 |
      ForEach-Object { $_.ToString() }
  )
  if (-not $?) {
    throw 'Module registry build/check failed.'
  }
  foreach ($expectedRegistryOutput in @(
    'v0.2 module registry check passed',
    ('registry_sha256=' + $registrySha256),
    ('registry_utf8_bytes=' + $registryBytes.Length),
    ('registry_build_estimate_tokens=' + $registryTokens)
  )) {
    if ($registryBuildOutput -notcontains $expectedRegistryOutput) {
      throw ('Module registry build/check output is missing: ' + $expectedRegistryOutput)
    }
  }

  $loaderModulePath = Join-Path $script:PhaseRoot 'scripts/reasonkit-v02.psm1'
  if (-not (Test-Path -LiteralPath $loaderModulePath -PathType Leaf)) {
    throw 'RK2-02 loader module is missing.'
  }
  Import-Module -Name $loaderModulePath -Force
  $loaderRegistry = Read-ReasonKitModuleRegistry -Path $registrySourceAbsolutePath
  $loaderManifestModules = @(
    foreach ($module in @($loaderRegistry.modules)) {
      $moduleId = Get-PropertyValue -Object $module -Name 'module_id'
      $sourcePath = Get-PropertyValue -Object $module -Name 'source_path'
      [PSCustomObject]@{
        module_id = $moduleId
        source_path = $sourcePath
        sha256 = Get-FileSha256 -RelativePath $sourcePath
      }
    }
  )
  $loaderManifest = [PSCustomObject]@{
    manifest_id = 'synthetic-phase-2'
    modules = $loaderManifestModules
  }
  $loaderEvidence = [PSCustomObject]@{
    evidence_id = 'synthetic-local-evidence'
    load_reason = 'route selected from supplied evidence'
  }
  $requiredLoadRecordFields = @(
    'module_id', 'module_sha256', 'source_path', 'module_bytes',
    'module_tokens_build_estimate', 'load_reason', 'load_phase',
    'parent_route', 'load_action', 'previous_sha256', 'reload_reason',
    'context_injected', 'module_reuse', 'order'
  )
  $firstRunState = New-ReasonKitRunState
  $firstPlan = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $loaderEvidence `
    -Phase 'route' `
    -RequiredCapabilities @() `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RegistryPath $registrySourceAbsolutePath `
    -RunState $firstRunState
  $firstRecord = @($firstPlan.selected_modules)[0]
  if ($firstPlan.full_bundle_loaded -ne $false -or
      $firstPlan.kernel.loaded -ne $true -or
      $firstRecord.load_action -ne 'loaded' -or
      $firstRecord.context_injected -ne $true -or
      $firstRecord.module_reuse.reused -ne $false) {
    throw 'First module load did not produce the required loaded record.'
  }
  foreach ($field in $requiredLoadRecordFields) {
    if ($null -eq $firstRecord.PSObject.Properties[$field]) {
      throw ('Load record field is missing: ' + $field)
    }
  }
  if (@($firstRunState.injected_context).Count -ne 1) {
    throw 'First module load did not inject exactly once.'
  }
  $projectedRegistryTokens = Get-PropertyValue -Object $firstPlan.telemetry -Name 'loader_index_tokens'
  if ($firstPlan.telemetry.loader_index_bytes -ne $registryBytes.Length -or
      $projectedRegistryTokens -ne $registryTokens -or
      $firstPlan.telemetry.loader_request_count -ne 1) {
    throw 'Loader cost telemetry is incomplete or incorrect.'
  }
  foreach ($providerField in @('input_tokens', 'cached_input_tokens', 'output_tokens', 'reasoning_tokens', 'total_tokens')) {
    if ($null -ne $firstPlan.provider_measurements.$providerField) {
      throw ('Provider measurement must remain null: ' + $providerField)
    }
  }
  if ($null -eq $firstRecord.module_tokens_build_estimate -or
      $null -ne $firstRecord.PSObject.Properties['input_tokens']) {
    throw 'Build-estimate tokens were not kept separate from provider measurements.'
  }
  foreach ($omittedField in @('source_manifest_sha256', 'module_ids', 'bytes', 'tokens', 'derivation', 'status')) {
    if ($null -eq $firstPlan.telemetry.omitted_context.PSObject.Properties[$omittedField]) {
      throw ('Omitted-context field is missing: ' + $omittedField)
    }
  }
  if ($firstPlan.telemetry.omitted_context.status -ne 'unavailable' -or
      $null -ne $firstPlan.telemetry.omitted_context.bytes -or
      $null -ne $firstPlan.telemetry.omitted_context.tokens) {
    throw 'Omitted-context telemetry is not explicitly unavailable.'
  }

  $secondPlan = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $loaderEvidence `
    -Phase 'route' `
    -RequiredCapabilities @() `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RegistryPath $registrySourceAbsolutePath `
    -RunState $firstRunState
  $secondRecord = @($secondPlan.selected_modules)[0]
  if ($secondRecord.load_action -ne 'reused' -or
      $secondRecord.context_injected -ne $false -or
      $secondRecord.module_reuse.reused -ne $true -or
      $secondRecord.module_reuse.scope -ne 'same_run' -or
      @($firstRunState.injected_context).Count -ne 1 -or
      $secondPlan.telemetry.loader_request_count -ne 2) {
    throw 'Same module and hash did not deduplicate deterministically.'
  }

  if ($secondPlan.telemetry.modules_loaded[0].load_action -ne 'reused' -or
      $secondPlan.telemetry.modules_loaded[0].context_injected -ne $false -or
      $secondPlan.telemetry.modules_loaded[0].module_reuse.reused -ne $true) {
    throw 'Schema-bound reused telemetry did not preserve no-injection semantics.'
  }

  $cacheRunState = New-ReasonKitRunState
  $cacheEvidence = [PSCustomObject]@{
    evidence_id = 'synthetic-provider-cache-event'
    load_reason = 'provider cache event observed'
    provider_cache = 'hit'
  }
  $cachePlan = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $cacheEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RegistryPath $registrySourceAbsolutePath `
    -RunState $cacheRunState
  if ($cachePlan.selected_modules[0].module_reuse.reused -ne $false) {
    throw 'Provider cache was incorrectly reported as ReasonKit module reuse.'
  }

  $codingManifestEntry = @($loaderManifestModules | Where-Object { $_.module_id -eq 'protocol.coding' })[0]
  $debuggingManifestEntry = @($loaderManifestModules | Where-Object { $_.module_id -eq 'protocol.debugging' })[0]
  $revisionRegistry = [PSCustomObject]@{
    schema_version = '0.2'
    registry_id = 'synthetic-revision'
    modules = @([PSCustomObject]@{
      module_id = 'protocol.coding'
      source_path = $debuggingManifestEntry.source_path
    })
    routes = @([PSCustomObject]@{
      route_id = 'coding'
      module_ids = @('protocol.coding')
      trigger_summary = 'synthetic revision'
    })
  }
  $revisionManifest = [PSCustomObject]@{
    manifest_id = 'synthetic-revision-manifest'
    modules = @([PSCustomObject]@{
      module_id = 'protocol.coding'
      source_path = $debuggingManifestEntry.source_path
      sha256 = $debuggingManifestEntry.sha256
    })
  }
  $reloadRunState = New-ReasonKitRunState
  $null = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RegistryPath $registrySourceAbsolutePath `
    -RunState $reloadRunState
  $reloadEvidence = [PSCustomObject]@{
    evidence_id = 'synthetic-explicit-revision'
    load_reason = 'explicit source revision evidence'
    reload_reason = 'explicit revision context'
  }
  $reloadPlan = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $reloadEvidence `
    -Phase 'route' `
    -Registry $revisionRegistry `
    -Manifest $revisionManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState $reloadRunState
  $reloadRecord = @($reloadPlan.selected_modules)[0]
  if ($reloadRecord.load_action -ne 'reloaded' -or
      $reloadRecord.context_injected -ne $true -or
      $reloadRecord.previous_sha256 -ne $codingManifestEntry.sha256 -or
      $reloadRecord.module_sha256 -ne $debuggingManifestEntry.sha256 -or
      $reloadRecord.reload_reason -ne 'explicit revision context') {
    throw 'Explicit different-hash revision did not produce a reloaded record.'
  }

  $null = Assert-LoaderTelemetrySchema -BaseDocument $minimalTelemetryRoundTrip -Plan $firstPlan -SchemaPath $telemetrySchemaPath -Name 'loaded'
  $null = Assert-LoaderTelemetrySchema -BaseDocument $minimalTelemetryRoundTrip -Plan $secondPlan -SchemaPath $telemetrySchemaPath -Name 'reused'
  $null = Assert-LoaderTelemetrySchema -BaseDocument $minimalTelemetryRoundTrip -Plan $reloadPlan -SchemaPath $telemetrySchemaPath -Name 'reloaded'

  $invalidPhasePlan = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $loaderEvidence `
    -Phase 'not-a-schema-phase' `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState (New-ReasonKitRunState)
  if (@($invalidPhasePlan.telemetry.modules_loaded)[0].load_phase -ne 'other') {
    throw 'Invalid internal phase was emitted outside the frozen schema enum.'
  }
  $null = Assert-LoaderTelemetrySchema -BaseDocument $minimalTelemetryRoundTrip -Plan $invalidPhasePlan -SchemaPath $telemetrySchemaPath -Name 'invalid-phase-projection'
  $unexplainedRunState = New-ReasonKitRunState
  $null = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState $unexplainedRunState
  Assert-Throws -Name 'unexplained different-hash duplicate' -Script {
    Resolve-ReasonKitContext `
      -Route 'coding' `
      -Evidence $loaderEvidence `
      -Registry $revisionRegistry `
      -Manifest $revisionManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState $unexplainedRunState
  }
  if (@($unexplainedRunState.injected_context).Count -ne 1) {
    throw 'Unexplained duplicate changed injected context.'
  }

  $boundaryRunState = New-ReasonKitRunState
  $null = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState $boundaryRunState
  Assert-Throws -Name 'phase-boundary reload without reason' -Script {
    Resolve-ReasonKitContext `
      -Route 'coding' `
      -Evidence ([PSCustomObject]@{ load_reason = 'boundary'; phase_boundary_reload = $true }) `
      -Phase 'verification' `
      -Registry $loaderRegistry `
      -Manifest $loaderManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState $boundaryRunState
  }
  $boundaryPlan = Resolve-ReasonKitContext `
    -Route 'coding' `
    -Evidence ([PSCustomObject]@{ load_reason = 'boundary'; phase_boundary_reload = $true; reload_reason = 'explicit phase boundary' }) `
    -Phase 'verification' `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState $boundaryRunState
  if ($boundaryPlan.selected_modules[0].load_action -ne 'reloaded' -or
      $boundaryPlan.selected_modules[0].context_injected -ne $true -or
      $boundaryPlan.selected_modules[0].reload_reason -ne 'explicit phase boundary') {
    throw 'Explicit same-hash phase-boundary reload was not recorded.'
  }

  $duplicateRegistry = [PSCustomObject]@{
    schema_version = '0.2'
    registry_id = 'synthetic-duplicate'
    modules = @(
      [PSCustomObject]@{ module_id = 'protocol.coding'; source_path = 'protocols/coding.md' },
      [PSCustomObject]@{ module_id = 'protocol.coding'; source_path = 'protocols/debugging.md' }
    )
    routes = @([PSCustomObject]@{ route_id = 'coding'; module_ids = @('protocol.coding'); trigger_summary = 'duplicate' })
  }
  Assert-Throws -Name 'duplicate registry module IDs' -Script {
    Resolve-ReasonKitContext `
      -Route 'coding' `
      -Evidence $loaderEvidence `
      -Registry $duplicateRegistry `
      -Manifest $loaderManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState (New-ReasonKitRunState)
  }
  $duplicateConditionalRegistry = [PSCustomObject]@{
    schema_version = '0.2'
    registry_id = 'synthetic-duplicate-conditional'
    modules = @(
      [PSCustomObject]@{ module_id = 'protocol.design'; source_path = 'protocols/design.md' },
      [PSCustomObject]@{ module_id = 'taste.anti-generic'; source_path = 'taste/anti-generic.md' }
    )
    routes = @([PSCustomObject]@{
      route_id = 'design'
      module_ids = @('protocol.design')
      conditional_modules = @(
        [PSCustomObject]@{ module_id = 'taste.anti-generic'; capability = 'taste' },
        [PSCustomObject]@{ module_id = 'taste.anti-generic'; capability = 'taste' }
      )
      trigger_summary = 'duplicate conditional'
    })
  }
  Assert-Throws -Name 'duplicate conditional registry modules' -Script {
    Resolve-ReasonKitContext `
      -Route 'design' `
      -Evidence $loaderEvidence `
      -Registry $duplicateConditionalRegistry `
      -Manifest $loaderManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState (New-ReasonKitRunState)
  }
  $unresolvedRegistry = [PSCustomObject]@{
    schema_version = '0.2'
    registry_id = 'synthetic-unresolved'
    modules = @([PSCustomObject]@{ module_id = 'protocol.coding'; source_path = 'protocols/coding.md' })
    routes = @([PSCustomObject]@{ route_id = 'coding'; module_ids = @('protocol.missing'); trigger_summary = 'unresolved' })
  }
  Assert-Throws -Name 'unresolved registry reference' -Script {
    Resolve-ReasonKitContext `
      -Route 'coding' `
      -Evidence $loaderEvidence `
      -Registry $unresolvedRegistry `
      -Manifest $loaderManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState (New-ReasonKitRunState)
  }
  $missingSourceRegistry = [PSCustomObject]@{
    schema_version = '0.2'
    registry_id = 'synthetic-missing-source'
    modules = @([PSCustomObject]@{ module_id = 'protocol.missing'; source_path = 'core/does-not-exist.md' })
    routes = @([PSCustomObject]@{ route_id = 'missing'; module_ids = @('protocol.missing'); trigger_summary = 'missing source' })
  }
  $missingSourceManifest = [PSCustomObject]@{
    manifest_id = 'synthetic-missing-source-manifest'
    modules = @([PSCustomObject]@{ module_id = 'protocol.missing'; source_path = 'core/does-not-exist.md'; sha256 = ('0' * 64) })
  }
  Assert-Throws -Name 'missing source file' -Script {
    Resolve-ReasonKitContext `
      -Route 'missing' `
      -Evidence $loaderEvidence `
      -Registry $missingSourceRegistry `
      -Manifest $missingSourceManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState (New-ReasonKitRunState)
  }
  $badHashManifest = [PSCustomObject]@{
    manifest_id = 'synthetic-bad-hash'
    modules = @(
      foreach ($entry in $loaderManifestModules) {
        [PSCustomObject]@{
          module_id = $entry.module_id
          source_path = $entry.source_path
          sha256 = if ($entry.module_id -eq 'protocol.coding') { ('0' * 64) } else { $entry.sha256 }
        }
      }
    )
  }
  Assert-Throws -Name 'source hash mismatch' -Script {
    Resolve-ReasonKitContext `
      -Route 'coding' `
      -Evidence $loaderEvidence `
      -Registry $loaderRegistry `
      -Manifest $badHashManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState (New-ReasonKitRunState)
  }

  $missingKernelRoot = Join-Path ([IO.Path]::GetTempPath()) ('reasonkit-v02-missing-kernel-' + [Guid]::NewGuid().ToString('N'))
  $missingKernelState = New-ReasonKitRunState
  $missingKernelError = $null
  $missingKernelPlan = $null
  New-Item -ItemType Directory -Path $missingKernelRoot -Force | Out-Null
  try {
    try {
      $missingKernelPlan = Resolve-ReasonKitContext `
        -Route 'coding' `
        -Evidence $loaderEvidence `
        -Registry $loaderRegistry `
        -Manifest $loaderManifest `
        -RepositoryRoot $missingKernelRoot `
        -RunState $missingKernelState
    }
    catch {
      $missingKernelError = $_.Exception.Message
    }
  }
  finally {
    Remove-Item -LiteralPath $missingKernelRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  if ($null -ne $missingKernelPlan -or
      [string]::IsNullOrWhiteSpace($missingKernelError) -or
      $missingKernelError -notmatch '(?i)kernel' -or
      @($missingKernelState.injected_context).Count -ne 0 -or
      @($missingKernelState.load_records).Count -ne 0) {
    throw 'Missing kernel did not fail closed before module injection.'
  }
  $failedState = New-ReasonKitRunState
  Assert-Throws -Name 'unknown route fail closed' -Script {
    Resolve-ReasonKitContext `
      -Route 'not-registered' `
      -Evidence $loaderEvidence `
      -Registry $loaderRegistry `
      -Manifest $loaderManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState $failedState
  }
  if (@($failedState.injected_context).Count -ne 0) {
    throw 'Normal loader error injected a fallback context.'
  }

  foreach ($routeId in @('coding', 'debugging', 'architecture', 'research')) {
    $localityPlan = Resolve-ReasonKitContext `
      -Route $routeId `
      -Evidence $loaderEvidence `
      -Registry $loaderRegistry `
      -Manifest $loaderManifest `
      -RepositoryRoot $script:PhaseRoot `
      -RunState (New-ReasonKitRunState)
    foreach ($record in @($localityPlan.selected_modules)) {
      if ($record.module_id -like 'taste.*' -or $record.module_id -eq 'protocol.design') {
        throw ('Engineering route loaded design/taste content: ' + $routeId)
      }
    }
  }
  $designPlan = Resolve-ReasonKitContext `
    -Route 'design' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RequiredCapabilities @() `
    -RepositoryRoot $script:PhaseRoot `
    -RunState (New-ReasonKitRunState)
  if (@($designPlan.selected_modules).Count -ne 1) {
    throw 'Design route loaded conditional taste content without an explicit capability.'
  }
  $designTastePlan = Resolve-ReasonKitContext `
    -Route 'design' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RequiredCapabilities @('taste') `
    -RepositoryRoot $script:PhaseRoot `
    -RunState (New-ReasonKitRunState)
  if (@($designTastePlan.selected_modules | Where-Object { $_.module_id -eq 'taste.anti-generic' }).Count -ne 1) {
    throw 'Explicit design taste capability did not load the conditional module.'
  }
  $computerPlan = Resolve-ReasonKitContext `
    -Route 'computer-use' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RequiredCapabilities @() `
    -RepositoryRoot $script:PhaseRoot `
    -RunState (New-ReasonKitRunState)
  if (@($computerPlan.selected_modules | Where-Object { $_.module_id -eq 'core.computer-use-policy' }).Count -ne 0) {
    throw 'Computer-use policy loaded without an explicit capability.'
  }
  $computerPolicyPlan = Resolve-ReasonKitContext `
    -Route 'computer-use' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RequiredCapabilities @('computer-use-policy') `
    -RepositoryRoot $script:PhaseRoot `
    -RunState (New-ReasonKitRunState)
  if (@($computerPolicyPlan.selected_modules | Where-Object { $_.module_id -eq 'core.computer-use-policy' }).Count -ne 1) {
    throw 'Explicit computer-use policy capability did not load the conditional module.'
  }

  $planStateA = New-ReasonKitRunState
  $planStateB = New-ReasonKitRunState
  $planA = Resolve-ReasonKitContext `
    -Route 'architecture' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState $planStateA
  $planB = Resolve-ReasonKitContext `
    -Route 'architecture' `
    -Evidence $loaderEvidence `
    -Registry $loaderRegistry `
    -Manifest $loaderManifest `
    -RepositoryRoot $script:PhaseRoot `
    -RunState $planStateB
  $signatureA = @($planA.selected_modules | ForEach-Object { $_.module_id + '|' + $_.module_sha256 + '|' + $_.load_action + '|' + $_.context_injected }) -join ';'
  $signatureB = @($planB.selected_modules | ForEach-Object { $_.module_id + '|' + $_.module_sha256 + '|' + $_.load_action + '|' + $_.context_injected }) -join ';'
  if ($signatureA -cne $signatureB -or $planA.full_bundle_loaded -ne $planB.full_bundle_loaded) {
    throw 'Identical loader input did not produce an identical context plan.'
  }

  # Phase 3 — RK2-03 Specialist Gate synthetic seam tests.
  $phase3State = New-ReasonKitRunState
  $phase3NoTrigger = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request) `
    -RunState $phase3State
  Assert-Phase3Decision -Decision $phase3NoTrigger -Name 'no trigger' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $false
  $phase3RecordA = $phase3NoTrigger

  $phase3SingleCause = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -EvidenceState 'resolved_by_local_verification' -EvidenceAttempted $true -EvidenceResolved $true) `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $phase3SingleCause -Name 'single supported cause' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $false

  $phase3Collapsed = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('competing_hypotheses') -Hypotheses @('cause-a', 'cause-b') -EvidenceState 'resolved_by_test' -EvidenceAttempted $true -EvidenceResolved $true) `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $phase3Collapsed -Name 'hypotheses collapsed' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $true
  $phase3RecordB = $phase3Collapsed

  $phase3ConflictState = New-ReasonKitRunState
  $phase3ConflictRequest = New-Phase3Request `
    -ConsiderationSignals @('conflicting_evidence') `
    -Hypotheses @('cause-a', 'cause-b') `
    -EvidenceState 'conflicting_unresolved' `
    -EvidenceAttempted $true `
    -MaterialUncertainty $true `
    -Risk 'material' `
    -RequestedRole 'investigator' `
    -ExpectedValue 'independent causal comparison'
  $phase3Conflict = Decide-ReasonKitSpecialist -Request $phase3ConflictRequest -RunState $phase3ConflictState
  Assert-Phase3Decision -Decision $phase3Conflict -Name 'unresolved conflict' -ExpectedDecision 'AUTHORIZED' -ExpectedConsidered $true
  if ($phase3Conflict.role -ne 'investigator' -or
      $phase3Conflict.telemetry.specialist_count -ne 0 -or
      @($phase3Conflict.telemetry.specialist_roles).Count -ne 0 -or
      $phase3Conflict.provider_measurements.agent_count -ne $null) {
    throw 'First specialist authorization did not remain distinct from actual specialist start.'
  }
  $phase3RecordC = $phase3Conflict

  $lifecycleState = New-ReasonKitRunState
  $lifecycleAuthorization = Decide-ReasonKitSpecialist -Request $phase3ConflictRequest -RunState $lifecycleState
  if ($lifecycleAuthorization.decision -ne 'AUTHORIZED' -or
      $lifecycleAuthorization.started -ne $false -or
      $lifecycleAuthorization.telemetry.specialist_count -ne 0 -or
      @($lifecycleAuthorization.telemetry.specialist_roles).Count -ne 0 -or
      $lifecycleAuthorization.provider_measurements.agent_count -ne $null) {
    throw 'Fresh authorization was incorrectly reported as an actual specialist start.'
  }
  $phase3RecordAuthorizationOnly = $lifecycleAuthorization

  $startedLifecycle = Record-ReasonKitSpecialistStart `
    -Authorization $lifecycleAuthorization `
    -RunState $lifecycleState
  if ($startedLifecycle.decision -ne 'STARTED' -or
      $startedLifecycle.started -ne $true -or
      $startedLifecycle.telemetry.specialist_gate.started -ne $true -or
      $startedLifecycle.telemetry.specialist_count -ne 1 -or
      @($startedLifecycle.telemetry.specialist_roles | Where-Object { $_ -eq 'investigator' }).Count -ne 1 -or
      $startedLifecycle.provider_measurements.agent_count -ne $null) {
    throw 'External specialist start was not recorded with actual started semantics.'
  }
  $null = Assert-Phase3TelemetrySchema `
    -BaseDocument $minimalTelemetryRoundTrip `
    -Decision $startedLifecycle `
    -SchemaPath $telemetrySchemaPath `
    -Name 'started-agent'
  $phase3RecordStarted = $startedLifecycle

  $duplicateStart = Record-ReasonKitSpecialistStart `
    -Authorization $lifecycleAuthorization `
    -RunState $lifecycleState
  if ($duplicateStart.decision -ne 'REJECTED' -or
      $duplicateStart.validity_event.type -ne 'duplicate_specialist_start' -or
      $duplicateStart.telemetry.specialist_count -ne 1) {
    throw 'Duplicate specialist start was not rejected without incrementing the started count.'
  }
  $phase3RecordDuplicateStart = $duplicateStart

  $recursiveStart = Record-ReasonKitSpecialistStart `
    -Authorization $lifecycleAuthorization `
    -RunState $lifecycleState `
    -CallerRole 'specialist'
  if ($recursiveStart.decision -ne 'REJECTED' -or
      $recursiveStart.validity_event.type -ne 'recursive_specialist_start' -or
      $recursiveStart.telemetry.specialist_count -ne 1) {
    throw 'Recursive specialist-originated start was not rejected.'
  }
  $phase3RecordRecursiveStart = $recursiveStart

  $startWithoutAuthorization = Record-ReasonKitSpecialistStart `
    -Authorization ([pscustomobject][ordered]@{ authorization_id = 'missing-authorization'; role = 'investigator' }) `
    -RunState (New-ReasonKitRunState)
  if ($startWithoutAuthorization.decision -ne 'REJECTED' -or
      $startWithoutAuthorization.validity_event.type -ne 'start_without_authorization' -or
      $startWithoutAuthorization.telemetry.specialist_count -ne 0) {
    throw 'Start without a valid authorization was not rejected.'
  }
  $phase3RecordStartWithoutAuthorization = $startWithoutAuthorization

  $roleMismatchState = New-ReasonKitRunState
  $roleMismatchAuthorization = Decide-ReasonKitSpecialist -Request $phase3ConflictRequest -RunState $roleMismatchState
  $roleMismatch = Record-ReasonKitSpecialistStart `
    -Authorization $roleMismatchAuthorization `
    -RunState $roleMismatchState `
    -Role 'verifier'
  if ($roleMismatch.decision -ne 'REJECTED' -or
      $roleMismatch.validity_event.type -ne 'specialist_role_mismatch' -or
      $roleMismatch.telemetry.specialist_count -ne 0) {
    throw 'Role-mismatched specialist start was not rejected.'
  }

  $multiStartState = New-ReasonKitRunState
  $multiStartRequests = @(
    New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'investigator' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -ExpectedValue 'bounded investigator value'
    New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'verifier' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -ExpectedValue 'bounded verifier value'
    New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'implementer' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -ExpectedValue 'bounded implementer value'
  )
  $multiStartResults = [System.Collections.Generic.List[object]]::new()
  foreach ($multiStartRequest in $multiStartRequests) {
    $multiAuthorization = Decide-ReasonKitSpecialist -Request $multiStartRequest -RunState $multiStartState
    if ($multiAuthorization.decision -ne 'AUTHORIZED') {
      throw 'A valid second or third specialist authorization was unexpectedly rejected.'
    }
    $multiStarted = Record-ReasonKitSpecialistStart -Authorization $multiAuthorization -RunState $multiStartState
    if ($multiStarted.decision -ne 'STARTED') {
      throw 'A valid second or third specialist start was unexpectedly rejected.'
    }
    $null = $multiStartResults.Add($multiStarted)
  }
  $thirdStart = $multiStartResults[2]
  if ($thirdStart.telemetry.specialist_count -ne 3 -or
      @($thirdStart.telemetry.specialist_roles).Count -ne 3) {
    throw 'Third specialist start did not produce the bounded count and role ledger.'
  }
  $pendingAuthorization = [pscustomobject][ordered]@{
    authorization_id = 'specialist-pending'
    role = 'reference-researcher'
    trigger = @('conflicting_evidence')
    expected_value = 'bounded pending authorization'
    evidence_state = 'conflicting_unresolved'
    considered = $true
    competing_hypotheses = 0
    adversarial = $false
    started = $false
  }
  $null = $multiStartState.specialists_authorized.Add($pendingAuthorization)
  $capStartAuthorization = [pscustomobject][ordered]@{
    decision = 'AUTHORIZED'
    authorization_id = 'specialist-pending'
    role = 'reference-researcher'
  }
  $capStart = Record-ReasonKitSpecialistStart -Authorization $capStartAuthorization -RunState $multiStartState
  if ($capStart.decision -ne 'REJECTED' -or
      $capStart.validity_event.type -ne 'specialist_cap_exceeded' -or
      $capStart.telemetry.specialist_count -ne 3) {
    throw 'Specialist start after the execution cap was not rejected.'
  }
  $phase3RecordCapStart = $capStart

  foreach ($complexity in @('L3', 'L4')) {
    $complexityDecision = Decide-ReasonKitSpecialist `
      -Request (New-Phase3Request -SelectedComplexity $complexity) `
      -RunState (New-ReasonKitRunState)
    Assert-Phase3Decision -Decision $complexityDecision -Name ($complexity + ' alone') -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $false
  }
  $unsureDecision = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('uncertainty')) `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $unsureDecision -Name 'uncertainty alone' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $false

  $unfamiliarResolved = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('unfamiliar_external_domain') -EvidenceState 'resolved_by_authoritative_query' -EvidenceAttempted $true -EvidenceResolved $true) `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $unfamiliarResolved -Name 'unfamiliar domain resolved' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $true

  $highImpact = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('high_impact_irreversible') -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -Risk 'material') `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $highImpact -Name 'high impact consideration' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $true

  $nondeterministic = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('nondeterministic_verification') -EvidenceState 'nondeterministic') `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $nondeterministic -Name 'nondeterministic verification' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $true

  $creative = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('unresolved_creative_direction') -EvidenceState 'unresolved') `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $creative -Name 'unresolved creative direction' -ExpectedDecision 'NO_SPAWN' -ExpectedConsidered $true

  $requestWithoutSignal = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -RequestedRole 'investigator') `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $requestWithoutSignal -Name 'request without signal' -ExpectedDecision 'REJECTED' -ExpectedConsidered $false

  $recursive = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -CallerRole 'specialist' -RequestKind 'delegate' -RequestedRole 'verifier' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true) `
    -RunState (New-ReasonKitRunState)
  Assert-Phase3Decision -Decision $recursive -Name 'recursive specialist request' -ExpectedDecision 'REJECTED' -ExpectedConsidered $true
  $phase3RecordD = $recursive

  Assert-Throws -Name 'malformed gate request' -Script {
    Decide-ReasonKitSpecialist -Request ([pscustomobject]@{}) -RunState (New-ReasonKitRunState)
  }

  foreach ($forbiddenRequest in @('specialist_to_specialist', 'peer_conversation', 'vote', 'consensus')) {
    $forbiddenDecision = Decide-ReasonKitSpecialist `
      -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestKind $forbiddenRequest -RequestedRole 'investigator' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true) `
      -RunState (New-ReasonKitRunState)
    Assert-Phase3Decision -Decision $forbiddenDecision -Name $forbiddenRequest -ExpectedDecision 'REJECTED' -ExpectedConsidered $true
  }

  $capState = New-ReasonKitRunState
  foreach ($role in @('investigator', 'verifier', 'implementer')) {
    $capDecision = Decide-ReasonKitSpecialist `
      -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole $role -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -ExpectedValue ('bounded ' + $role)) `
      -RunState $capState
    Assert-Phase3Decision -Decision $capDecision -Name ('specialist authorization ' + $role) -ExpectedDecision 'AUTHORIZED' -ExpectedConsidered $true
  }
  $fourth = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'reference-researcher' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true) `
    -RunState $capState
  Assert-Phase3Decision -Decision $fourth -Name 'fourth specialist' -ExpectedDecision 'REJECTED' -ExpectedConsidered $true
  if ($fourth.validity_event.type -ne 'specialist_cap_exceeded') {
    throw 'Fourth specialist rejection was not recorded as a validity event.'
  }
  $phase3RecordE = $fourth

  $adversarialState = New-ReasonKitRunState
  $firstAdversarial = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'adversarial-reviewer' -ExpectedValue 'bounded adversarial review' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -AdversarialReview $true) `
    -RunState $adversarialState
  Assert-Phase3Decision -Decision $firstAdversarial -Name 'first adversarial pass' -ExpectedDecision 'AUTHORIZED' -ExpectedConsidered $true
  $secondAdversarial = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'adversarial-reviewer' -ExpectedValue 'bounded adversarial review' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -AdversarialReview $true) `
    -RunState $adversarialState
  Assert-Phase3Decision -Decision $secondAdversarial -Name 'second adversarial pass' -ExpectedDecision 'REJECTED' -ExpectedConsidered $true
  if ($secondAdversarial.validity_event.type -ne 'adversarial_cap_exceeded') {
    throw 'Second adversarial rejection was not recorded as a validity event.'
  }
  $phase3RecordF = $secondAdversarial

  $adversarialLifecycleState = New-ReasonKitRunState
  $adversarialLifecycleAuthorization = Decide-ReasonKitSpecialist `
    -Request (New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -RequestedRole 'adversarial-reviewer' -ExpectedValue 'bounded adversarial review' -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -AdversarialReview $true) `
    -RunState $adversarialLifecycleState
  $adversarialLifecycleStart = Record-ReasonKitSpecialistStart `
    -Authorization $adversarialLifecycleAuthorization `
    -RunState $adversarialLifecycleState
  if ($adversarialLifecycleStart.decision -ne 'STARTED' -or
      $adversarialLifecycleStart.telemetry.specialist_gate.started -ne $true -or
      $adversarialLifecycleStart.telemetry.specialist_count -ne 1) {
    throw 'First adversarial start did not produce actual-start telemetry.'
  }
  $secondAdversarialStart = Record-ReasonKitSpecialistStart `
    -Authorization $adversarialLifecycleAuthorization `
    -RunState $adversarialLifecycleState
  if ($secondAdversarialStart.decision -ne 'REJECTED' -or
      $secondAdversarialStart.validity_event.type -ne 'duplicate_specialist_start') {
    throw 'Second adversarial start was not rejected and recorded.'
  }

  $validReport = [pscustomobject][ordered]@{
    role = 'investigator'
    evidence_refs = @('test:conflicting-evidence', 'test:reproduction')
    conclusion = 'The remaining cause is bounded to the observed seam.'
    residual_risk = 'One external integration remains unverified.'
    recommended_next_action = 'Run the named verification check.'
  }
  $validReportResult = Test-ReasonKitSpecialistReport -Report $validReport -Python $python
  if ($validReportResult.accepted -ne $true -or $validReportResult.report_tokens -le 0) {
    throw 'Valid bounded specialist report was not accepted.'
  }
  $phase3RecordG = $validReportResult

  $missingReportField = [pscustomobject][ordered]@{
    role = 'investigator'
    evidence_refs = @('test:missing-field')
    conclusion = 'Incomplete report.'
    residual_risk = 'Unknown.'
  }
  $missingReportResult = Test-ReasonKitSpecialistReport -Report $missingReportField -Python $python
  if ($missingReportResult.accepted -ne $false) {
    throw 'Specialist report missing a required field was accepted.'
  }
  $rawTranscriptReport = [pscustomobject][ordered]@{
    role = 'investigator'
    evidence_refs = @('test:raw-transcript')
    conclusion = 'Structured conclusion.'
    residual_risk = 'Low.'
    recommended_next_action = 'Verify.'
    raw_transcript = 'This field is forbidden.'
  }
  $rawTranscriptResult = Test-ReasonKitSpecialistReport -Report $rawTranscriptReport -Python $python
  if ($rawTranscriptResult.accepted -ne $false) {
    throw 'Specialist report containing a raw transcript was accepted.'
  }
  $oversizedReport = [pscustomobject][ordered]@{
    role = 'investigator'
    evidence_refs = @('test:oversized')
    conclusion = ('x' * 5000)
    residual_risk = 'High.'
    recommended_next_action = 'Reduce the report.'
  }
  $oversizedResult = Test-ReasonKitSpecialistReport -Report $oversizedReport -Python $python
  if ($oversizedResult.accepted -ne $false -or
      $oversizedResult.over_budget -ne $true -or
      $oversizedResult.report_tokens -le 512) {
    throw 'Oversized bounded specialist report was not surfaced correctly.'
  }
  $phase3RecordH = $oversizedResult

  $null = Assert-Phase3TelemetrySchema -BaseDocument $minimalTelemetryRoundTrip -Decision $phase3NoTrigger -SchemaPath $telemetrySchemaPath -Name 'no-agent'
  $null = Assert-Phase3TelemetrySchema -BaseDocument $minimalTelemetryRoundTrip -Decision $phase3Conflict -SchemaPath $telemetrySchemaPath -Name 'authorized-specialist'
  if ($phase3Conflict.telemetry.specialist_count -ne 0 -or
      @($phase3Conflict.telemetry.specialist_roles).Count -ne 0 -or
      $phase3Conflict.provider_measurements.agent_count -ne $null) {
    throw 'ReasonKit specialist_count was not kept distinct from provider agent_count.'
  }

  $deterministicRequest = New-Phase3Request -ConsiderationSignals @('conflicting_evidence') -Hypotheses @('cause-a', 'cause-b') -EvidenceState 'conflicting_unresolved' -EvidenceAttempted $true -MaterialUncertainty $true -RequestedRole 'investigator' -ExpectedValue 'bounded evidence value'
  $deterministicA = Decide-ReasonKitSpecialist -Request $deterministicRequest -RunState (New-ReasonKitRunState)
  $deterministicB = Decide-ReasonKitSpecialist -Request $deterministicRequest -RunState (New-ReasonKitRunState)
  $deterministicJsonA = $deterministicA | ConvertTo-Json -Compress -Depth 50
  $deterministicJsonB = $deterministicB | ConvertTo-Json -Compress -Depth 50
  if ($deterministicJsonA -cne $deterministicJsonB) {
    throw 'Identical Specialist Gate inputs did not produce identical decisions.'
  }
  $deterministicLifecycleStateA = New-ReasonKitRunState
  $deterministicLifecycleAuthA = Decide-ReasonKitSpecialist -Request $deterministicRequest -RunState $deterministicLifecycleStateA
  $deterministicLifecycleStartA = Record-ReasonKitSpecialistStart -Authorization $deterministicLifecycleAuthA -RunState $deterministicLifecycleStateA
  $deterministicLifecycleStateB = New-ReasonKitRunState
  $deterministicLifecycleAuthB = Decide-ReasonKitSpecialist -Request $deterministicRequest -RunState $deterministicLifecycleStateB
  $deterministicLifecycleStartB = Record-ReasonKitSpecialistStart -Authorization $deterministicLifecycleAuthB -RunState $deterministicLifecycleStateB
  $deterministicStartJsonA = $deterministicLifecycleStartA | ConvertTo-Json -Compress -Depth 50
  $deterministicStartJsonB = $deterministicLifecycleStartB | ConvertTo-Json -Compress -Depth 50
  if ($deterministicStartJsonA -cne $deterministicStartJsonB) {
    throw 'Identical specialist start inputs did not produce identical lifecycle decisions.'
  }
  if ($phase3Conflict.started -ne $false -or
      $phase3Conflict.provider_measurements.input_tokens -ne $null -or
      $phase3Conflict.provider_measurements.output_tokens -ne $null) {
    throw 'Specialist Gate appears to have started a provider or fabricated provider measurements.'
  }
  if ($startedLifecycle.provider_measurements.input_tokens -ne $null -or
      $startedLifecycle.provider_measurements.output_tokens -ne $null -or
      $startedLifecycle.started -ne $true) {
    throw 'Specialist start seam fabricated provider usage or failed to record the external start.'
  }

  $phase4TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('reasonkit-v02-phase4-' + [Guid]::NewGuid().ToString('N'))
  $phase4CandidatePath = Join-Path $phase4TempRoot 'candidate-manifest.json'
  $phase4OutputRelative = 'phase4-test-runs-' + [Guid]::NewGuid().ToString('N')
  $phase4OutputAbsolute = Join-Path $script:PhaseRoot $phase4OutputRelative
  $phase4RepeatOutputRelative = 'phase4-repeat-runs-' + [Guid]::NewGuid().ToString('N')
  $phase4RepeatOutputAbsolute = Join-Path $script:PhaseRoot $phase4RepeatOutputRelative
  New-Item -ItemType Directory -Force -Path $phase4TempRoot | Out-Null
  try {
    $phase4SourceCommit = Invoke-GitText -Arguments @('rev-parse', 'HEAD')
    $phase4Candidate = New-ReasonKitCandidateManifest `
      -CandidateId 'rk2-synthetic-phase4' `
      -CandidateVersion '0.2.0-synthetic' `
      -SourceCommit $phase4SourceCommit `
      -RepositoryRoot $script:PhaseRoot
    $phase4CanonicalA = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $phase4Candidate
    $phase4CanonicalB = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $phase4Candidate
    $phase4DigestCanonicalA = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $phase4Candidate -ForDigest
    $phase4DigestCanonicalB = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $phase4Candidate -ForDigest
    $phase4DigestHashA = Get-ReasonKitCandidateManifestHash -Manifest $phase4Candidate
    $phase4DigestHashB = Get-ReasonKitCandidateManifestHash -Manifest $phase4Candidate
    if ($phase4CanonicalA -cne $phase4CanonicalB -or
        $phase4DigestCanonicalA -cne $phase4DigestCanonicalB -or
        $phase4DigestCanonicalA -match 'candidate_manifest_sha256' -or
        $phase4DigestHashA -cne $phase4DigestHashB -or
        $phase4DigestHashA -cne $phase4Candidate.candidate_manifest_sha256 -or
        $phase4Candidate.candidate_manifest_sha256 -match '^0{64}$') {
      throw 'Phase 4 candidate canonicalization is not deterministic.'
    }
    $phase4Utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($phase4CandidatePath, $phase4CanonicalA, $phase4Utf8)
    $null = Assert-ReasonKitCandidateManifest `
      -Manifest $phase4Candidate `
      -RepositoryRoot $script:PhaseRoot `
      -ExpectedSourceCommit $phase4SourceCommit `
      -SchemaPath (Join-Path $script:PhaseRoot 'core/candidate-manifest.schema.json') `
      -ManifestText $phase4CanonicalA

    Assert-Throws -Name 'candidate digest field mutation' -Script {
      $tamperedDigest = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $tamperedDigest.candidate_manifest_sha256 = if ($phase4Candidate.candidate_manifest_sha256 -eq ('a' * 64)) { ('b' * 64) } else { ('a' * 64) }
      Assert-ReasonKitCandidateManifest -Manifest $tamperedDigest -RepositoryRoot $script:PhaseRoot
    }

    $phase4MutationRepo = Join-Path $phase4TempRoot 'mutation-repo'
    New-Item -ItemType Directory -Force -Path $phase4MutationRepo | Out-Null
    foreach ($requiredPath in @(
        'core/tiny-kernel.md',
        'core/module-registry.json',
        'core/specialist-gate.md',
        'core/telemetry.schema.json',
        'core/candidate-manifest.schema.json',
        'scripts/reasonkit-v02.psm1',
        'scripts/run-benchmark.ps1'
    )) {
      $sourcePath = Join-Path $script:PhaseRoot ($requiredPath -replace '/', '\')
      $destinationPath = Join-Path $phase4MutationRepo ($requiredPath -replace '/', '\')
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationPath) | Out-Null
      Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    }
    $mutationRegistry = Get-Content -Raw -LiteralPath (Join-Path $phase4MutationRepo 'core/module-registry.json') | ConvertFrom-Json -Depth 20
    foreach ($mutationModule in @($mutationRegistry.modules)) {
      $moduleRelativePath = [string]$mutationModule.source_path
      $sourcePath = Join-Path $script:PhaseRoot ($moduleRelativePath -replace '/', '\')
      $destinationPath = Join-Path $phase4MutationRepo ($moduleRelativePath -replace '/', '\')
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationPath) | Out-Null
      Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    }
    $mutationDistRoot = Join-Path $phase4MutationRepo 'dist/v0.2'
    New-Item -ItemType Directory -Force -Path $mutationDistRoot | Out-Null
    Copy-Item -Path (Join-Path $script:PhaseRoot 'dist/v0.2/*') -Destination $mutationDistRoot -Recurse -Force
    $mutationKernelPath = Join-Path $phase4MutationRepo 'core/tiny-kernel.md'
    $mutationKernelBytes = [IO.File]::ReadAllBytes($mutationKernelPath)
    if ($mutationKernelBytes.Length -eq 0) {
      throw 'Mutation fixture kernel is unexpectedly empty.'
    }
    $mutationKernelBytes[0] = if ($mutationKernelBytes[0] -eq 0x23) { [byte]0x2D } else { [byte]0x23 }
    [IO.File]::WriteAllBytes($mutationKernelPath, $mutationKernelBytes)
    $phase4MutatedCandidate = New-ReasonKitCandidateManifest `
      -CandidateId 'rk2-synthetic-phase4' `
      -CandidateVersion '0.2.0-synthetic' `
      -SourceCommit $phase4SourceCommit `
      -RepositoryRoot $phase4MutationRepo
    if ($phase4MutatedCandidate.candidate_manifest_sha256 -eq
        $phase4Candidate.candidate_manifest_sha256) {
      throw 'One-byte covered-file mutation did not change the candidate digest.'
    }
    Assert-Throws -Name 'candidate unresolved source commit' -Script {
      $badSource = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $badSource.source_commit = ('0' * 40)
      $badSource.candidate_manifest_sha256 = Get-ReasonKitCandidateManifestHash -Manifest $badSource
      Assert-ReasonKitCandidateManifest -Manifest $badSource -RepositoryRoot $script:PhaseRoot
    }
    Assert-Throws -Name 'candidate duplicate path' -Script {
      $duplicate = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $duplicate.covered_files = @($duplicate.covered_files + $duplicate.covered_files[0])
      Assert-ReasonKitCandidateManifest -Manifest $duplicate -RepositoryRoot $script:PhaseRoot
    }
    Assert-Throws -Name 'candidate missing file' -Script {
      $missing = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $missing.covered_files = @($missing.covered_files | Where-Object { $_.repository_relative_path -ne 'core/tiny-kernel.md' })
      Assert-ReasonKitCandidateManifest -Manifest $missing -RepositoryRoot $script:PhaseRoot
    }
    Assert-Throws -Name 'candidate declared SHA mismatch' -Script {
      $badSha = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $badSha.covered_files[0].sha256 = ('b' * 64)
      Assert-ReasonKitCandidateManifest -Manifest $badSha -RepositoryRoot $script:PhaseRoot
    }
    Assert-Throws -Name 'candidate source commit mismatch' -Script {
      Assert-ReasonKitCandidateManifest -Manifest $phase4Candidate -RepositoryRoot $script:PhaseRoot -ExpectedSourceCommit (('0' * 40) -join '')
    }
    Assert-Throws -Name 'candidate kernel hash mismatch' -Script {
      $badKernel = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $badKernel.kernel_sha256 = ('c' * 64)
      Assert-ReasonKitCandidateManifest -Manifest $badKernel -RepositoryRoot $script:PhaseRoot
    }
    Assert-Throws -Name 'candidate registry hash mismatch' -Script {
      $badRegistry = ($phase4Candidate | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
      $badRegistry.module_manifest_sha256 = ('d' * 64)
      Assert-ReasonKitCandidateManifest -Manifest $badRegistry -RepositoryRoot $script:PhaseRoot
    }

    $phase4Telemetry = New-ReasonKitTelemetryRecord `
      -RunId 'synthetic-phase4-run' `
      -TaskId 'synthetic' `
      -Arm 'C' `
      -CandidateManifest $phase4Candidate `
      -SourceCommit $phase4SourceCommit `
      -Context $firstPlan.telemetry `
      -Specialists $phase3Conflict.telemetry
    if ($null -ne $phase4Telemetry.provider_measurements.total_tokens -or
        ($phase4Telemetry.context | ConvertTo-Json -Depth 50) -match 'candidate_id') {
      throw 'Candidate binding leaked into context or fabricated total_tokens.'
    }
    $phase4Telemetry = Update-ReasonKitTelemetryRecord `
      -Document $phase4Telemetry `
      -ProviderMeasurements ([ordered]@{
        input_tokens = 10
        cached_input_tokens = 8
        output_tokens = 2
        reasoning_tokens = $null
        total_tokens = $null
        tool_calls = 1
        agent_count = $null
        duration_seconds = $null
      })
    if ($phase4Telemetry.provider_measurements.total_tokens -ne $null -or
        $phase4Telemetry.provider_measurements.input_tokens -ne 10) {
      throw 'Provider measurements were recomputed or not preserved as nullable fields.'
    }
    foreach ($moduleRecord in @($phase4Telemetry.context.modules_loaded)) {
      if ($null -ne $moduleRecord.PSObject.Properties['provider_cache']) {
        throw 'Provider cache was conflated with loader reuse telemetry.'
      }
    }
    $null = Assert-ReasonKitTelemetryRecord -Document $phase4Telemetry

    $legacyOutput = @(& .\scripts\run-benchmark.ps1 -Case TASK-001 -Arm A -OutputRoot ('phase4-legacy-' + [Guid]::NewGuid().ToString('N')))
    $legacyPrepared = @($legacyOutput | Where-Object { $_.ToString().StartsWith('prepared ') } | Select-Object -Last 1)
    if ($legacyPrepared.Count -ne 1) {
      throw 'Historical v0.1 runner compatibility preparation failed.'
    }
    $legacyRelative = $legacyPrepared[0].ToString().Substring('prepared '.Length)
    $legacyPath = Join-Path $script:PhaseRoot $legacyRelative
    if (Test-Path -LiteralPath (Join-Path $legacyPath 'telemetry.json') -PathType Leaf) {
      throw 'Historical v0.1 runner unexpectedly emitted a v0.2 telemetry sidecar.'
    }
    Remove-Item -LiteralPath (Split-Path -Parent $legacyPath) -Recurse -Force -ErrorAction SilentlyContinue

    $v02Output = @(& .\scripts\run-benchmark.ps1 `
      -Profile v0.2 `
      -Case TASK-001 `
      -Arm A `
      -CandidateManifestPath $phase4CandidatePath `
      -BenchmarkManifestPath (Join-Path $script:PhaseRoot 'evals/benchmark.json') `
      -OutputRoot $phase4OutputRelative)
    $v02Prepared = @($v02Output | Where-Object { $_.ToString().StartsWith('prepared ') } | Select-Object -Last 1)
    if ($v02Prepared.Count -ne 1) {
      throw 'v0.2 runner did not prepare one isolated packet.'
    }
    $v02Relative = $v02Prepared[0].ToString().Substring('prepared '.Length)
    $v02Path = Join-Path $script:PhaseRoot $v02Relative
    $v02Metadata = Get-Content -Raw -LiteralPath (Join-Path $v02Path 'run.json') | ConvertFrom-Json -Depth 80
    $v02Sidecar = Get-Content -Raw -LiteralPath (Join-Path $v02Path 'telemetry.json') | ConvertFrom-Json -Depth 80
    if ($v02Metadata.candidate_id -ne $phase4Candidate.candidate_id -or
        $v02Metadata.candidate_manifest_sha256 -ne $phase4Candidate.candidate_manifest_sha256 -or
        $v02Sidecar.identity.candidate_id -ne $phase4Candidate.candidate_id -or
        $v02Sidecar.identity.candidate_manifest_sha256 -ne $phase4Candidate.candidate_manifest_sha256 -or
        @((Get-ChildItem -LiteralPath (Join-Path $v02Path 'workspace') -Recurse -File | Where-Object { $_.Name -match 'candidate' })).Count -gt 0) {
      throw 'v0.2 candidate provenance binding or prompt-isolation contract failed.'
    }
    if ($null -ne $v02Sidecar.provider_measurements.total_tokens) {
      throw 'v0.2 prepared telemetry fabricated total_tokens.'
    }

    $v02ContextPlanPath = Join-Path $v02Path 'context-plan.json'
    if (-not (Test-Path -LiteralPath $v02ContextPlanPath -PathType Leaf) -or
        $v02Metadata.context_plan_file -ne ($v02Relative.Replace('\', '/') + '/context-plan.json')) {
      throw 'v0.2 runner did not emit the deterministic context-plan sidecar before host execution.'
    }
    $v02ContextPlanText = [IO.File]::ReadAllText($v02ContextPlanPath)
    if ([string]::IsNullOrWhiteSpace($v02ContextPlanText) -or
        $v02ContextPlanText -match [regex]::Escape([string]$v02Metadata.run_id) -or
        $v02ContextPlanText -match 'created_at_utc') {
      throw 'v0.2 context-plan sidecar contains nondeterministic packet metadata.'
    }
    $v02RepeatOutput = @(& .\scripts\run-benchmark.ps1 `
      -Profile v0.2 `
      -Case TASK-001 `
      -Arm A `
      -CandidateManifestPath $phase4CandidatePath `
      -BenchmarkManifestPath (Join-Path $script:PhaseRoot 'evals/benchmark.json') `
      -OutputRoot $phase4RepeatOutputRelative)
    $v02RepeatPrepared = @($v02RepeatOutput | Where-Object { $_.ToString().StartsWith('prepared ') } | Select-Object -Last 1)
    if ($v02RepeatPrepared.Count -ne 1) {
      throw 'v0.2 deterministic context-plan repeat packet was not prepared.'
    }
    $v02RepeatRelative = $v02RepeatPrepared[0].ToString().Substring('prepared '.Length)
    $v02RepeatPath = Join-Path $script:PhaseRoot $v02RepeatRelative
    $v02RepeatContextPlanText = [IO.File]::ReadAllText((Join-Path $v02RepeatPath 'context-plan.json'))
    if ($v02ContextPlanText -cne $v02RepeatContextPlanText) {
      throw 'Identical v0.2 context-plan inputs did not produce identical sidecar bytes.'
    }

    $providerHostScript = Join-Path $phase4TempRoot 'provider-host.ps1'
    $providerHostText = @'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$metricsPath = $env:REASONKIT_METRICS_FILE
$metrics = Get-Content -Raw -LiteralPath $metricsPath | ConvertFrom-Json -Depth 80
$metrics.input_tokens = 17
$metrics.cached_input_tokens = 11
$metrics.output_tokens = 3
$metrics.reasoning_tokens = 4
$metrics.total_tokens = 999
$metrics.tool_calls = 2
$metrics.agent_count = 0
$metrics.duration_seconds = 1.25
$metrics.provider_status = 'COMPLETED'
$metrics.model_completion_status = 'COMPLETED'
$metrics.task_success = $true
$metrics.scope_violation = $false
$metrics.evaluator_validity = 'NOT_APPLICABLE'
$metrics.failure_class = $null
$metrics.verification = [ordered]@{ result = 'PASS'; evidence = @('synthetic-provider-verification') }
$metrics.stop = [ordered]@{ decision = 'STOP'; reason = 'Synthetic host completed.' }
[IO.File]::WriteAllText($metricsPath, ($metrics | ConvertTo-Json -Depth 80), $utf8NoBom)
$planPath = $env:REASONKIT_CONTEXT_PLAN_FILE
$observation = [ordered]@{
  context_plan_exists = Test-Path -LiteralPath $planPath -PathType Leaf
  telemetry_exists = Test-Path -LiteralPath $env:REASONKIT_TELEMETRY_FILE -PathType Leaf
  metrics_exists = Test-Path -LiteralPath $metricsPath -PathType Leaf
  recovery_of = $env:REASONKIT_RECOVERY_OF
  context_plan_text = if (Test-Path -LiteralPath $planPath -PathType Leaf) { [IO.File]::ReadAllText($planPath) } else { '' }
}
[IO.File]::WriteAllText((Join-Path $env:REASONKIT_WORKSPACE 'host-observation.json'), ($observation | ConvertTo-Json -Depth 20), $utf8NoBom)
Write-Output 'completed-host-output'
'@
    [IO.File]::WriteAllText($providerHostScript, $providerHostText, $phase4Utf8)

    $completedOutput = @(& .\scripts\run-benchmark.ps1 `
      -Profile v0.2 `
      -Case TASK-001 `
      -Arm A `
      -CandidateManifestPath $phase4CandidatePath `
      -BenchmarkManifestPath (Join-Path $script:PhaseRoot 'evals/benchmark.json') `
      -OutputRoot $phase4OutputRelative `
      -Command 'pwsh.exe' `
      -ArgumentList @('-NoProfile', '-File', $providerHostScript))
    $completedRan = @($completedOutput | Where-Object { $_.ToString().StartsWith('ran ') } | Select-Object -Last 1)
    if ($completedRan.Count -ne 1) {
      throw 'Provider-written metrics host did not complete one v0.2 packet.'
    }
    $completedRelative = $completedRan[0].ToString().Substring('ran '.Length).Split(' (exit=')[0]
    $completedPath = Join-Path $script:PhaseRoot $completedRelative
    $completedMetadata = Get-Content -Raw -LiteralPath (Join-Path $completedPath 'run.json') | ConvertFrom-Json -Depth 80
    $completedTelemetry = Get-Content -Raw -LiteralPath (Join-Path $completedPath 'telemetry.json') | ConvertFrom-Json -Depth 80
    $completedObservation = Get-Content -Raw -LiteralPath (Join-Path $completedPath 'workspace/host-observation.json') | ConvertFrom-Json -Depth 20
    $completedRawPath = Join-Path $completedPath 'model-output.txt'
    $completedRawText = [IO.File]::ReadAllText($completedRawPath)
    $completedRawHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $completedRawPath).Hash.ToLowerInvariant()
    if ($completedMetadata.context_plan_file -ne ($completedRelative.Replace('\', '/') + '/context-plan.json') -or
        $completedObservation.context_plan_exists -ne $true -or
        $completedObservation.telemetry_exists -ne $true -or
        $completedObservation.metrics_exists -ne $true -or
        -not [string]::IsNullOrWhiteSpace([string]$completedObservation.recovery_of) -or
        $completedObservation.context_plan_text -cne $v02ContextPlanText -or
        $completedRawText -cne "completed-host-output$([Environment]::NewLine)" -or
        $completedTelemetry.provider_measurements.input_tokens -ne 17 -or
        $completedTelemetry.provider_measurements.cached_input_tokens -ne 11 -or
        $completedTelemetry.provider_measurements.output_tokens -ne 3 -or
        $completedTelemetry.provider_measurements.reasoning_tokens -ne 4 -or
        $completedTelemetry.provider_measurements.total_tokens -ne 999 -or
        $completedTelemetry.provider_measurements.tool_calls -ne 2 -or
        $completedTelemetry.provider_measurements.agent_count -ne 0 -or
        $completedTelemetry.provider_measurements.duration_seconds -ne 1.25 -or
        $completedTelemetry.outcome.provider_status -ne 'COMPLETED' -or
        $completedTelemetry.outcome.model_completion_status -ne 'COMPLETED' -or
        $completedTelemetry.outcome.task_success -ne $true) {
      throw 'Runner did not preserve provider-written measurements, sidecar paths, or completed raw output.'
    }
    $completedRawHashAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $completedRawPath).Hash.ToLowerInvariant()
    if ($completedRawHashBefore -cne $completedRawHashAfter) {
      throw 'Completed raw output changed after telemetry processing.'
    }

    $abortedHostScript = Join-Path $phase4TempRoot 'provider-abort-host.ps1'
    $abortedHostText = @'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$metricsPath = $env:REASONKIT_METRICS_FILE
$metrics = Get-Content -Raw -LiteralPath $metricsPath | ConvertFrom-Json -Depth 80
$metrics.provider_status = 'ABORTED'
$metrics.model_completion_status = 'NOT_STARTED'
$metrics.task_success = $null
$metrics.scope_violation = $null
$metrics.evaluator_validity = 'UNKNOWN'
$metrics.failure_class = 'PROVIDER_ABORTED'
$metrics.verification = [ordered]@{ result = 'NOT_RUN'; evidence = @('provider-abort') }
$metrics.stop = [ordered]@{ decision = 'STOP'; reason = 'Provider usage limit.' }
[IO.File]::WriteAllText($metricsPath, ($metrics | ConvertTo-Json -Depth 80), $utf8NoBom)
Write-Output 'provider-aborted-output'
exit 17
'@
    [IO.File]::WriteAllText($abortedHostScript, $abortedHostText, $phase4Utf8)

    $abortedOutput = @(& .\scripts\run-benchmark.ps1 `
      -Profile v0.2 `
      -Case TASK-001 `
      -Arm A `
      -CandidateManifestPath $phase4CandidatePath `
      -BenchmarkManifestPath (Join-Path $script:PhaseRoot 'evals/benchmark.json') `
      -OutputRoot $phase4OutputRelative `
      -Command 'pwsh.exe' `
      -ArgumentList @('-NoProfile', '-File', $abortedHostScript))
    $abortedRan = @($abortedOutput | Where-Object { $_.ToString().StartsWith('ran ') } | Select-Object -Last 1)
    if ($abortedRan.Count -ne 1) {
      throw 'Provider-aborted host did not produce one preserved packet.'
    }
    $abortedRelative = $abortedRan[0].ToString().Substring('ran '.Length).Split(' (exit=')[0]
    $abortedPath = Join-Path $script:PhaseRoot $abortedRelative
    $abortedMetadataTextBefore = [IO.File]::ReadAllText((Join-Path $abortedPath 'run.json'))
    $abortedMetadata = $abortedMetadataTextBefore | ConvertFrom-Json -Depth 80
    $abortedMetricsTextBefore = [IO.File]::ReadAllText((Join-Path $abortedPath 'metrics.json'))
    $abortedTelemetryTextBefore = [IO.File]::ReadAllText((Join-Path $abortedPath 'telemetry.json'))
    $abortedRawPath = Join-Path $abortedPath 'model-output.txt'
    $abortedRawTextBefore = [IO.File]::ReadAllText($abortedRawPath)
    $abortedRawHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $abortedRawPath).Hash.ToLowerInvariant()
    $abortedTelemetry = $abortedTelemetryTextBefore | ConvertFrom-Json -Depth 80
    if ($abortedTelemetry.outcome.provider_status -ne 'ABORTED' -or
        $abortedTelemetry.outcome.model_completion_status -ne 'NOT_STARTED' -or
        $abortedTelemetry.outcome.failure_class -ne 'PROVIDER_ABORTED' -or
        $abortedRawTextBefore -cne "provider-aborted-output$([Environment]::NewLine)") {
      throw 'PROVIDER_ABORTED packet was not preserved with provider-owned outcome evidence.'
    }

    $recoveryOutput = @(& .\scripts\run-benchmark.ps1 `
      -Profile v0.2 `
      -Case TASK-001 `
      -Arm A `
      -CandidateManifestPath $phase4CandidatePath `
      -BenchmarkManifestPath (Join-Path $script:PhaseRoot 'evals/benchmark.json') `
      -OutputRoot $phase4OutputRelative `
      -RecoveryOf $abortedMetadata.run_id `
      -Command 'pwsh.exe' `
      -ArgumentList @('-NoProfile', '-File', $providerHostScript))
    $recoveryRan = @($recoveryOutput | Where-Object { $_.ToString().StartsWith('ran ') } | Select-Object -Last 1)
    if ($recoveryRan.Count -ne 1) {
      throw 'Provider recovery host did not produce one new packet.'
    }
    $recoveryRelative = $recoveryRan[0].ToString().Substring('ran '.Length).Split(' (exit=')[0]
    $recoveryPath = Join-Path $script:PhaseRoot $recoveryRelative
    $recoveryMetadata = Get-Content -Raw -LiteralPath (Join-Path $recoveryPath 'run.json') | ConvertFrom-Json -Depth 80
    $recoveryObservation = Get-Content -Raw -LiteralPath (Join-Path $recoveryPath 'workspace/host-observation.json') | ConvertFrom-Json -Depth 20
    if ($recoveryMetadata.run_id -eq $abortedMetadata.run_id -or
        $recoveryMetadata.recovery_of -ne $abortedMetadata.run_id -or
        $recoveryObservation.recovery_of -ne $abortedMetadata.run_id -or
        -not (Test-Path -LiteralPath $abortedPath -PathType Container) -or
        -not (Test-Path -LiteralPath $abortedRawPath -PathType Leaf) -or
        (Get-FileHash -Algorithm SHA256 -LiteralPath $abortedRawPath).Hash.ToLowerInvariant() -cne $abortedRawHashBefore -or
        [IO.File]::ReadAllText((Join-Path $abortedPath 'run.json')) -cne $abortedMetadataTextBefore -or
        [IO.File]::ReadAllText((Join-Path $abortedPath 'metrics.json')) -cne $abortedMetricsTextBefore -or
        [IO.File]::ReadAllText((Join-Path $abortedPath 'telemetry.json')) -cne $abortedTelemetryTextBefore) {
      throw 'Recovery replaced, rewrote, or deleted the original PROVIDER_ABORTED packet.'
    }

    Write-Output 'phase4_candidate_manifest_tests=PASS'
    Write-Output 'phase4_telemetry_binding_tests=PASS'
    Write-Output 'phase4_runner_compatibility_tests=PASS'
  }
  finally {
    Remove-Item -LiteralPath $phase4TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $phase4OutputAbsolute -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $phase4RepeatOutputAbsolute -Recurse -Force -ErrorAction SilentlyContinue
  }

  Write-Output 'rk2_03_no_spawn_tests=PASS'
  Write-Output 'rk2_03_authorization_tests=PASS'
  Write-Output 'rk2_03_lifecycle_tests=PASS'
  Write-Output 'rk2_03_negative_invariant_tests=PASS'
  Write-Output 'rk2_03_specialist_cap_tests=PASS'
  Write-Output 'rk2_03_adversarial_cap_tests=PASS'
  Write-Output 'rk2_03_report_shape_tests=PASS'
  Write-Output 'rk2_03_report_budget_tests=PASS'
  Write-Output 'rk2_03_telemetry_schema_tests=PASS'
  Write-Output 'rk2_03_determinism_tests=PASS'
  Write-Output 'rk2_03_lifecycle_determinism_tests=PASS'
  Write-Output ('rk2_03_record_A=' + ($phase3RecordA | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_B=' + ($phase3RecordB | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_C=' + ($phase3RecordC | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_I=' + ($phase3RecordAuthorizationOnly | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_J=' + ($phase3RecordStarted | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_K=' + ($phase3RecordDuplicateStart | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_L=' + ($phase3RecordStartWithoutAuthorization | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_M=' + ($phase3RecordRecursiveStart | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_N=' + ($phase3RecordCapStart | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_D=' + ($phase3RecordD | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_E=' + ($phase3RecordE | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_F=' + ($phase3RecordF | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_G=' + ($phase3RecordG | ConvertTo-Json -Compress -Depth 30))
  Write-Output ('rk2_03_record_H=' + ($phase3RecordH | ConvertTo-Json -Compress -Depth 30))

  Write-Output 'Phase 0 v0.2 synthetic tests passed'
  Write-Output ('baseline_commit=' + $script:BaselineCommit)
  Write-Output ('frozen_design_sha256=' + $mirrorHash)
  Write-Output ('tokenizer=' + $script:TokenizerPackage + '/' + $tokenizerVersion + '/' + $script:TokenizerEncoding)
  Write-Output ('tokenizer_measurement=' + $script:TokenizerMeasurementKind)
  Write-Output ('guarded_v01_files=' + $script:FrozenV01Hashes.Count)
  Write-Output ('phase1_mutable_v01_seams=' + ($script:Phase1MutableV01Seams -join ','))
  Write-Output ('kernel_sha256=' + $kernelSha256)
  Write-Output ('kernel_utf8_bytes=' + $kernelBytes.Length)
  Write-Output ('kernel_build_estimate_tokens=' + $kernelTokens)
  Write-Output ('generated_kernel_sha256=' + $generatedKernelSha256)
  Write-Output ('registry_sha256=' + $registrySha256)
  Write-Output ('registry_utf8_bytes=' + $registryBytes.Length)
  Write-Output ('registry_build_estimate_tokens=' + $registryTokens)
  Write-Output 'rk2_02_loader_tests=PASS'
}
finally {
  Pop-Location
}
