[CmdletBinding()]
param(
  [switch]$Check
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dist = Join-Path $root 'dist'
$fullPath = Join-Path $dist 'reasonkit.md'
$minPath = Join-Path $dist 'reasonkit-min.md'
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

$sections = @(
  [PSCustomObject]@{
    Title = 'Skill'
    Files = @('skill/SKILL.md')
  },
  [PSCustomObject]@{
    Title = 'Core policies'
    Files = @(
      'core/constitution.md',
      'core/task-router.md',
      'core/complexity-governor.md',
      'core/token-governor.md',
      'core/agent-composer.md',
      'core/tool-router.md',
      'core/computer-use-policy.md',
      'core/verification-policy.md',
      'core/stop-policy.md'
    )
  },
  [PSCustomObject]@{
    Title = 'Protocols'
    Files = @(
      'protocols/coding.md',
      'protocols/debugging.md',
      'protocols/architecture.md',
      'protocols/research.md',
      'protocols/design.md',
      'protocols/computer-use.md'
    )
  },
  [PSCustomObject]@{
    Title = 'Taste'
    Files = @(
      'taste/anti-generic.md',
      'taste/visual-reasoning.md',
      'taste/critique.md'
    )
  },
  [PSCustomObject]@{
    Title = 'Specialist roles'
    Files = @(
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
    )
  }
)

$fullHeader = @'
# ReasonKit

ReasonKit — adaptive reasoning and agent orchestration for efficient AI work.

This is the generated full distribution bundle. It is assembled from the
source files in skill/, core/, protocols/, taste/, and agents/. Use the
matching adapter instructions when loading it into a host.

Operating loop: classify → evidence → bounded specialists only when needed →
execute → verify → stop.
'@

$parts = [System.Collections.Generic.List[string]]::new()
$null = $parts.Add($fullHeader)
foreach ($section in $sections) {
  $null = $parts.Add(('## ' + $section.Title))
  foreach ($relativePath in $section.Files) {
    $null = $parts.Add((Read-ReasonKitFile -RelativePath $relativePath))
  }
}
$fullText = Normalize-ReasonKitText (($parts -join ($newLine + $newLine)))

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
architecture at most 1,500. The default total run budget is L0 1,200, L1
2,500, L2 6,000, L3 12,000, and L4 20,000 tokens. A 48,000-token run needs
explicit escalation and a recorded reason.

Return: status, evidence, decision, actions, verification, residual unknowns,
and stop reason. Use COMPLETE, PARTIAL, BLOCKED, or UNKNOWN honestly.
'@

if ($Check) {
  $mismatches = @()
  foreach ($target in @(
    [PSCustomObject]@{ Path = $fullPath; Expected = $fullText },
    [PSCustomObject]@{ Path = $minPath; Expected = $minText }
  )) {
    if (-not (Test-Path -LiteralPath $target.Path -PathType Leaf)) {
      $mismatches += $target.Path
      continue
    }
    $actual = [IO.File]::ReadAllText($target.Path)
    if ($actual -cne $target.Expected) {
      $mismatches += $target.Path
    }
  }
  if ($mismatches.Count -gt 0) {
    $mismatches | ForEach-Object { Write-Error "Generated file is stale or missing: $_" }
    throw 'Generated distribution is stale or missing.'
  }
  Write-Output 'dist check passed'
  return
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
[IO.File]::WriteAllText($fullPath, $fullText, $utf8NoBom)
[IO.File]::WriteAllText($minPath, $minText, $utf8NoBom)
Write-Output "wrote $fullPath"
Write-Output "wrote $minPath"
