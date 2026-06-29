# Regenerates assets/jordan-howson-cv.pdf from index.html.
# The PDF is a generated artifact: run this after editing site content so the
# downloadable CV stays in sync. Requires Python and a Chromium browser
# (Brave, Chrome, or Edge) for its headless print-to-pdf, which preserves
# clickable links and applies the site's @media print styles.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$candidates = @(
  "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
  "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)
$browser = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw "No Chromium browser (Brave, Chrome, or Edge) found." }

$server = Start-Process python -ArgumentList "-m", "http.server", "8765" `
  -WorkingDirectory $root -PassThru -WindowStyle Hidden
try {
  Start-Sleep -Seconds 2
  $args = @(
    "--headless", "--disable-gpu", "--no-pdf-header-footer",
    "--virtual-time-budget=12000",
    "--print-to-pdf=$root\assets\jordan-howson-cv.pdf",
    "http://localhost:8765/"
  )
  & $browser @args
  Write-Host "Wrote assets/jordan-howson-cv.pdf"
} finally {
  Stop-Process -Id $server.Id -Force
}
