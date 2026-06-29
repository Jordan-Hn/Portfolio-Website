# Regenerates assets/jordan-howson-cv.pdf from index.html.
# The PDF is a generated artifact: run this after editing site content so the
# downloadable CV stays in sync. Requires Python (with the websocket-client
# package) and a Chromium browser (Brave, Chrome, or Edge). Printing goes
# through the DevTools protocol (scripts/cdp-print.py) because the plain
# --print-to-pdf flag hangs on recent Brave builds; this route preserves
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

# Fresh profile so the launch never hands off to an already-running browser.
$profile = Join-Path $env:TEMP ("cv-pdf-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force $profile | Out-Null

$server = Start-Process python -ArgumentList "-m", "http.server", "8765" `
  -WorkingDirectory $root -PassThru -WindowStyle Hidden
$chromium = $null
try {
  Start-Sleep -Seconds 2
  $chromium = Start-Process $browser -ArgumentList ("--headless --disable-gpu --no-proxy-server " +
    "--disable-extensions --remote-debugging-port=9333 --remote-allow-origins=* " +
    "`"--user-data-dir=$profile`" about:blank") -PassThru -WindowStyle Hidden
  Start-Sleep -Seconds 4
  python "$root\scripts\cdp-print.py" 9333 "http://127.0.0.1:8765/" "$root\assets\jordan-howson-cv.pdf"
  if ($LASTEXITCODE -ne 0) { throw "cdp-print.py failed with exit code $LASTEXITCODE" }
  Write-Host "Wrote assets/jordan-howson-cv.pdf"
} finally {
  if ($chromium) { Stop-Process -Id $chromium.Id -Force -ErrorAction SilentlyContinue }
  Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
  Remove-Item -Recurse -Force $profile -ErrorAction SilentlyContinue
}
