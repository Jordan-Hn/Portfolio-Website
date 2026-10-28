# Regenerates assets/jordan-howson-cv.pdf from index.html.
# The PDF is a generated artifact: run this after editing site content so the
# downloadable CV stays in sync. Requires Python (with the websocket-client
# package) and a Chromium browser (Brave, Chrome, or Edge). Printing goes
# through the DevTools protocol (scripts/cdp-print.py) because the plain
# --print-to-pdf flag hangs on recent Brave builds; this route preserves
# clickable links and applies the site's @media print styles.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Get-AvailablePort {
  $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $listener.Start()
  try { return $listener.LocalEndpoint.Port } finally { $listener.Stop() }
}
$httpPort = Get-AvailablePort
$debugPort = Get-AvailablePort
while ($debugPort -eq $httpPort) { $debugPort = Get-AvailablePort }

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

$server = Start-Process python -ArgumentList "-m", "http.server", "$httpPort", "--bind", "127.0.0.1" `
  -WorkingDirectory $root -PassThru -WindowStyle Hidden
$chromium = $null
try {
  Start-Sleep -Seconds 2
  if ($server.HasExited) { throw "The portfolio preview server failed to start." }
  $chromium = Start-Process $browser -ArgumentList ("--headless --disable-gpu --no-proxy-server " +
    "--disable-extensions --remote-debugging-port=$debugPort --remote-allow-origins=* " +
    "`"--user-data-dir=$profile`" about:blank") -PassThru -WindowStyle Hidden
  Start-Sleep -Seconds 4
  python "$root\scripts\cdp-print.py" $debugPort "http://127.0.0.1:$httpPort/" "$root\assets\jordan-howson-cv.pdf"
  if ($LASTEXITCODE -ne 0) { throw "cdp-print.py failed with exit code $LASTEXITCODE" }
  Write-Host "Wrote assets/jordan-howson-cv.pdf"
} finally {
  if ($chromium) { Stop-Process -Id $chromium.Id -Force -ErrorAction SilentlyContinue }
  Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
  $resolvedProfile = [System.IO.Path]::GetFullPath($profile)
  $tempRoot = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
  if (-not $resolvedProfile.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
      [System.IO.Path]::GetFileName($resolvedProfile) -notlike 'cv-pdf-*') {
    throw "Refusing to remove an unexpected browser profile path: $resolvedProfile"
  }
  Remove-Item -LiteralPath $resolvedProfile -Recurse -Force -ErrorAction SilentlyContinue
}
