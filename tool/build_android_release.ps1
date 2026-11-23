# Release Android App Bundle. Uses admob_defines.json when present.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$defines = Join-Path $root "admob_defines.json"
$args = @("build", "appbundle", "--release")
if (Test-Path $defines) {
  $args += "--dart-define-from-file=$defines"
  Write-Host "Using dart defines from admob_defines.json"
} else {
  Write-Host "No admob_defines.json — release stays ad-free (placeholders)."
  Write-Host "Copy admob_defines.json.example → admob_defines.json and fill real AdMob IDs."
}

& flutter @args
Write-Host "AAB ready under build/app/outputs/bundle/release/"
