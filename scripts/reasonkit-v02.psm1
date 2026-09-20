$ErrorActionPreference = 'Stop'

$script:ReasonKitRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:TokenizerPackage = 'tiktoken'
$script:TokenizerVersion = '0.14.0'
$script:TokenizerEncoding = 'cl100k_base'
$script:TokenizerMeasurement = 'build_estimate'
$script:Utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
$script:Utf8Strict = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false, $true)
$script:ExpectedKernelSha256 = 'b23a87ddac73658f7191c5682182d83a379556520e7d08935b064e50b4d7d31a'
$script:SpecialistMax = 3
$script:AdversarialMax = 1
$script:SpecialistReportTokenMax = 512

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

function Get-RkArrayValue {
  param(
    [object]$Object,
    [string]$Name
  )

  $items = [System.Collections.Generic.List[object]]::new()
  $value = Get-RkProperty -Object $Object -Name $Name
  foreach ($item in @($value)) {
    if ($null -ne $item) {
      $null = $items.Add($item)
    }
  }
  return ,$items.ToArray()
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
    specialists_authorized = [System.Collections.Generic.List[object]]::new()
    specialists_started = [System.Collections.Generic.List[object]]::new()
    roles_started = [System.Collections.Generic.List[string]]::new()
    adversarial_authorizations = 0
    adversarial_passes = 0
    prior_decisions = [System.Collections.Generic.List[object]]::new()
  }
}

function Assert-RkRunState {
  param([object]$RunState)

  if ($null -eq $RunState) {
    throw 'Per-run state is required.'
  }
  foreach ($field in @(
    'loaded_by_key', 'loaded_by_module', 'load_records', 'injected_context',
    'next_order', 'request_count', 'specialists_authorized',
    'specialists_started', 'roles_started', 'adversarial_authorizations',
    'adversarial_passes', 'prior_decisions'
  )) {
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

function Get-RkSpecialistStrings {
  param([object]$Value)

  return @(
    foreach ($item in @($Value)) {
      if ($null -eq $item) {
        continue
      }
      $text = ([string]$item).Trim()
      if (-not [string]::IsNullOrWhiteSpace($text)) {
        $text
      }
    }
  )
}

function Get-RkSpecialistSignals {
  param(
    [object]$Request,
    [int]$HypothesisCount,
    [string]$EvidenceState,
    [string]$VerificationState,
    [string]$Risk
  )

  $aliases = @{
    'competing_hypotheses' = 'competing_hypotheses'
    'two_or_more_live_competing_hypotheses' = 'competing_hypotheses'
    'conflicting_evidence' = 'conflicting_evidence'
    'ownership_ambiguity' = 'ownership_ambiguity'
    'unfamiliar_external_domain' = 'unfamiliar_external_domain'
    'high_impact_irreversible' = 'high_impact_irreversible'
    'nondeterministic_verification' = 'nondeterministic_verification'
    'unresolved_creative_direction' = 'unresolved_creative_direction'
    'creative_direction_unresolved' = 'unresolved_creative_direction'
  }
  $ignored = @('uncertainty', 'l3', 'l4', 'complexity', 'more_reasoning', 'general_task_difficulty')
  $signals = [System.Collections.Generic.List[string]]::new()
  foreach ($rawSignal in @(Get-RkSpecialistStrings -Value (Get-RkProperty -Object $Request -Name 'consideration_signals'))) {
    $key = $rawSignal.ToLowerInvariant().Replace(' ', '_').Replace('-', '_')
    if ($ignored -contains $key) {
      continue
    }
    if ($aliases.ContainsKey($key)) {
      $signals.Add($aliases[$key])
    }
  }
  if ($HypothesisCount -ge 2) {
    $signals.Add('competing_hypotheses')
  }
  if ($EvidenceState -eq 'conflicting_unresolved') {
    $signals.Add('conflicting_evidence')
  }
  if ($VerificationState -eq 'nondeterministic') {
    $signals.Add('nondeterministic_verification')
  }
  if ($Risk -in @('high', 'material', 'irreversible')) {
    $signals.Add('high_impact_irreversible')
  }
  return @($signals | Sort-Object -Unique)
}

function Test-RkSpecialistEvidenceResolved {
  param(
    [object]$Request,
    [string]$EvidenceState
  )

  if ([bool](Get-RkProperty -Object $Request -Name 'evidence_resolved')) {
    return $true
  }
  return $EvidenceState -in @(
    'resolved',
    'resolved_by_test',
    'resolved_by_local_verification',
    'resolved_by_authoritative_query',
    'collapsed_by_evidence'
  )
}

function Get-RkSpecialistBudget {
  param(
    [object]$Request,
    [int]$AuthorizedCount,
    [int]$AdversarialPasses,
    [int]$AdversarialAuthorizations
  )

  $requestedBudget = Get-RkProperty -Object $Request -Name 'remaining_budget'
  $requestedSpecialists = Get-RkProperty -Object $requestedBudget -Name 'specialists_remaining'
  $requestedAdversarial = Get-RkProperty -Object $requestedBudget -Name 'adversarial_passes_remaining'
  $specialistsRemaining = if ($null -eq $requestedSpecialists) {
    [Math]::Max(0, $script:SpecialistMax - $AuthorizedCount)
  }
  else {
    [Math]::Max(0, [int]$requestedSpecialists)
  }
  $adversarialRemaining = if ($null -eq $requestedAdversarial) {
    [Math]::Max(0, $script:AdversarialMax - $AdversarialAuthorizations)
  }
  else {
    [Math]::Max(0, [int]$requestedAdversarial)
  }
  return [pscustomobject][ordered]@{
    specialists_remaining = $specialistsRemaining
    adversarial_authorizations_remaining = $adversarialRemaining
  }
}

function Test-ReasonKitSpecialistReport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Report,
    [Parameter(Mandatory = $false)]
    [string]$Python
  )

  if ([string]::IsNullOrWhiteSpace($Python)) {
    $Python = Get-RkPythonExecutable
  }
  $requiredFields = @('role', 'evidence_refs', 'conclusion', 'residual_risk', 'recommended_next_action')
  if ($null -eq $Report) {
    return [pscustomobject][ordered]@{
      accepted = $false
      over_budget = $false
      report_tokens = $null
      report = $null
      telemetry_record = $null
      rejection_reason = 'specialist report is null'
    }
  }
  $properties = @($Report.PSObject.Properties.Name)
  $missing = @($requiredFields | Where-Object { $properties -notcontains $_ })
  $extra = @($properties | Where-Object { $requiredFields -notcontains $_ })
  if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
    $reasonParts = [System.Collections.Generic.List[string]]::new()
    if ($missing.Count -gt 0) {
      $reasonParts.Add('missing=' + ($missing -join ','))
    }
    if ($extra.Count -gt 0) {
      $reasonParts.Add('extra=' + ($extra -join ','))
    }
    return [pscustomobject][ordered]@{
      accepted = $false
      over_budget = $false
      report_tokens = $null
      report = $null
      telemetry_record = $null
      rejection_reason = ($reasonParts -join '; ')
    }
  }

  $evidenceRefs = @(Get-RkSpecialistStrings -Value (Get-RkProperty -Object $Report -Name 'evidence_refs'))
  $normalized = [pscustomobject][ordered]@{
    role = ([string](Get-RkProperty -Object $Report -Name 'role')).Trim()
    evidence_refs = $evidenceRefs
    conclusion = ([string](Get-RkProperty -Object $Report -Name 'conclusion')).Trim()
    residual_risk = ([string](Get-RkProperty -Object $Report -Name 'residual_risk')).Trim()
    recommended_next_action = ([string](Get-RkProperty -Object $Report -Name 'recommended_next_action')).Trim()
  }
  foreach ($field in @('role', 'conclusion', 'residual_risk', 'recommended_next_action')) {
    if ([string]::IsNullOrWhiteSpace((Get-RkProperty -Object $normalized -Name $field))) {
      return [pscustomobject][ordered]@{
        accepted = $false
        over_budget = $false
        report_tokens = $null
        report = $null
        telemetry_record = $null
        rejection_reason = ('specialist report field is empty: ' + $field)
      }
    }
  }
  if ($evidenceRefs.Count -eq 0) {
    return [pscustomobject][ordered]@{
      accepted = $false
      over_budget = $false
      report_tokens = $null
      report = $null
      telemetry_record = $null
      rejection_reason = 'specialist report evidence_refs is empty'
    }
  }

  $serialized = $normalized | ConvertTo-Json -Compress -Depth 20
  $reportTokens = Get-RkTokenizerEstimate -Text $serialized -Python $Python
  $overBudget = $reportTokens -gt $script:SpecialistReportTokenMax
  $reason = if ($overBudget) {
    'specialist report exceeds the provisional build-estimate token target'
  }
  else {
    $null
  }
  return [pscustomobject][ordered]@{
    accepted = -not $overBudget
    over_budget = $overBudget
    report_tokens = $reportTokens
    report = $normalized
    telemetry_record = [pscustomobject][ordered]@{
      role = $normalized.role
      evidence_refs = @($normalized.evidence_refs)
      conclusion = $normalized.conclusion
      residual_risk = $normalized.residual_risk
      recommended_next_action = $normalized.recommended_next_action
      report_tokens = $reportTokens
    }
    rejection_reason = $reason
  }
}

function Decide-ReasonKitSpecialist {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Request,
    [Parameter(Mandatory = $true)]
    [object]$RunState
  )

  $requestProperties = @()
  if ($null -ne $Request -and $null -ne $Request.PSObject) {
    $requestProperties = @($Request.PSObject.Properties.Name | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
  }
  $knownRequestFields = @(
    'consideration_signals', 'hypotheses', 'evidence_state', 'evidence_attempted',
    'evidence_resolved', 'material_uncertainty', 'risk', 'verification_state',
    'selected_complexity', 'caller_role', 'request_kind', 'requested_role',
    'expected_value', 'adversarial_review', 'remaining_budget'
  )
  if ($null -eq $Request -or $requestProperties.Count -eq 0 -or
      @($requestProperties | Where-Object { $knownRequestFields -contains $_ }).Count -eq 0) {
    throw 'Specialist Gate request must be a non-empty structured object.'
  }
  Assert-RkRunState -RunState $RunState

  $hypotheses = @(Get-RkSpecialistStrings -Value (Get-RkProperty -Object $Request -Name 'hypotheses') | Sort-Object -Unique)
  $hypothesisCount = $hypotheses.Count
  $evidenceState = [string](Get-RkProperty -Object $Request -Name 'evidence_state')
  if ([string]::IsNullOrWhiteSpace($evidenceState)) {
    $evidenceState = 'not_attempted'
  }
  $verificationState = [string](Get-RkProperty -Object $Request -Name 'verification_state')
  if ([string]::IsNullOrWhiteSpace($verificationState)) {
    $verificationState = 'unknown'
  }
  $risk = ([string](Get-RkProperty -Object $Request -Name 'risk')).ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($risk)) {
    $risk = 'low'
  }
  $triggers = @(Get-RkSpecialistSignals -Request $Request -HypothesisCount $hypothesisCount -EvidenceState $evidenceState -VerificationState $verificationState -Risk $risk)
  $considered = $triggers.Count -gt 0
  $requestKind = ([string](Get-RkProperty -Object $Request -Name 'request_kind')).ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($requestKind)) {
    $requestKind = 'delegate'
  }
  $callerRole = ([string](Get-RkProperty -Object $Request -Name 'caller_role')).ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($callerRole)) {
    $callerRole = 'hub'
  }
  $requestedRole = ([string](Get-RkProperty -Object $Request -Name 'requested_role')).Trim()
  $expectedValue = Get-RkProperty -Object $Request -Name 'expected_value'
  if ($null -ne $expectedValue) {
    $expectedValue = ([string]$expectedValue).Trim()
  }
  $isAdversarial = [bool](Get-RkProperty -Object $Request -Name 'adversarial_review') -or
    $requestedRole.ToLowerInvariant() -eq 'adversarial-reviewer'
  $authorizedBefore = @($RunState.specialists_authorized).Count
  $adversarialAuthorizationsBefore = [int]$RunState.adversarial_authorizations
  $adversarialBefore = [int]$RunState.adversarial_passes
  $budgetBefore = Get-RkSpecialistBudget `
    -Request $Request `
    -AuthorizedCount $authorizedBefore `
    -AdversarialPasses $adversarialBefore `
    -AdversarialAuthorizations $adversarialAuthorizationsBefore
  $evidenceAttempted = [bool](Get-RkProperty -Object $Request -Name 'evidence_attempted')
  $evidenceResolved = Test-RkSpecialistEvidenceResolved -Request $Request -EvidenceState $evidenceState
  $materialUncertainty = [bool](Get-RkProperty -Object $Request -Name 'material_uncertainty')
  $decision = 'NO_SPAWN'
  $rejectionReason = $null
  $validityEvent = $null
  $authorizedRole = $null
  $authorizedAfter = $authorizedBefore
  $authorizationId = $null
  $adversarialAuthorizationsAfter = $adversarialAuthorizationsBefore
  $adversarialAfter = $adversarialBefore

  if ($callerRole -in @('specialist', 'agent')) {
    $decision = 'REJECTED'
    $rejectionReason = 'specialists cannot invoke or delegate to another specialist'
    $validityEvent = [pscustomobject][ordered]@{ type = 'recursive_specialist_request'; reason = $rejectionReason }
  }
  elseif ($requestKind -in @('specialist_to_specialist', 'peer_conversation', 'vote', 'consensus', 'majority', 'recursive_spawn')) {
    $decision = 'REJECTED'
    $rejectionReason = 'requested specialist interaction is forbidden'
    $validityEvent = [pscustomobject][ordered]@{ type = 'negative_invariant'; reason = $requestKind }
  }
  elseif (-not $considered) {
    if (-not [string]::IsNullOrWhiteSpace($requestedRole)) {
      $decision = 'REJECTED'
      $rejectionReason = 'specialist request lacks a valid consideration signal'
      $validityEvent = [pscustomobject][ordered]@{ type = 'request_without_signal'; reason = $rejectionReason }
    }
    else {
      $rejectionReason = 'no specialist consideration signal'
    }
  }
  elseif ($evidenceResolved) {
    $rejectionReason = 'deterministic evidence resolved uncertainty'
  }
  elseif (-not $materialUncertainty -and $risk -notin @('high', 'material', 'irreversible')) {
    $rejectionReason = 'remaining uncertainty is not material'
  }
  elseif (-not $evidenceAttempted -and $evidenceState -notin @('unavailable', 'inadequate')) {
    $rejectionReason = 'deterministic evidence has not been attempted'
  }
  elseif ([string]::IsNullOrWhiteSpace($requestedRole)) {
    $rejectionReason = 'bounded specialist role is missing'
  }
  elseif ($budgetBefore.specialists_remaining -le 0 -or $authorizedBefore -ge $script:SpecialistMax) {
    $decision = 'REJECTED'
    $rejectionReason = 'specialist cap exceeded'
    $validityEvent = [pscustomobject][ordered]@{ type = 'specialist_cap_exceeded'; reason = $rejectionReason }
  }
  elseif ([string]::IsNullOrWhiteSpace([string]$expectedValue)) {
    $rejectionReason = 'bounded specialist expected value is missing'
  }
  elseif ($isAdversarial -and ($budgetBefore.adversarial_authorizations_remaining -le 0 -or $adversarialAuthorizationsBefore -ge $script:AdversarialMax)) {
    $decision = 'REJECTED'
    $rejectionReason = 'adversarial review cap exceeded'
    $validityEvent = [pscustomobject][ordered]@{ type = 'adversarial_cap_exceeded'; reason = $rejectionReason }
  }
  else {
    $decision = 'AUTHORIZED'
    $authorizedRole = $requestedRole
    $authorizedAfter++
    $authorizationId = 'specialist-' + ($authorizedAfter.ToString())
    $null = $RunState.specialists_authorized.Add([pscustomobject][ordered]@{
      authorization_id = $authorizationId
      role = $requestedRole
      trigger = @($triggers)
      expected_value = $expectedValue
      evidence_state = $evidenceState
      considered = $considered
      competing_hypotheses = $hypothesisCount
      adversarial = $isAdversarial
      started = $false
    })
    if ($isAdversarial) {
      $adversarialAuthorizationsAfter++
      $RunState.adversarial_authorizations = $adversarialAuthorizationsAfter
    }
  }

  $specialistConsumed = if ($decision -eq 'AUTHORIZED') { 1 } else { 0 }
  $adversarialAuthorizationConsumed = if ($decision -eq 'AUTHORIZED' -and $isAdversarial) { 1 } else { 0 }
  $budget = [pscustomobject][ordered]@{
    specialist_cap = $script:SpecialistMax
    adversarial_cap = $script:AdversarialMax
    authorized_count_before = $authorizedBefore
    authorized_count_after = $authorizedAfter
    specialists_remaining_before = $budgetBefore.specialists_remaining
    specialists_remaining_after = [Math]::Max(0, $budgetBefore.specialists_remaining - $specialistConsumed)
    adversarial_authorizations_before = $adversarialAuthorizationsBefore
    adversarial_authorizations_after = $adversarialAuthorizationsAfter
    adversarial_authorizations_remaining_before = $budgetBefore.adversarial_authorizations_remaining
    adversarial_authorizations_remaining_after = [Math]::Max(0, $budgetBefore.adversarial_authorizations_remaining - $adversarialAuthorizationConsumed)
    adversarial_passes_before = $adversarialBefore
    adversarial_passes_after = $adversarialAfter
    adversarial_passes_remaining_before = [Math]::Max(0, $script:AdversarialMax - $adversarialBefore)
    adversarial_passes_remaining_after = [Math]::Max(0, $script:AdversarialMax - $adversarialAfter)
  }
  $schemaGate = [pscustomobject][ordered]@{
    considered = $considered
    started = $false
    trigger = @($triggers)
    evidence_state = $evidenceState
    competing_hypotheses = $hypothesisCount
    rejection_reason = $rejectionReason
    role = $authorizedRole
  }
  $specialistRoles = @($RunState.roles_started)
  $telemetry = [pscustomobject][ordered]@{
    specialist_gate = $schemaGate
    specialist_roles = @($specialistRoles)
    specialist_count = @($RunState.specialists_started).Count
    specialist_reports = @()
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
  $null = $RunState.prior_decisions.Add([pscustomobject][ordered]@{
    decision = $decision
    considered = $considered
    trigger = @($triggers)
    role = $authorizedRole
    authorization_id = $authorizationId
    validity_event = if ($null -eq $validityEvent) { $null } else { $validityEvent.type }
  })
  return [pscustomobject][ordered]@{
    decision = $decision
    considered = $considered
    started = $false
    trigger = @($triggers)
    evidence_state = $evidenceState
    competing_hypotheses = $hypothesisCount
    rejection_reason = $rejectionReason
    role = $authorizedRole
    authorization_id = $authorizationId
    expected_value = $expectedValue
    budget = $budget
    validity_event = $validityEvent
    telemetry = $telemetry
    provider_measurements = $providerMeasurements
  }
}

function New-RkSpecialistLifecycleResult {
  param(
    [string]$Decision,
    [bool]$Started,
    [object]$AuthorizationRecord,
    [string]$AuthorizationId,
    [string]$Role,
    [AllowNull()]
    [object]$RejectionReason,
    [object]$ValidityEvent,
    [object]$RunState
  )

  $considered = if ($null -eq $AuthorizationRecord) { $false } else { [bool](Get-RkProperty -Object $AuthorizationRecord -Name 'considered') }
  $trigger = if ($null -eq $AuthorizationRecord) { @() } else { @(Get-RkProperty -Object $AuthorizationRecord -Name 'trigger') }
  $evidenceState = if ($null -eq $AuthorizationRecord) { 'not_available' } else { [string](Get-RkProperty -Object $AuthorizationRecord -Name 'evidence_state') }
  if ([string]::IsNullOrWhiteSpace($evidenceState)) {
    $evidenceState = 'not_available'
  }
  $hypothesisCount = if ($null -eq $AuthorizationRecord) { 0 } else { [int](Get-RkProperty -Object $AuthorizationRecord -Name 'competing_hypotheses') }
  $expectedValue = if ($null -eq $AuthorizationRecord) { $null } else { Get-RkProperty -Object $AuthorizationRecord -Name 'expected_value' }
  $startedCount = @($RunState.specialists_started).Count
  $startedRoles = @($RunState.roles_started)
  $schemaGate = [pscustomobject][ordered]@{
    considered = $considered
    started = $Started
    trigger = @($trigger)
    evidence_state = $evidenceState
    competing_hypotheses = $hypothesisCount
    rejection_reason = $RejectionReason
    role = if ([string]::IsNullOrWhiteSpace($Role)) { $null } else { $Role }
  }
  $telemetry = [pscustomobject][ordered]@{
    specialist_gate = $schemaGate
    specialist_roles = @($startedRoles)
    specialist_count = $startedCount
    specialist_reports = @()
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
  return [pscustomobject][ordered]@{
    decision = $Decision
    transition = if ($Started) { 'STARTED' } else { 'REJECTED' }
    started = $Started
    authorization_id = if ([string]::IsNullOrWhiteSpace($AuthorizationId)) { $null } else { $AuthorizationId }
    considered = $considered
    trigger = @($trigger)
    evidence_state = $evidenceState
    competing_hypotheses = $hypothesisCount
    rejection_reason = $RejectionReason
    role = if ([string]::IsNullOrWhiteSpace($Role)) { $null } else { $Role }
    expected_value = $expectedValue
    budget = [pscustomobject][ordered]@{
      specialist_cap = $script:SpecialistMax
      started_count = $startedCount
      specialists_remaining = [Math]::Max(0, $script:SpecialistMax - $startedCount)
      authorized_count = @($RunState.specialists_authorized).Count
      adversarial_authorizations = [int]$RunState.adversarial_authorizations
      adversarial_passes = [int]$RunState.adversarial_passes
      adversarial_cap = $script:AdversarialMax
    }
    validity_event = $ValidityEvent
    telemetry = $telemetry
    provider_measurements = $providerMeasurements
  }
}

function Record-ReasonKitSpecialistStart {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Authorization,
    [Parameter(Mandatory = $true)]
    [object]$RunState,
    [Parameter(Mandatory = $false)]
    [string]$Role,
    [Parameter(Mandatory = $false)]
    [string]$CallerRole = 'hub'
  )

  Assert-RkRunState -RunState $RunState
  $authorizationId = ([string](Get-RkProperty -Object $Authorization -Name 'authorization_id')).Trim()
  $authorizationDecision = [string](Get-RkProperty -Object $Authorization -Name 'decision')
  $authorizationRecords = @(
    $RunState.specialists_authorized |
      Where-Object { (Get-RkProperty -Object $_ -Name 'authorization_id') -eq $authorizationId }
  )
  $authorizationRecord = if ($authorizationRecords.Count -eq 1) { $authorizationRecords[0] } else { $null }
  $requestedRole = ([string]$Role).Trim()
  if ([string]::IsNullOrWhiteSpace($requestedRole) -and $null -ne $authorizationRecord) {
    $requestedRole = ([string](Get-RkProperty -Object $authorizationRecord -Name 'role')).Trim()
  }
  $normalizedCallerRole = ([string]$CallerRole).Trim().ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($normalizedCallerRole)) {
    $normalizedCallerRole = 'hub'
  }

  $rejectionReason = $null
  $validityEvent = $null
  if ($normalizedCallerRole -in @('specialist', 'agent')) {
    $rejectionReason = 'specialists cannot start or delegate another specialist'
    $validityEvent = [pscustomobject][ordered]@{ type = 'recursive_specialist_start'; reason = $rejectionReason }
  }
  elseif ([string]::IsNullOrWhiteSpace($authorizationId) -or
      $authorizationDecision -ne 'AUTHORIZED' -or
      $null -eq $authorizationRecord) {
    $rejectionReason = 'specialist start requires an existing valid authorization'
    $validityEvent = [pscustomobject][ordered]@{ type = 'start_without_authorization'; reason = $rejectionReason }
  }
  elseif ($requestedRole -cne ([string](Get-RkProperty -Object $authorizationRecord -Name 'role')).Trim()) {
    $rejectionReason = 'specialist start role does not match the authorization'
    $validityEvent = [pscustomobject][ordered]@{ type = 'specialist_role_mismatch'; reason = $rejectionReason }
  }
  elseif ([bool](Get-RkProperty -Object $authorizationRecord -Name 'started') -or
      @($RunState.specialists_started | Where-Object { (Get-RkProperty -Object $_ -Name 'authorization_id') -eq $authorizationId }).Count -gt 0) {
    $rejectionReason = 'specialist authorization has already been started'
    $validityEvent = [pscustomobject][ordered]@{ type = 'duplicate_specialist_start'; reason = $rejectionReason }
  }
  elseif (@($RunState.specialists_started).Count -ge $script:SpecialistMax) {
    $rejectionReason = 'specialist execution cap exceeded'
    $validityEvent = [pscustomobject][ordered]@{ type = 'specialist_cap_exceeded'; reason = $rejectionReason }
  }
  elseif ([bool](Get-RkProperty -Object $authorizationRecord -Name 'adversarial') -and
      [int]$RunState.adversarial_passes -ge $script:AdversarialMax) {
    $rejectionReason = 'adversarial execution cap exceeded'
    $validityEvent = [pscustomobject][ordered]@{ type = 'adversarial_cap_exceeded'; reason = $rejectionReason }
  }

  if ($null -ne $rejectionReason) {
    $null = $RunState.prior_decisions.Add([pscustomobject][ordered]@{
      decision = 'REJECTED'
      transition = 'REJECTED'
      authorization_id = if ([string]::IsNullOrWhiteSpace($authorizationId)) { $null } else { $authorizationId }
      role = if ([string]::IsNullOrWhiteSpace($requestedRole)) { $null } else { $requestedRole }
      validity_event = $validityEvent.type
    })
    return New-RkSpecialistLifecycleResult `
      -Decision 'REJECTED' `
      -Started $false `
      -AuthorizationRecord $authorizationRecord `
      -AuthorizationId $authorizationId `
      -Role $requestedRole `
      -RejectionReason $rejectionReason `
      -ValidityEvent $validityEvent `
      -RunState $RunState
  }

  $authorizationRecord.started = $true
  $startedRecord = [pscustomobject][ordered]@{
    authorization_id = $authorizationId
    role = $requestedRole
    adversarial = [bool](Get-RkProperty -Object $authorizationRecord -Name 'adversarial')
    started = $true
    order = @($RunState.specialists_started).Count + 1
  }
  $null = $RunState.specialists_started.Add($startedRecord)
  if (@($RunState.roles_started) -notcontains $requestedRole) {
    $null = $RunState.roles_started.Add($requestedRole)
  }
  if ($startedRecord.adversarial) {
    $RunState.adversarial_passes = [int]$RunState.adversarial_passes + 1
  }
  $null = $RunState.prior_decisions.Add([pscustomobject][ordered]@{
    decision = 'STARTED'
    transition = 'STARTED'
    authorization_id = $authorizationId
    role = $requestedRole
    validity_event = $null
  })
  return New-RkSpecialistLifecycleResult `
    -Decision 'STARTED' `
    -Started $true `
    -AuthorizationRecord $authorizationRecord `
    -AuthorizationId $authorizationId `
    -Role $requestedRole `
    -RejectionReason $null `
    -ValidityEvent $null `
    -RunState $RunState
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

function New-RkCandidateFileRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRelativePath,
    [Parameter(Mandatory = $true)]
    [string]$Role,
    [Parameter(Mandatory = $false)]
    [string]$ModuleId
  )

  $resolved = Resolve-RkRepositoryPath `
    -RepositoryRoot $RepositoryRoot `
    -RepositoryRelativePath $RepositoryRelativePath
  if (-not (Test-Path -LiteralPath $resolved.absolute_path -PathType Leaf)) {
    throw ('Candidate covered file is missing: ' + $resolved.relative_path)
  }
  $bytes = [IO.File]::ReadAllBytes($resolved.absolute_path)
  return [ordered]@{
    repository_relative_path = $resolved.relative_path
    sha256 = Get-RkBytesSha256 -Bytes $bytes
    bytes = [int64]$bytes.Length
    role = $Role
    module_id = if ([string]::IsNullOrWhiteSpace($ModuleId)) { $null } else { $ModuleId }
  }
}

function Add-RkCandidateFileRecord {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[object]]$Records,
    [Parameter(Mandatory = $true)]
    [hashtable]$Seen,
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRelativePath,
    [Parameter(Mandatory = $true)]
    [string]$Role,
    [Parameter(Mandatory = $false)]
    [string]$ModuleId
  )

  $canonicalPath = Normalize-RkPath -Path $RepositoryRelativePath
  if ($Seen.ContainsKey($canonicalPath)) {
    throw ('Duplicate candidate covered path: ' + $canonicalPath)
  }
  $Seen[$canonicalPath] = $true
  $null = $Records.Add((New-RkCandidateFileRecord `
    -RepositoryRoot $RepositoryRoot `
    -RepositoryRelativePath $canonicalPath `
    -Role $Role `
    -ModuleId $ModuleId))
}

function Get-RkCandidateCoverage {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,
    [Parameter(Mandatory = $false)]
    [string]$RegistryPath,
    [Parameter(Mandatory = $false)]
    [string[]]$AdapterPaths = @()
  )

  if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
    $RegistryPath = Join-Path $RepositoryRoot 'core/module-registry.json'
  }
  $registry = Read-ReasonKitModuleRegistry -Path $RegistryPath
  $records = [System.Collections.Generic.List[object]]::new()
  $seen = @{}

  Add-RkCandidateFileRecord -Records $records -Seen $seen -RepositoryRoot $RepositoryRoot `
    -RepositoryRelativePath 'core/tiny-kernel.md' -Role 'kernel'
  Add-RkCandidateFileRecord -Records $records -Seen $seen -RepositoryRoot $RepositoryRoot `
    -RepositoryRelativePath 'core/module-registry.json' -Role 'module_registry'

  foreach ($module in @(Get-RkProperty -Object $registry -Name 'modules')) {
    Add-RkCandidateFileRecord -Records $records -Seen $seen -RepositoryRoot $RepositoryRoot `
      -RepositoryRelativePath ([string](Get-RkProperty -Object $module -Name 'source_path')) `
      -Role 'loadable_module' `
      -ModuleId ([string](Get-RkProperty -Object $module -Name 'module_id'))
  }

  foreach ($entry in @(
    [pscustomobject]@{ path = 'core/specialist-gate.md'; role = 'specialist_gate' }
    [pscustomobject]@{ path = 'core/telemetry.schema.json'; role = 'telemetry_schema' }
    [pscustomobject]@{ path = 'core/candidate-manifest.schema.json'; role = 'candidate_schema' }
    [pscustomobject]@{ path = 'scripts/reasonkit-v02.psm1'; role = 'implementation_module' }
    [pscustomobject]@{ path = 'scripts/run-benchmark.ps1'; role = 'runner' }
  )) {
    Add-RkCandidateFileRecord -Records $records -Seen $seen -RepositoryRoot $RepositoryRoot `
      -RepositoryRelativePath $entry.path -Role $entry.role
  }

  $generatedRoot = Join-Path $RepositoryRoot 'dist/v0.2'
  if (-not (Test-Path -LiteralPath $generatedRoot -PathType Container)) {
    throw 'Candidate generated-artifact directory is missing: dist/v0.2'
  }
  $generatedFiles = @(Get-ChildItem -LiteralPath $generatedRoot -Recurse -File | Sort-Object FullName)
  if ($generatedFiles.Count -eq 0) {
    throw 'Candidate coverage requires at least one generated v0.2 artifact.'
  }
  foreach ($file in $generatedFiles) {
    $relative = [IO.Path]::GetRelativePath($RepositoryRoot, $file.FullName).Replace('\', '/')
    Add-RkCandidateFileRecord -Records $records -Seen $seen -RepositoryRoot $RepositoryRoot `
      -RepositoryRelativePath $relative -Role 'generated_artifact'
  }

  foreach ($adapterPath in @($AdapterPaths)) {
    if ([string]::IsNullOrWhiteSpace($adapterPath)) {
      continue
    }
    Add-RkCandidateFileRecord -Records $records -Seen $seen -RepositoryRoot $RepositoryRoot `
      -RepositoryRelativePath $adapterPath -Role 'adapter'
  }

  return @($records.ToArray() | Sort-Object { $_['repository_relative_path'] })
}

function ConvertTo-RkCandidateManifestPayload {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Manifest,
    [Parameter(Mandatory = $false)]
    [bool]$ForDigest = $false
  )

  $coveredFiles = @(
    Get-RkItems -Object $Manifest -Name 'covered_files' |
      ForEach-Object {
        [ordered]@{
          repository_relative_path = Normalize-RkPath -Path ([string](Get-RkProperty -Object $_ -Name 'repository_relative_path'))
          sha256 = ([string](Get-RkProperty -Object $_ -Name 'sha256')).ToLowerInvariant()
          bytes = [int64](Get-RkProperty -Object $_ -Name 'bytes')
          role = [string](Get-RkProperty -Object $_ -Name 'role')
          module_id = Get-RkProperty -Object $_ -Name 'module_id'
        }
      } |
      Sort-Object { $_['repository_relative_path'] }
  )

  $payload = [ordered]@{
    candidate_id = [string](Get-RkProperty -Object $Manifest -Name 'candidate_id')
    candidate_version = [string](Get-RkProperty -Object $Manifest -Name 'candidate_version')
    source_commit = ([string](Get-RkProperty -Object $Manifest -Name 'source_commit')).ToLowerInvariant()
  }
  if (-not $ForDigest) {
    $payload['candidate_manifest_sha256'] = ([string](Get-RkProperty -Object $Manifest -Name 'candidate_manifest_sha256')).ToLowerInvariant()
  }
  $payload['kernel_sha256'] = ([string](Get-RkProperty -Object $Manifest -Name 'kernel_sha256')).ToLowerInvariant()
  $payload['module_manifest_sha256'] = ([string](Get-RkProperty -Object $Manifest -Name 'module_manifest_sha256')).ToLowerInvariant()
  $payload['covered_files'] = @($coveredFiles)
  return $payload
}

function ConvertTo-ReasonKitCanonicalCandidateManifestJson {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Manifest,
    [Parameter(Mandatory = $false)]
    [switch]$ForDigest
  )

  $payload = ConvertTo-RkCandidateManifestPayload -Manifest $Manifest -ForDigest $ForDigest.IsPresent
  return (($payload | ConvertTo-Json -Compress -Depth 50) + [string][char]10)
}

function Get-ReasonKitCandidateManifestHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Manifest
  )

  $canonical = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $Manifest -ForDigest
  return Get-RkBytesSha256 -Bytes $script:Utf8NoBom.GetBytes($canonical)
}

function New-ReasonKitCandidateManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$CandidateId,
    [Parameter(Mandatory = $true)]
    [string]$CandidateVersion,
    [Parameter(Mandatory = $true)]
    [string]$SourceCommit,
    [Parameter(Mandatory = $false)]
    [string]$RepositoryRoot = $script:ReasonKitRoot,
    [Parameter(Mandatory = $false)]
    [string[]]$AdapterPaths = @()
  )

  if ($CandidateId -notmatch '^rk2-[a-z0-9][a-z0-9.-]*$') {
    throw 'Candidate ID is not canonical.'
  }
  if ([string]::IsNullOrWhiteSpace($CandidateVersion)) {
    throw 'Candidate version is empty.'
  }
  if ($SourceCommit -notmatch '^[0-9a-fA-F]{40}$') {
    throw 'Candidate source commit is not a 40-character Git SHA.'
  }

  $coveredFiles = @(Get-RkCandidateCoverage -RepositoryRoot $RepositoryRoot -AdapterPaths $AdapterPaths)
  $kernelRecord = @($coveredFiles | Where-Object { $_.repository_relative_path -eq 'core/tiny-kernel.md' }) | Select-Object -First 1
  $registryRecord = @($coveredFiles | Where-Object { $_.repository_relative_path -eq 'core/module-registry.json' }) | Select-Object -First 1
  if ($null -eq $kernelRecord -or $null -eq $registryRecord) {
    throw 'Candidate coverage is missing the kernel or module registry.'
  }

  $manifest = [pscustomobject][ordered]@{
    candidate_id = $CandidateId
    candidate_version = $CandidateVersion
    source_commit = $SourceCommit.ToLowerInvariant()
    candidate_manifest_sha256 = $null
    kernel_sha256 = $kernelRecord.sha256
    module_manifest_sha256 = $registryRecord.sha256
    covered_files = @($coveredFiles)
  }
  $manifest.candidate_manifest_sha256 = Get-ReasonKitCandidateManifestHash -Manifest $manifest
  return $manifest
}

function Assert-ReasonKitCandidateManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Manifest,
    [Parameter(Mandatory = $false)]
    [string]$RepositoryRoot = $script:ReasonKitRoot,
    [Parameter(Mandatory = $false)]
    [string]$ExpectedSourceCommit,
    [Parameter(Mandatory = $false)]
    [string]$SchemaPath,
    [Parameter(Mandatory = $false)]
    [string]$ManifestText
  )

  foreach ($field in @('candidate_id', 'candidate_version', 'source_commit', 'candidate_manifest_sha256', 'kernel_sha256', 'module_manifest_sha256', 'covered_files')) {
    if ($null -eq $Manifest.PSObject.Properties[$field]) {
      throw ('Candidate manifest field is missing: ' + $field)
    }
  }
  if ([string]$Manifest.candidate_id -notmatch '^rk2-[a-z0-9][a-z0-9.-]*$') {
    throw 'Candidate manifest candidate_id is invalid.'
  }
  if ([string]::IsNullOrWhiteSpace([string]$Manifest.candidate_version)) {
    throw 'Candidate manifest candidate_version is empty.'
  }
  $sourceCommit = ([string]$Manifest.source_commit).ToLowerInvariant()
  if ($sourceCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'Candidate manifest source_commit is invalid.'
  }
  if ([string]$Manifest.source_commit -cne $sourceCommit) {
    throw 'Candidate manifest source_commit must be lowercase.'
  }
  if (-not [string]::IsNullOrWhiteSpace($ExpectedSourceCommit) -and
      $sourceCommit -cne $ExpectedSourceCommit.ToLowerInvariant()) {
    throw 'Candidate manifest source_commit does not match the checkout.'
  }
  $gitCommand = Get-Command git -ErrorAction SilentlyContinue
  if ($null -eq $gitCommand) {
    throw 'Cannot resolve candidate source_commit because git is unavailable.'
  }
  $global:LASTEXITCODE = 0
  $null = @(& $gitCommand.Source -C $RepositoryRoot cat-file -e ($sourceCommit + '^{commit}') 2>$null)
  $gitExitCode = $LASTEXITCODE
  $global:LASTEXITCODE = 0
  if ($gitExitCode -ne 0) {
    throw 'Candidate manifest source_commit does not resolve to a commit in the repository.'
  }

  $covered = @(Get-RkItems -Object $Manifest -Name 'covered_files')
  if ($covered.Count -eq 0) {
    throw 'Candidate manifest has no covered files.'
  }
  $seen = @{}
  $paths = [System.Collections.Generic.List[string]]::new()
  foreach ($entry in $covered) {
    $declaredPath = [string](Get-RkProperty -Object $entry -Name 'repository_relative_path')
    $path = Normalize-RkPath -Path $declaredPath
    if ($declaredPath -cne $path) {
      throw ('Candidate covered path is not canonical: ' + $declaredPath)
    }
    if ($seen.ContainsKey($path)) {
      throw ('Duplicate candidate covered path: ' + $path)
    }
    $seen[$path] = $true
    $null = $paths.Add($path)
    $sha = ([string](Get-RkProperty -Object $entry -Name 'sha256'))
    if ($sha -notmatch '^[0-9a-f]{64}$') {
      throw ('Candidate covered SHA-256 must be lowercase: ' + $path)
    }
    $bytesValue = Get-RkProperty -Object $entry -Name 'bytes'
    if ($null -eq $bytesValue -or [int64]$bytesValue -lt 0) {
      throw ('Candidate covered byte count is invalid: ' + $path)
    }
    $role = [string](Get-RkProperty -Object $entry -Name 'role')
    if (@('kernel', 'module_registry', 'loadable_module', 'specialist_gate', 'telemetry_schema', 'candidate_schema', 'runner', 'implementation_module', 'adapter', 'generated_artifact', 'other') -notcontains $role) {
      throw ('Candidate covered role is invalid: ' + $path)
    }
    $resolved = Resolve-RkRepositoryPath -RepositoryRoot $RepositoryRoot -RepositoryRelativePath $path
    if (-not (Test-Path -LiteralPath $resolved.absolute_path -PathType Leaf)) {
      throw ('Candidate covered file is missing: ' + $path)
    }
    $actualBytes = [IO.File]::ReadAllBytes($resolved.absolute_path)
    $actualSha = Get-RkBytesSha256 -Bytes $actualBytes
    if ([int64]$bytesValue -ne [int64]$actualBytes.Length) {
      throw ('Candidate covered byte count mismatch: ' + $path)
    }
    if ($sha -cne $actualSha) {
      throw ('Candidate covered SHA-256 mismatch: ' + $path)
    }
  }
  $sortedPaths = @($paths | Sort-Object)
  if (($paths -join [string][char]10) -cne ($sortedPaths -join [string][char]10)) {
    throw 'Candidate covered files are not in lexicographic path order.'
  }

  $requiredRecords = @(Get-RkCandidateCoverage -RepositoryRoot $RepositoryRoot)
  foreach ($required in $requiredRecords) {
    if (-not $seen.ContainsKey($required.repository_relative_path)) {
      throw ('Candidate coverage is missing: ' + $required.repository_relative_path)
    }
  }
  $kernelActual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $RepositoryRoot 'core/tiny-kernel.md')).Hash.ToLowerInvariant()
  $registryActual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $RepositoryRoot 'core/module-registry.json')).Hash.ToLowerInvariant()
  if ([string]$Manifest.kernel_sha256 -cne $kernelActual) {
    throw 'Candidate kernel_sha256 does not match the current kernel.'
  }
  if ([string]$Manifest.module_manifest_sha256 -cne $registryActual) {
    throw 'Candidate module_manifest_sha256 does not match the current registry.'
  }
  $computedManifestHash = Get-ReasonKitCandidateManifestHash -Manifest $Manifest
  if ([string]$Manifest.candidate_manifest_sha256 -cne $computedManifestHash) {
    throw 'Candidate manifest hash mismatch.'
  }

  $canonicalJson = ConvertTo-ReasonKitCanonicalCandidateManifestJson -Manifest $Manifest
  if ($PSBoundParameters.ContainsKey('ManifestText') -and $ManifestText -cne $canonicalJson) {
    throw 'Candidate manifest bytes are not canonical UTF-8 JSON with one final LF.'
  }
  if ([string]::IsNullOrWhiteSpace($SchemaPath)) {
    $SchemaPath = Join-Path $RepositoryRoot 'core/candidate-manifest.schema.json'
  }
  if (Test-Path -LiteralPath $SchemaPath -PathType Leaf) {
    $schemaValid = Test-Json -Json $canonicalJson -SchemaFile $SchemaPath -ErrorAction Stop
    if ($schemaValid -ne $true) {
      throw 'Candidate manifest does not satisfy the frozen schema.'
    }
  }
  return $Manifest
}

function ConvertTo-RkTelemetryContext {
  param([object]$Context)

  $source = $Context
  if ($null -ne $source -and $null -ne $source.PSObject.Properties['telemetry']) {
    $source = $source.telemetry
  }
  $fullBundle = Get-RkProperty -Object $source -Name 'full_bundle'
  $omitted = Get-RkProperty -Object $source -Name 'omitted_context'
  return [ordered]@{
    kernel_bytes = Get-RkProperty -Object $source -Name 'kernel_bytes'
    kernel_tokens = Get-RkProperty -Object $source -Name 'kernel_tokens'
    loader_index_bytes = Get-RkProperty -Object $source -Name 'loader_index_bytes'
    loader_index_tokens = Get-RkProperty -Object $source -Name 'loader_index_tokens'
    loader_request_count = if ($null -eq (Get-RkProperty -Object $source -Name 'loader_request_count')) { 0 } else { [int](Get-RkProperty -Object $source -Name 'loader_request_count') }
    loader_decision_duration_ms = Get-RkProperty -Object $source -Name 'loader_decision_duration_ms'
    route = Get-RkProperty -Object $source -Name 'route'
    selected_complexity = Get-RkProperty -Object $source -Name 'selected_complexity'
    modules_loaded = Get-RkArrayValue -Object $source -Name 'modules_loaded'
    omitted_context = [ordered]@{
      source_manifest_sha256 = Get-RkProperty -Object $omitted -Name 'source_manifest_sha256'
      module_ids = Get-RkArrayValue -Object $omitted -Name 'module_ids'
      bytes = Get-RkProperty -Object $omitted -Name 'bytes'
      tokens = Get-RkProperty -Object $omitted -Name 'tokens'
      derivation = if ($null -eq (Get-RkProperty -Object $omitted -Name 'derivation')) { 'not available' } else { Get-RkProperty -Object $omitted -Name 'derivation' }
      status = if ($null -eq (Get-RkProperty -Object $omitted -Name 'status')) { 'unavailable' } else { Get-RkProperty -Object $omitted -Name 'status' }
    }
    full_bundle = [ordered]@{
      loaded = if ($null -eq (Get-RkProperty -Object $fullBundle -Name 'loaded')) { $false } else { [bool](Get-RkProperty -Object $fullBundle -Name 'loaded') }
      escalation_reason = Get-RkProperty -Object $fullBundle -Name 'escalation_reason'
      requested_by = Get-RkProperty -Object $fullBundle -Name 'requested_by'
      approved_by_or_gate = Get-RkProperty -Object $fullBundle -Name 'approved_by_or_gate'
      source_hash = Get-RkProperty -Object $fullBundle -Name 'source_hash'
      loaded_bytes = Get-RkProperty -Object $fullBundle -Name 'loaded_bytes'
      loaded_tokens_if_deterministic = Get-RkProperty -Object $fullBundle -Name 'loaded_tokens_if_deterministic'
    }
    instruction_bytes = Get-RkProperty -Object $source -Name 'instruction_bytes'
  }
}

function ConvertTo-RkTelemetrySpecialists {
  param([object]$Specialists)

  $source = $Specialists
  if ($null -ne $source -and $null -ne $source.PSObject.Properties['telemetry']) {
    $source = $source.telemetry
  }
  $gate = Get-RkProperty -Object $source -Name 'specialist_gate'
  return [ordered]@{
    specialist_gate = [ordered]@{
      considered = if ($null -eq (Get-RkProperty -Object $gate -Name 'considered')) { $false } else { [bool](Get-RkProperty -Object $gate -Name 'considered') }
      started = if ($null -eq (Get-RkProperty -Object $gate -Name 'started')) { $false } else { [bool](Get-RkProperty -Object $gate -Name 'started') }
      trigger = Get-RkArrayValue -Object $gate -Name 'trigger'
      evidence_state = if ($null -eq (Get-RkProperty -Object $gate -Name 'evidence_state')) { 'not_considered' } else { Get-RkProperty -Object $gate -Name 'evidence_state' }
      competing_hypotheses = if ($null -eq (Get-RkProperty -Object $gate -Name 'competing_hypotheses')) { 0 } else { [int](Get-RkProperty -Object $gate -Name 'competing_hypotheses') }
      rejection_reason = Get-RkProperty -Object $gate -Name 'rejection_reason'
      role = Get-RkProperty -Object $gate -Name 'role'
    }
    specialist_roles = Get-RkArrayValue -Object $source -Name 'specialist_roles'
    specialist_count = if ($null -eq (Get-RkProperty -Object $source -Name 'specialist_count')) { 0 } else { [int](Get-RkProperty -Object $source -Name 'specialist_count') }
    specialist_reports = Get-RkArrayValue -Object $source -Name 'specialist_reports'
  }
}

function ConvertTo-RkTelemetryOutcome {
  param([object]$Outcome)

  $source = $Outcome
  if ($null -ne $source -and $null -ne $source.PSObject.Properties['outcome']) {
    $source = $source.outcome
  }
  $verification = Get-RkProperty -Object $source -Name 'verification'
  $stop = Get-RkProperty -Object $source -Name 'stop'
  return [ordered]@{
    verification = [ordered]@{
      result = if ($null -eq (Get-RkProperty -Object $verification -Name 'result')) { 'NOT_RUN' } else { Get-RkProperty -Object $verification -Name 'result' }
      evidence = Get-RkArrayValue -Object $verification -Name 'evidence'
    }
    stop = [ordered]@{
      decision = if ($null -eq (Get-RkProperty -Object $stop -Name 'decision')) { 'CONTINUE' } else { Get-RkProperty -Object $stop -Name 'decision' }
      reason = if ([string]::IsNullOrWhiteSpace([string](Get-RkProperty -Object $stop -Name 'reason'))) { 'awaiting host evidence' } else { Get-RkProperty -Object $stop -Name 'reason' }
    }
    provider_status = if ($null -eq (Get-RkProperty -Object $source -Name 'provider_status')) { 'UNKNOWN' } else { Get-RkProperty -Object $source -Name 'provider_status' }
    model_completion_status = if ($null -eq (Get-RkProperty -Object $source -Name 'model_completion_status')) { 'NOT_STARTED' } else { Get-RkProperty -Object $source -Name 'model_completion_status' }
    task_success = Get-RkProperty -Object $source -Name 'task_success'
    scope_violation = Get-RkProperty -Object $source -Name 'scope_violation'
    evaluator_validity = if ($null -eq (Get-RkProperty -Object $source -Name 'evaluator_validity')) { 'UNKNOWN' } else { Get-RkProperty -Object $source -Name 'evaluator_validity' }
    changed_files = Get-RkArrayValue -Object $source -Name 'changed_files'
    tests_weakened = Get-RkProperty -Object $source -Name 'tests_weakened'
    dependencies_changed = Get-RkProperty -Object $source -Name 'dependencies_changed'
    failure_class = Get-RkProperty -Object $source -Name 'failure_class'
  }
}

function ConvertTo-RkTelemetryProviderMeasurements {
  param([object]$ProviderMeasurements)

  $source = $ProviderMeasurements
  if ($null -ne $source -and $null -ne $source.PSObject.Properties['provider_measurements']) {
    $source = $source.provider_measurements
  }
  return [ordered]@{
    input_tokens = Get-RkProperty -Object $source -Name 'input_tokens'
    cached_input_tokens = Get-RkProperty -Object $source -Name 'cached_input_tokens'
    output_tokens = Get-RkProperty -Object $source -Name 'output_tokens'
    reasoning_tokens = Get-RkProperty -Object $source -Name 'reasoning_tokens'
    total_tokens = Get-RkProperty -Object $source -Name 'total_tokens'
    tool_calls = Get-RkProperty -Object $source -Name 'tool_calls'
    agent_count = Get-RkProperty -Object $source -Name 'agent_count'
    duration_seconds = Get-RkProperty -Object $source -Name 'duration_seconds'
  }
}

function ConvertTo-RkTelemetryIntegrity {
  param([object]$Integrity)

  $source = $Integrity
  return [ordered]@{
    source_dirty = Get-RkProperty -Object $source -Name 'source_dirty'
    raw_packet_sha256 = Get-RkProperty -Object $source -Name 'raw_packet_sha256'
    telemetry_sha256 = Get-RkProperty -Object $source -Name 'telemetry_sha256'
    historical_materials_unchanged = Get-RkProperty -Object $source -Name 'historical_materials_unchanged'
    integrity_status = if ($null -eq (Get-RkProperty -Object $source -Name 'integrity_status')) { 'UNVERIFIED' } else { Get-RkProperty -Object $source -Name 'integrity_status' }
  }
}

function New-ReasonKitTelemetryRecord {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$RunId,
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    [Parameter(Mandatory = $true)]
    [ValidateSet('A', 'B', 'C', 'D')]
    [string]$Arm,
    [Parameter(Mandatory = $false)]
    [object]$CandidateManifest,
    [string]$SourceTag,
    [string]$SourceCommit,
    [string]$TaskHash,
    [string]$FixtureHash,
    [string]$HostFingerprint,
    [string]$KernelId,
    [string]$KernelSha256,
    [string]$ModuleManifestSha256,
    [string]$RunnerSha256,
    [string]$AdapterSha256,
    [object]$Context,
    [object]$Specialists,
    [object]$Outcome,
    [object]$ProviderMeasurements,
    [object]$Integrity
  )

  $candidateId = Get-RkProperty -Object $CandidateManifest -Name 'candidate_id'
  $candidateVersion = Get-RkProperty -Object $CandidateManifest -Name 'candidate_version'
  $candidateManifestSha = Get-RkProperty -Object $CandidateManifest -Name 'candidate_manifest_sha256'
  if ([string]::IsNullOrWhiteSpace($SourceCommit)) {
    $SourceCommit = Get-RkProperty -Object $CandidateManifest -Name 'source_commit'
  }
  if ([string]::IsNullOrWhiteSpace($KernelSha256)) {
    $KernelSha256 = Get-RkProperty -Object $CandidateManifest -Name 'kernel_sha256'
  }
  if ([string]::IsNullOrWhiteSpace($ModuleManifestSha256)) {
    $ModuleManifestSha256 = Get-RkProperty -Object $CandidateManifest -Name 'module_manifest_sha256'
  }

  $document = [pscustomobject][ordered]@{
    schema_version = '0.2'
    identity = [ordered]@{
      run_id = $RunId
      task_id = $TaskId
      arm = $Arm
      candidate_id = if ([string]::IsNullOrWhiteSpace([string]$candidateId)) { $null } else { $candidateId }
      candidate_version = if ([string]::IsNullOrWhiteSpace([string]$candidateVersion)) { $null } else { $candidateVersion }
      candidate_manifest_sha256 = if ([string]::IsNullOrWhiteSpace([string]$candidateManifestSha)) { $null } else { ([string]$candidateManifestSha).ToLowerInvariant() }
      telemetry_schema_version = '0.2'
    }
    provenance = [ordered]@{
      source_tag = if ([string]::IsNullOrWhiteSpace($SourceTag)) { $null } else { $SourceTag }
      source_commit = if ([string]::IsNullOrWhiteSpace($SourceCommit)) { $null } else { $SourceCommit.ToLowerInvariant() }
      task_hash = if ([string]::IsNullOrWhiteSpace($TaskHash)) { $null } else { $TaskHash.ToLowerInvariant() }
      fixture_hash = if ([string]::IsNullOrWhiteSpace($FixtureHash)) { $null } else { $FixtureHash.ToLowerInvariant() }
      host_fingerprint = if ([string]::IsNullOrWhiteSpace($HostFingerprint)) { $null } else { $HostFingerprint }
      kernel_id = if ([string]::IsNullOrWhiteSpace($KernelId)) { $null } else { $KernelId }
      kernel_sha256 = if ([string]::IsNullOrWhiteSpace($KernelSha256)) { $null } else { $KernelSha256.ToLowerInvariant() }
      module_manifest_sha256 = if ([string]::IsNullOrWhiteSpace($ModuleManifestSha256)) { $null } else { $ModuleManifestSha256.ToLowerInvariant() }
      runner_sha256 = if ([string]::IsNullOrWhiteSpace($RunnerSha256)) { $null } else { $RunnerSha256.ToLowerInvariant() }
      adapter_sha256 = if ([string]::IsNullOrWhiteSpace($AdapterSha256)) { $null } else { $AdapterSha256.ToLowerInvariant() }
    }
    context = ConvertTo-RkTelemetryContext -Context $Context
    specialists = ConvertTo-RkTelemetrySpecialists -Specialists $Specialists
    outcome = ConvertTo-RkTelemetryOutcome -Outcome $Outcome
    provider_measurements = ConvertTo-RkTelemetryProviderMeasurements -ProviderMeasurements $ProviderMeasurements
    integrity = ConvertTo-RkTelemetryIntegrity -Integrity $Integrity
  }
  $null = Assert-ReasonKitTelemetryRecord -Document $document
  return $document
}

function Assert-ReasonKitTelemetryRecord {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Document,
    [Parameter(Mandatory = $false)]
    [string]$SchemaPath
  )

  foreach ($group in @('identity', 'provenance', 'context', 'specialists', 'outcome', 'provider_measurements', 'integrity')) {
    if ($null -eq $Document.PSObject.Properties[$group]) {
      throw ('Telemetry group is missing: ' + $group)
    }
  }
  $identity = Get-RkProperty -Object $Document -Name 'identity'
  $candidateFields = @(
    Get-RkProperty -Object $identity -Name 'candidate_id'
    Get-RkProperty -Object $identity -Name 'candidate_version'
    Get-RkProperty -Object $identity -Name 'candidate_manifest_sha256'
  )
  $candidatePresent = -not [string]::IsNullOrWhiteSpace([string]$candidateFields[0])
  if ($candidatePresent -and ($candidateFields | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
    throw 'Candidate telemetry identity is incomplete.'
  }
  if (-not $candidatePresent -and ($candidateFields | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
    throw 'Candidate telemetry identity contains a partial binding.'
  }

  $outcome = Get-RkProperty -Object $Document -Name 'outcome'
  $failureClass = Get-RkProperty -Object $outcome -Name 'failure_class'
  if (@($null, 'MODEL_FAIL', 'EVALUATOR_INVALID', 'PROVIDER_ABORTED') -notcontains $failureClass) {
    throw ('Unknown telemetry failure class: ' + $failureClass)
  }
  if ($failureClass -eq 'PROVIDER_ABORTED' -and (Get-RkProperty -Object $outcome -Name 'provider_status') -ne 'ABORTED') {
    throw 'PROVIDER_ABORTED requires provider_status=ABORTED.'
  }
  if ($failureClass -eq 'MODEL_FAIL' -and (Get-RkProperty -Object $outcome -Name 'task_success') -ne $false) {
    throw 'MODEL_FAIL requires task_success=false.'
  }
  if ($failureClass -eq 'EVALUATOR_INVALID' -and (Get-RkProperty -Object $outcome -Name 'evaluator_validity') -ne 'INVALID') {
    throw 'EVALUATOR_INVALID requires evaluator_validity=INVALID.'
  }
  $specialists = Get-RkProperty -Object $Document -Name 'specialists'
  if ([int](Get-RkProperty -Object $specialists -Name 'specialist_count') -gt $script:SpecialistMax -or
      @(Get-RkProperty -Object $specialists -Name 'specialist_reports').Count -gt $script:SpecialistMax) {
    throw 'Telemetry specialist cap exceeded.'
  }

  if ([string]::IsNullOrWhiteSpace($SchemaPath)) {
    $SchemaPath = Join-Path $script:ReasonKitRoot 'core/telemetry.schema.json'
  }
  if (Test-Path -LiteralPath $SchemaPath -PathType Leaf) {
    $json = $Document | ConvertTo-Json -Depth 80 -Compress
    $valid = Test-Json -Json $json -SchemaFile $SchemaPath -ErrorAction Stop
    if ($valid -ne $true) {
      throw 'Telemetry record does not satisfy the frozen schema.'
    }
  }
  return $Document
}

function Update-ReasonKitTelemetryRecord {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [object]$Document,
    [Parameter(Mandatory = $false)]
    [object]$Context,
    [Parameter(Mandatory = $false)]
    [object]$Specialists,
    [Parameter(Mandatory = $false)]
    [object]$Outcome,
    [Parameter(Mandatory = $false)]
    [object]$ProviderMeasurements,
    [Parameter(Mandatory = $false)]
    [object]$Integrity
  )

  $updated = ($Document | ConvertTo-Json -Depth 80) | ConvertFrom-Json -Depth 80
  if ($PSBoundParameters.ContainsKey('Context')) {
    $updated.context = ConvertTo-RkTelemetryContext -Context $Context
  }
  if ($PSBoundParameters.ContainsKey('Specialists')) {
    $updated.specialists = ConvertTo-RkTelemetrySpecialists -Specialists $Specialists
  }
  if ($PSBoundParameters.ContainsKey('Outcome')) {
    $updated.outcome = ConvertTo-RkTelemetryOutcome -Outcome $Outcome
  }
  if ($PSBoundParameters.ContainsKey('ProviderMeasurements')) {
    $updated.provider_measurements = ConvertTo-RkTelemetryProviderMeasurements -ProviderMeasurements $ProviderMeasurements
  }
  if ($PSBoundParameters.ContainsKey('Integrity')) {
    $updated.integrity = ConvertTo-RkTelemetryIntegrity -Integrity $Integrity
  }
  $null = Assert-ReasonKitTelemetryRecord -Document $updated
  return $updated
}

Export-ModuleMember -Function @(
  'Read-ReasonKitModuleRegistry',
  'New-ReasonKitRunState',
  'Resolve-ReasonKitContext',
  'Decide-ReasonKitSpecialist',
  'Record-ReasonKitSpecialistStart',
  'Test-ReasonKitSpecialistReport',
  'ConvertTo-ReasonKitCanonicalCandidateManifestJson',
  'Get-ReasonKitCandidateManifestHash',
  'New-ReasonKitCandidateManifest',
  'Assert-ReasonKitCandidateManifest',
  'New-ReasonKitTelemetryRecord',
  'Assert-ReasonKitTelemetryRecord',
  'Update-ReasonKitTelemetryRecord'
)
