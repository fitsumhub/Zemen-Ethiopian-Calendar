# Release Flutter Web build with production football proxy.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$proxy = "https://zemen-football-proxy.aplusethiopia1.workers.dev"
$privacy = "$proxy/privacy-policy.html"

flutter build web --release `
  --dart-define=FOOTBALL_PROXY_BASE=$proxy `
  --dart-define=PRIVACY_POLICY_URL=$privacy
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Web build ready: build/web"
