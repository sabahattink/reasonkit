[CmdletBinding()]
param(
  [switch]$Check
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dist = Join-Path $root 'dist'
$newLine = [string][char]10
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-ReasonKitFile {
  param([string]$RelativePath)

  $path = Join-Path $root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing source file: $RelativePath"
  }
  return [IO.File]::ReadAllText($path)
}

function Normalize-ReasonKitText {
  param([string]$Text)

  $normalized = [Text.RegularExpressions.Regex]::Replace(
    $Text,
    '[ \t]+(\r?\n)',
    '$1'
  )
  return $normalized.TrimEnd([char]13, [char]10) + $newLine
}

function Build-ReasonKitBundle {
  param(
    [string]$BundleName,
    [string[]]$Files
  )

  $parts = [System.Collections.Generic.List[string]]::new()
  $null = $parts.Add('# ReasonKit')
  $null = $parts.Add('')
  $null = $parts.Add('ReasonKit — adaptive reasoning and agent orchestration for efficient AI work.')
  $null = $parts.Add('')
  $null = $parts.Add(('Generated task bundle: ' + $BundleName + '.'))
  $null = $parts.Add('Load this bundle at the host seam; do not load unrelated task protocols by default.')

  foreach ($relativePath in $Files) {
    $null = $parts.Add(('### Source: ' + $relativePath))
    $null = $parts.Add((Read-ReasonKitFile -RelativePath $relativePath))
  }

  return Normalize-ReasonKitText (($parts -join ($newLine + $newLine)))
}

$commonFiles = @(
  'skill/SKILL.md',
  'core/constitution.md',
  'core/task-router.md',
  'core/complexity-governor.md',
  'core/token-governor.md',
  'core/agent-composer.md',
  'core/tool-router.md',
  'core/verification-policy.md',
  'core/stop-policy.md'
)

$bundleDefinitions = @(
  [PSCustomObject]@{
    Name = 'reasonkit-coding.md'
    Files = @($commonFiles + @(
      'protocols/coding.md',
      'agents/investigator.md',
      'agents/implementer.md',
      'agents/verifier.md',
      'agents/adversarial-reviewer.md'
    ))
  },
  [PSCustomObject]@{
    Name = 'reasonkit-debugging.md'
    Files = @($commonFiles + @(
      'protocols/debugging.md',
      'agents/investigator.md',
      'agents/verifier.md',
      'agents/adversarial-reviewer.md',
      'agents/dissent.md'
    ))
  },
  [PSCustomObject]@{
    Name = 'reasonkit-design.md'
    Files = @($commonFiles + @(
      'protocols/design.md',
      'taste/anti-generic.md',
      'taste/visual-reasoning.md',
      'taste/critique.md',
      'agents/art-director.md',
      'agents/design-critic.md',
      'agents/creative-technologist.md',
      'agents/visual-inspector.md',
      'agents/user-journey-tester.md'
    ))
  },
  [PSCustomObject]@{
    Name = 'reasonkit-research.md'
    Files = @($commonFiles + @(
      'protocols/research.md',
      'agents/reference-researcher.md',
      'agents/verifier.md',
      'agents/dissent.md'
    ))
  },
  [PSCustomObject]@{
    Name = 'reasonkit-full.md'
    Files = @($commonFiles + @(
      'core/computer-use-policy.md',
      'protocols/coding.md',
      'protocols/debugging.md',
      'protocols/architecture.md',
      'protocols/research.md',
      'protocols/design.md',
      'protocols/computer-use.md',
      'taste/anti-generic.md',
      'taste/visual-reasoning.md',
      'taste/critique.md',
      'agents/investigator.md',
      'agents/implementer.md',
      'agents/verifier.md',
      'agents/adversarial-reviewer.md',
      'agents/dissent.md',
      'agents/art-director.md',
      'agents/design-critic.md',
      'agents/reference-researcher.md',
      'agents/creative-technologist.md',
      'agents/visual-inspector.md',
      'agents/user-journey-tester.md'
    ))
  }
)

$minText = Normalize-ReasonKitText @'
# ReasonKit — compact adapter

You are one reasoning hub using the ReasonKit operating layer. ReasonKit
improves the process around a model; it does not turn one model into another.

Operating loop:
classify → evidence → bounded specialists only when needed → execute → verify → stop

1. Extract the task, constraints, tools, risk, and acceptance condition.
2. Classify L0-L4. L0 stays inline; L1 uses no specialist and only a compact
   route when useful; L2-L4 use the smallest adequate bounded route.
3. Use direct tools and evidence before more tokens.
4. Keep specialists hub-and-spoke: one question, one evidence slice, one
   return contract. They cannot chat, spawn, or widen scope.
5. Use at most one adversarial review pass.
6. For visual work, render the target artifact and inspect it. Source or build
   success is not visual proof.
7. Follow GREEN, YELLOW, and RED Computer Use gates. RED effects stay under
   explicit human control.
8. Verify independently and stop.

Default ceilings: L0 0 specialists; L1 0; L2 1; L3 3; L4 5.
Normal specialist output is at most 800 tokens; research is at most 1,200 and
architecture at most 1,500. Default total run budgets are L0 1,200, L1 2,500,
L2 6,000, L3 12,000, and L4 20,000 tokens. A 48,000-token run needs explicit
escalation and a recorded reason.

Return: status, evidence, decision, actions, verification, residual unknowns,
and stop reason. Use COMPLETE, PARTIAL, BLOCKED, or UNKNOWN honestly.
'@

$expectedFiles = [ordered]@{
  'reasonkit-min.md' = $minText
}
foreach ($definition in $bundleDefinitions) {
  $bundleText = Build-ReasonKitBundle -BundleName $definition.Name -Files $definition.Files
  $expectedFiles[$definition.Name] = $bundleText
}

if ($Check) {
  $mismatches = @()
  foreach ($fileName in $expectedFiles.Keys) {
    $targetPath = Join-Path $dist $fileName
    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
      $mismatches += $fileName
      continue
    }
    $actual = [IO.File]::ReadAllText($targetPath)
    if ($actual -cne $expectedFiles[$fileName]) {
      $mismatches += $fileName
    }
  }
  if ($mismatches.Count -gt 0) {
    $mismatches | ForEach-Object { Write-Error ('Generated file is stale or missing: ' + $_) }
    throw 'Generated distribution check failed.'
  }
  Write-Output 'dist check passed'
  return
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
foreach ($fileName in $expectedFiles.Keys) {
  $targetPath = Join-Path $dist $fileName
  [IO.File]::WriteAllText($targetPath, $expectedFiles[$fileName], $utf8NoBom)
  Write-Output ('wrote ' + $targetPath)
}
