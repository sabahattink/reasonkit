param(
  [string]$PackageRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
$fixtureRoot = Join-Path $resolvedRoot 'fixture-public'
$hiddenCheck = Join-Path $resolvedRoot 'evaluator-only/hidden-concurrency-regression.js'

Push-Location $fixtureRoot
try {
  & npm.cmd test
  if ($LASTEXITCODE -ne 0) { throw "public test suite failed with exit code $LASTEXITCODE" }

  & node $hiddenCheck $resolvedRoot public
  $preFixExit = $LASTEXITCODE
  if ($preFixExit -eq 0) { throw 'held-out regression unexpectedly passed before the reference fix' }

  & node $hiddenCheck $resolvedRoot reference
  if ($LASTEXITCODE -ne 0) { throw "reference implementation failed with exit code $LASTEXITCODE" }

  [pscustomobject]@{
    public_tests = 'PASS'
    held_out_pre_fix = 'EXPECTED_FAIL'
    reference_fix = 'PASS'
    package_root = $resolvedRoot
  } | ConvertTo-Json
}
finally {
  Pop-Location
}
