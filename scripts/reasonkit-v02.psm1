$ErrorActionPreference = 'Stop'

$script:ReasonKitRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:TokenizerPackage = 'tiktoken'
$script:TokenizerVersion = '0.14.0'
$script:TokenizerEncoding = 'cl100k_base'
$script:TokenizerMeasurement = 'build_estimate'
$script:Utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
$script:Utf8Strict = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false, $true)
$script:ExpectedKernelSha256 = 'b23a87ddac73658f7191c5682182d83a379556520e7d08935b064e50b4d7d31a'

function Get-RkProperty {
  param(
    [Parameter(Mandatory = $false)]
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }
  if ($Object -is [System.Collections.IDictionary] -and $Object.Contains($Name)) {
    return $Object[$Name]
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function Get-RkItems {
  param(
    [Parameter(Mandatory = $false)]
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $value = Get-RkProperty -Object $Object -Name $Name
  if ($null -eq $value) {
    return @()
  }
  return @($value)
}

function Normalize-RkPath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    throw 'Repository path is empty.'
  }
  $normalized = $Path.Replace('\', '/')
  while ($normalized.StartsWith('./', [StringComparison]::Ordinal)) {
    $normalized = $normalized.Substring(2)
  }
  if ([string]::IsNullOrWhiteSpace($normalized) -or
      $normalized.StartsWith('/', [StringComparison]::Ordinal) -or
      $normalized -match '^[A-Za-z]:/' -or
      $normalized -match '(^|/)\.\.?(/|$)' -or
      $normalized -match '//' -or
      $normalized -match '[*?\[\]]') {
    throw ('Non-canonical repository path: ' + $Path)
  }
  return $normalized
}

function Resolve-RkRepositoryPath {
  param(
    [string]$RepositoryRoot,
    [string]$RepositoryRelativePath
  )

  $canonical = Normalize-RkPath -Path $RepositoryRelativePath
  $absolute = Join-Path $RepositoryRoot ($canonical -replace '/', '\')
  return [pscustomobject]@{
    relative_path = $canonical
    absolute_path = $absolute
  }
}

function Get-RkBytesSha256 {
  param([byte[]]$Bytes)

  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant()
  }
  finally {
    $sha.Dispose()
  }
}

function Normalize-RkText {
  param([string]$Text)

  $normalized = $Text.Replace(([string][char]13 + [string][char]10), [string][char]10)
  $normalized = $normalized.Replace([string][char]13, [string][char]10)
  $normalized = [Regex]::Replace($normalized, '[ \t]+(?=' + [string][char]10 + '|$)', '')
  while ($normalized.EndsWith([string][char]10, [StringComparison]::Ordinal)) {
    $normalized = $normalized.Substring(0, $normalized.Length - 1)
  }
  return $normalized + [string][char]10
}

function Get-RkPythonExecutable {
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

function Get-RkTokenizerVersion {
  param([string]$Python)

  $output = @(
    & $Python -c "import importlib.metadata as m; print(m.version('tiktoken'))" 2>&1 |
      ForEach-Object { $_.ToString() }
  )
  if ($LASTEXITCODE -ne 0) {
    throw ('Pinned tokenizer package is unavailable: ' + ($output -join ' '))
  }
  return (($output | Select-Object -Last 1).ToString().Trim())
}

function Get-RkTokenizerEstimate {
  param(
    [string]$Text,
    [string]$Python
  )

  $temporaryPath = Join-Path ([IO.Path]::GetTempPath()) ('reasonkit-v02-loader-token-' + [Guid]::NewGuid().ToString('N') + '.txt')
  [IO.File]::WriteAllText($temporaryPath, $Text, $script:Utf8NoBom)
  try {
    $code = "import pathlib,sys,tiktoken; data=pathlib.Path(sys.argv[1]).read_bytes().decode('utf-8'); enc=tiktoken.get_encoding('cl100k_base'); print(len(enc.encode(data, disallowed_special=())))"
    $output = @(
      & $Python -c $code $temporaryPath 2>&1 |
        ForEach-Object { $_.ToString() }
    )
    if ($LASTEXITCODE -ne 0) {
      throw ('Tokenizer estimate failed: ' + ($output -join ' '))
    }
    $estimate = (($output | Select-Object -Last 1).ToString().Trim())
    if ($estimate -notmatch '^[0-9]+$') {
      throw ('Tokenizer returned a non-numeric estimate: ' + $estimate)
    }
    return [int]$estimate
  }
  finally {
    Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
  }
}

function Get-RkTextMetrics {
  param(
    [string]$Text,
    [string]$Python
  )

  $normalized = Normalize-RkText -Text $Text
  $bytes = $script:Utf8NoBom.GetBytes($normalized)
  $version = Get-RkTokenizerVersion -Python $Python
  if ($version -ne $script:TokenizerVersion) {
    throw ('Tokenizer version mismatch. Expected ' + $script:TokenizerVersion + ', got ' + $version)
  }
  return [pscustomobject]@{
    text = $normalized
    bytes = $bytes
    sha256 = Get-RkBytesSha256 -Bytes $bytes
    byte_count = $bytes.Length
    token_count = Get-RkTokenizerEstimate -Text $normalized -Python $Python
  }
}

function Assert-RkRegistry {
  param([object]$Registry)

  if ($null -eq $Registry) {
    throw 'Module registry is null.'
  }
  if ((Get-RkProperty -Object $Registry -Name 'schema_version') -ne '0.2') {
    throw 'Unsupported module registry schema version.'
  }
  foreach ($field in @('schema_version', 'registry_id', 'modules', 'routes')) {
    if ($null -eq $Registry.PSObject.Properties[$field]) {
      throw ('Module registry field is missing: ' + $field)
    }
  }
  $allowedTopFields = @('schema_version', 'registry_id', 'modules', 'routes')
  foreach ($propertyName in @($Registry.PSObject.Properties.Name)) {
    if ($allowedTopFields -notcontains $propertyName) {
      throw ('Unexpected module registry field: ' + $propertyName)
    }
  }
  if ([string]::IsNullOrWhiteSpace((Get-RkProperty -Object $Registry -Name 'registry_id'))) {
    throw 'Module registry ID is empty.'
  }

  $modules = @(Get-RkProperty -Object $Registry -Name 'modules')
  if ($modules.Count -eq 0) {
    throw 'Module registry has no modules.'
  }
  $moduleById = @{}
  foreach ($module in $modules) {
    foreach ($propertyName in @($module.PSObject.Properties.Name)) {
      if (@('module_id', 'source_path') -notcontains $propertyName) {
        throw ('Unexpected module field: ' + $propertyName)
      }
    }
    $moduleId = Get-RkProperty -Object $module -Name 'module_id'
    $sourcePath = Get-RkProperty -Object $module -Name 'source_path'
    if ([string]::IsNullOrWhiteSpace($moduleId) -or [string]::IsNullOrWhiteSpace($sourcePath)) {
      throw 'Every registry module needs a module_id and source_path.'
    }
    if ($moduleById.ContainsKey($moduleId)) {
      throw ('Duplicate registry module ID: ' + $moduleId)
    }
    $moduleById[$moduleId] = [pscustomobject]@{
      module_id = $moduleId
      source_path = Normalize-RkPath -Path $sourcePath
    }
  }

  $routes = @(Get-RkProperty -Object $Registry -Name 'routes')
  if ($routes.Count -eq 0) {
    throw 'Module registry has no routes.'
  }
  $routeIds = @{}
  foreach ($route in $routes) {
    foreach ($propertyName in @($route.PSObject.Properties.Name)) {
      if (@('route_id', 'module_ids', 'conditional_modules', 'trigger_summary') -notcontains $propertyName) {
        throw ('Unexpected route field: ' + $propertyName)
      }
    }
    $routeId = Get-RkProperty -Object $route -Name 'route_id'
    $moduleIds = @(Get-RkProperty -Object $route -Name 'module_ids')
    $triggerSummary = Get-RkProperty -Object $route -Name 'trigger_summary'
    if ([string]::IsNullOrWhiteSpace($routeId) -or
        [string]::IsNullOrWhiteSpace($triggerSummary) -or
        $moduleIds.Count -eq 0) {
      throw 'Every registry route needs a route_id, trigger_summary, and module_ids.'
    }
    if ($routeIds.ContainsKey($routeId)) {
      throw ('Duplicate registry route ID: ' + $routeId)
    }
    $routeIds[$routeId] = $true
    $routeModuleIds = @{}
    $conditionalModuleIds = @{}
    foreach ($moduleId in $moduleIds) {
      if (-not $moduleById.ContainsKey($moduleId)) {
        throw ('Unresolved registry route module: ' + $moduleId)
      }
      if ($routeModuleIds.ContainsKey($moduleId)) {
        throw ('Duplicate module in route: ' + $routeId + '/' + $moduleId)
      }
      $routeModuleIds[$moduleId] = $true
    }
    $conditionalModules = @(
      Get-RkProperty -Object $route -Name 'conditional_modules' |
        Where-Object { $null -ne $_ }
    )
    foreach ($conditional in $conditionalModules) {
      foreach ($propertyName in @($conditional.PSObject.Properties.Name)) {
        if (@('module_id', 'capability') -notcontains $propertyName) {
          throw ('Unexpected conditional module field: ' + $propertyName)
        }
      }
      $moduleId = Get-RkProperty -Object $conditional -Name 'module_id'
      $capability = Get-RkProperty -Object $conditional -Name 'capability'
      if (-not $moduleById.ContainsKey($moduleId) -or [string]::IsNullOrWhiteSpace($capability)) {
        throw ('Invalid conditional module on route: ' + $routeId)
      }
      if ($routeModuleIds.ContainsKey($moduleId)) {
        throw ('Conditional module is already a default module: ' + $routeId + '/' + $moduleId)
      }
      if ($conditionalModuleIds.ContainsKey($moduleId)) {
        throw ('Duplicate conditional module in route: ' + $routeId + '/' + $moduleId)
      }
      $conditionalModuleIds[$moduleId] = $true
    }
  }

  return [pscustomobject]@{
    registry = $Registry
    modules_by_id = $moduleById
    routes_by_id = $routeIds
  }
}

function Read-ReasonKitModuleRegistry {
  [CmdletBinding()]
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = Join-Path $script:ReasonKitRoot 'core/module-registry.json'
  }
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw ('Module registry file is missing: ' + $Path)
  }
  $registry = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -Depth 30
  $null = Assert-RkRegistry -Registry $registry
  return $registry
}

function New-ReasonKitRunState {
  [CmdletBinding()]
  param()

  return [pscustomobject]@{
    loaded_by_key = @{}
    loaded_by_module = @{}
    load_records = [System.Collections.Generic.List[object]]::new()
    injected_context = [System.Collections.Generic.List[string]]::new()
    next_order = 1
    request_count = 0
  }
}

function Assert-RkRunState {
  param([object]$RunState)

  if ($null -eq $RunState) {
    throw 'Per-run state is required.'
  }
  foreach ($field in @('loaded_by_key', 'loaded_by_module', 'load_records', 'injected_context', 'next_order', 'request_count')) {
    if ($null -eq $RunState.PSObject.Properties[$field]) {
      throw ('Per-run state field is missing: ' + $field)
    }
  }
}

function Get-RkEvidenceValue {
  param(
    [object]$Evidence,
    [string]$Name
  )

  $value = Get-RkProperty -Object $Evidence -Name $Name
  if ($null -ne $value) {
    return $value
  }
  if ($Evidence -is [string] -and $Name -eq 'load_reason') {
    return $Evidence
  }
  return $null
}

function Get-RkModuleRecord {
  param(
    [object]$Module,
    [object]$Manifest,
    [object]$Evidence,
    [object]$RunState,
    [string]$RepositoryRoot,
    [string]$Phase,
    [string]$ParentRoute,
    [int]$Order,
    [string]$Python
  )

  $moduleId = Get-RkProperty -Object $Module -Name 'module_id'
  $sourcePath = Normalize-RkPath -Path (Get-RkProperty -Object $Module -Name 'source_path')
  $manifestEntries = @(
    Get-RkItems -Object $Manifest -Name 'modules' |
      Where-Object { (Get-RkProperty -Object $_ -Name 'module_id') -eq $moduleId }
  )
  if ($manifestEntries.Count -ne 1) {
    throw ('Manifest must contain exactly one provenance entry for: ' + $moduleId)
  }
  $manifestEntry = $manifestEntries[0]
  $manifestSourcePath = Normalize-RkPath -Path (Get-RkProperty -Object $manifestEntry -Name 'source_path')
  if ($manifestSourcePath -cne $sourcePath) {
    throw ('Registry and provenance paths differ for: ' + $moduleId)
  }
  $expectedSha = ([string](Get-RkProperty -Object $manifestEntry -Name 'sha256')).ToLowerInvariant()
  if ($expectedSha -notmatch '^[0-9a-f]{64}$') {
    throw ('Invalid expected module SHA-256 for: ' + $moduleId)
  }
  $resolved = Resolve-RkRepositoryPath -RepositoryRoot $RepositoryRoot -RepositoryRelativePath $sourcePath
  if (-not (Test-Path -LiteralPath $resolved.absolute_path -PathType Leaf)) {
    throw ('Module source file is missing: ' + $sourcePath)
  }
  $rawBytes = [IO.File]::ReadAllBytes($resolved.absolute_path)
  $actualSha = Get-RkBytesSha256 -Bytes $rawBytes
  if ($actualSha -cne $expectedSha) {
    throw ('Module source SHA-256 mismatch: ' + $moduleId)
  }
  $rawText = $script:Utf8Strict.GetString($rawBytes)
  $metrics = Get-RkTextMetrics -Text $rawText -Python $Python
  $loadReason = [string](Get-RkEvidenceValue -Evidence $Evidence -Name 'load_reason')
  if ([string]::IsNullOrWhiteSpace($loadReason)) {
    throw ('Load evidence is missing a load_reason for: ' + $moduleId)
  }
  $reloadReasonValue = Get-RkEvidenceValue -Evidence $Evidence -Name 'reload_reason'
  $reloadReason = if ($null -eq $reloadReasonValue) { $null } else { [string]$reloadReasonValue }
  $phaseBoundaryValue = Get-RkEvidenceValue -Evidence $Evidence -Name 'phase_boundary_reload'
  $phaseBoundaryReload = $false
  if ($null -ne $phaseBoundaryValue) {
    $phaseBoundaryReload = [bool]$phaseBoundaryValue
  }

  $moduleKey = $moduleId + '|' + $expectedSha
  $sameRecord = $null
  if ($RunState.loaded_by_key.ContainsKey($moduleKey)) {
    $sameRecord = $RunState.loaded_by_key[$moduleKey]
  }
  $previousRecord = $null
  if ($RunState.loaded_by_module.ContainsKey($moduleId)) {
    $previousRecord = $RunState.loaded_by_module[$moduleId]
  }

  $loadAction = 'loaded'
  $contextInjected = $true
  $previousSha = $null
  $recordReloadReason = $null
  $moduleReuse = [pscustomobject]@{
    reused = $false
    scope = 'same_run'
  }
  if ($null -ne $sameRecord) {
    if ($phaseBoundaryReload) {
      if ([string]::IsNullOrWhiteSpace($reloadReason)) {
        throw ('Same-hash phase-boundary reload requires an explicit reason: ' + $moduleId)
      }
      $loadAction = 'reloaded'
      $previousSha = $expectedSha
      $recordReloadReason = $reloadReason
    }
    elseif (-not [string]::IsNullOrWhiteSpace($reloadReason)) {
      throw ('Same-hash reload requires phase_boundary_reload=true: ' + $moduleId)
    }
    else {
      $loadAction = 'reused'
      $contextInjected = $false
      $moduleReuse = [pscustomobject]@{
        reused = $true
        scope = 'same_run'
      }
    }
  }
  elseif ($null -ne $previousRecord) {
    if ([string]::IsNullOrWhiteSpace($reloadReason)) {
      throw ('Different-hash reload requires an explicit reason: ' + $moduleId)
    }
    $loadAction = 'reloaded'
    $previousSha = $previousRecord.module_sha256
    $recordReloadReason = $reloadReason
  }

  return [pscustomobject][ordered]@{
    module_id = $moduleId
    module_sha256 = $expectedSha
    source_path = $sourcePath
    module_bytes = $rawBytes.Length
    module_tokens_build_estimate = $metrics.token_count
    load_reason = $loadReason
    load_phase = $Phase
    parent_route = $ParentRoute
    load_action = $loadAction
    previous_sha256 = $previousSha
    reload_reason = $recordReloadReason
    context_injected = $contextInjected
    module_reuse = $moduleReuse
    order = $Order
    content = if ($contextInjected) { $metrics.text } else { $null }
  }
}

function Commit-RkModuleRecords {
  param(
    [object[]]$Records,
    [object]$RunState
  )

  foreach ($record in $Records) {
    $key = $record.module_id + '|' + $record.module_sha256
    if ($record.context_injected) {
      $null = $RunState.injected_context.Add($record.content)
    }
    $RunState.loaded_by_key[$key] = $record
    $RunState.loaded_by_module[$record.module_id] = $record
    $null = $RunState.load_records.Add($record)
  }
  $RunState.next_order = $RunState.next_order + @($Records).Count
  $RunState.request_count = $RunState.request_count + 1
}

function Convert-RkLoadPhaseToSchemaValue {
  param([string]$Phase)

  if (@('classification', 'evidence', 'specialist', 'verification', 'other') -contains $Phase) {
    return $Phase
  }
  return 'other'
}

function Convert-RkModuleRecordToTelemetry {
  param([object]$Record)

  $internalReuse = Get-RkProperty -Object $Record -Name 'module_reuse'
  $isReused = [bool](Get-RkProperty -Object $internalReuse -Name 'reused')
  $loadAction = [string](Get-RkProperty -Object $Record -Name 'load_action')
  $reuseScope = if ($isReused) { 'same_run' } else { 'none' }
  $reuseCount = if ($isReused) { 1 } else { 0 }
  $reuseReason = if ($isReused) {
    'same module and hash already loaded in this run'
  }
  elseif ($loadAction -eq 'reloaded') {
    Get-RkProperty -Object $Record -Name 'reload_reason'
  }
  else {
    $null
  }

  return [pscustomobject][ordered]@{
    module_id = Get-RkProperty -Object $Record -Name 'module_id'
    module_sha256 = Get-RkProperty -Object $Record -Name 'module_sha256'
    module_bytes = Get-RkProperty -Object $Record -Name 'module_bytes'
    module_tokens = Get-RkProperty -Object $Record -Name 'module_tokens_build_estimate'
    load_reason = Get-RkProperty -Object $Record -Name 'load_reason'
    load_phase = Convert-RkLoadPhaseToSchemaValue -Phase (Get-RkProperty -Object $Record -Name 'load_phase')
    module_reuse = [pscustomobject][ordered]@{
      reused = $isReused
      count = $reuseCount
      scope = $reuseScope
      reason = $reuseReason
    }
    load_action = $loadAction
    previous_sha256 = Get-RkProperty -Object $Record -Name 'previous_sha256'
    reload_reason = Get-RkProperty -Object $Record -Name 'reload_reason'
    context_injected = [bool](Get-RkProperty -Object $Record -Name 'context_injected')
  }
}

function Convert-RkTelemetryProjection {
  param(
    [string]$Route,
    [object]$KernelMetrics,
    [object]$RegistryMetrics,
    [object[]]$Records,
    [object]$RunState,
    [object]$Manifest,
    [int]$DecisionDurationMs
  )

  $manifestSha = Get-RkProperty -Object $Manifest -Name 'manifest_sha256'
  $schemaModules = @(
    foreach ($record in @($Records)) {
      Convert-RkModuleRecordToTelemetry -Record $record
    }
  )
  $fullBundle = [pscustomobject][ordered]@{
    loaded = $false
    escalation_reason = $null
    requested_by = $null
    approved_by_or_gate = $null
    source_hash = $null
    loaded_bytes = $null
    loaded_tokens_if_deterministic = $null
  }
  $omittedContext = [pscustomobject][ordered]@{
    source_manifest_sha256 = $manifestSha
    module_ids = @()
    bytes = $null
    tokens = $null
    derivation = 'not computed by Phase 2 loader'
    status = 'unavailable'
  }

  return [pscustomobject][ordered]@{
    kernel_bytes = if ($null -eq $KernelMetrics) { $null } else { $KernelMetrics.byte_count }
    kernel_tokens = if ($null -eq $KernelMetrics) { $null } else { $KernelMetrics.token_count }
    loader_index_bytes = if ($null -eq $RegistryMetrics) { $null } else { $RegistryMetrics.byte_count }
    loader_index_tokens = if ($null -eq $RegistryMetrics) { $null } else { $RegistryMetrics.token_count }
    loader_request_count = [int]$RunState.request_count
    loader_decision_duration_ms = $DecisionDurationMs
    route = $Route
    selected_complexity = $null
    modules_loaded = $schemaModules
    omitted_context = $omittedContext
    full_bundle = $fullBundle
    instruction_bytes = $null
  }
}

function Resolve-ReasonKitContext {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Route,
    [Parameter(Mandatory = $true)]
    [object]$Evidence,
    [Parameter(Mandatory = $false)]
    [string]$Phase = 'route',
    [Parameter(Mandatory = $false)]
    [string]$ParentRoute,
    [Parameter(Mandatory = $false)]
    [string[]]$RequiredCapabilities = @(),
    [Parameter(Mandatory = $true)]
    [object]$Registry,
    [Parameter(Mandatory = $true)]
    [object]$Manifest,
    [Parameter(Mandatory = $false)]
    [string]$RepositoryRoot,
    [Parameter(Mandatory = $false)]
    [string]$RegistryPath,
    [Parameter(Mandatory = $true)]
    [object]$RunState
  )

  $watch = [Diagnostics.Stopwatch]::StartNew()
  Assert-RkRunState -RunState $RunState
  if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = $script:ReasonKitRoot
  }
  if ([string]::IsNullOrWhiteSpace($Phase)) {
    $Phase = 'route'
  }
  if ($null -eq $Evidence -or ($Evidence -is [string] -and [string]::IsNullOrWhiteSpace($Evidence))) {
    throw 'Evidence is required for context resolution.'
  }
  $python = Get-RkPythonExecutable
  $kernelPath = Join-Path $RepositoryRoot 'core/tiny-kernel.md'
  if (-not (Test-Path -LiteralPath $kernelPath -PathType Leaf)) {
    throw ('Tiny Kernel is missing: ' + $kernelPath)
  }
  $kernelRawBytes = [IO.File]::ReadAllBytes($kernelPath)
  $kernelSha256 = Get-RkBytesSha256 -Bytes $kernelRawBytes
  if ($kernelSha256 -cne $script:ExpectedKernelSha256) {
    throw ('Tiny Kernel SHA-256 mismatch. Expected ' + $script:ExpectedKernelSha256 + ', got ' + $kernelSha256)
  }
  $kernelText = $script:Utf8Strict.GetString($kernelRawBytes)
  $kernelMetrics = Get-RkTextMetrics -Text $kernelText -Python $python
  $registryIndex = Assert-RkRegistry -Registry $Registry
  $routeItems = @(
    Get-RkItems -Object $Registry -Name 'routes' |
      Where-Object { (Get-RkProperty -Object $_ -Name 'route_id') -eq $Route }
  )
  if ($routeItems.Count -ne 1) {
    throw ('Route is not registered: ' + $Route)
  }
  $routeItem = $routeItems[0]

  $registryMetrics = $null
  if (-not [string]::IsNullOrWhiteSpace($RegistryPath)) {
    if (-not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
      throw ('Registry path is missing: ' + $RegistryPath)
    }
    $registryMetrics = Get-RkTextMetrics -Text ([IO.File]::ReadAllText($RegistryPath)) -Python $python
  }
  $moduleIds = [System.Collections.Generic.List[string]]::new()
  foreach ($moduleId in @(Get-RkProperty -Object $routeItem -Name 'module_ids')) {
    $moduleIds.Add([string]$moduleId)
  }
  $capabilities = @($RequiredCapabilities | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
  foreach ($conditional in @(
    Get-RkProperty -Object $routeItem -Name 'conditional_modules' |
      Where-Object { $null -ne $_ }
  )) {
    $capability = [string](Get-RkProperty -Object $conditional -Name 'capability')
    $conditionalModuleId = [string](Get-RkProperty -Object $conditional -Name 'module_id')
    if ($capabilities -contains $capability) {
      if ($moduleIds -contains $conditionalModuleId) {
        throw ('Conditional module duplicated by route: ' + $conditionalModuleId)
      }
      $moduleIds.Add($conditionalModuleId)
    }
  }

  $records = [System.Collections.Generic.List[object]]::new()
  $recordOrder = [int]$RunState.next_order
  foreach ($moduleId in $moduleIds) {
    $module = $registryIndex.modules_by_id[$moduleId]
    $record = Get-RkModuleRecord `
      -Module $module `
      -Manifest $Manifest `
      -Evidence $Evidence `
      -RunState $RunState `
      -RepositoryRoot $RepositoryRoot `
      -Phase $Phase `
      -ParentRoute $ParentRoute `
      -Order $recordOrder `
      -Python $python
    $null = $records.Add($record)
    $recordOrder++
  }

  Commit-RkModuleRecords -Records @($records) -RunState $RunState
  $injectedThisCall = @($records | Where-Object { $_.context_injected } | ForEach-Object { $_.content })
  $manifestSha = Get-RkProperty -Object $Manifest -Name 'manifest_sha256'
  $omittedContext = [pscustomobject][ordered]@{
    source_manifest_sha256 = $manifestSha
    module_ids = @()
    bytes = $null
    tokens = $null
    derivation = 'not computed by Phase 2 loader'
    status = 'inconclusive'
  }
  $providerMeasurements = [pscustomobject][ordered]@{
    input_tokens = $null
    cached_input_tokens = $null
    output_tokens = $null
    reasoning_tokens = $null
    total_tokens = $null
    tool_calls = $null
    agent_count = $null
    duration_seconds = $null
  }
  $watch.Stop()
  $decisionDurationMs = [int][math]::Max(0, [math]::Round($watch.Elapsed.TotalMilliseconds))
  $telemetryProjection = Convert-RkTelemetryProjection `
    -Route $Route `
    -KernelMetrics $kernelMetrics `
    -RegistryMetrics $registryMetrics `
    -Records @($records) `
    -RunState $RunState `
    -Manifest $Manifest `
    -DecisionDurationMs $decisionDurationMs
  return [pscustomobject][ordered]@{
    kernel = [pscustomobject][ordered]@{
      loaded = $true
      module_id = 'core.tiny-kernel'
      source_path = 'core/tiny-kernel.md'
      sha256 = if ($null -eq $kernelMetrics) { $null } else { $kernelMetrics.sha256 }
      bytes = if ($null -eq $kernelMetrics) { $null } else { $kernelMetrics.byte_count }
      tokens_build_estimate = if ($null -eq $kernelMetrics) { $null } else { $kernelMetrics.token_count }
    }
    selected_modules = @($records)
    full_bundle_loaded = $false
    context_injected = $injectedThisCall
    load_actions = @($records | ForEach-Object { $_.load_action })
    provenance = [pscustomobject][ordered]@{
      registry_id = Get-RkProperty -Object $Registry -Name 'registry_id'
      manifest_id = Get-RkProperty -Object $Manifest -Name 'manifest_id'
      registry_sha256 = if ($null -eq $registryMetrics) { $null } else { $registryMetrics.sha256 }
      source_manifest_sha256 = $manifestSha
    }
     telemetry = $telemetryProjection
     provider_measurements = $providerMeasurements
   }
}

Export-ModuleMember -Function @(
  'Read-ReasonKitModuleRegistry',
  'New-ReasonKitRunState',
  'Resolve-ReasonKitContext'
)
