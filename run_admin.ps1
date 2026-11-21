$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$flutterPath = 'C:\src\flutter\bin\flutter.bat'
$adminUrl = 'http://127.0.0.1:7357'
$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'

if (-not (Test-Path -LiteralPath $flutterPath)) {
    throw "Flutter was not found: $flutterPath"
}
if (Get-NetTCPConnection -LocalPort 7357 -State Listen -ErrorAction SilentlyContinue) {
    Write-Host "Port 7357 is already in use. Open $adminUrl or stop the previous server before restarting."
    exit 1
}

Write-Host "Admin page: $adminUrl"
Write-Host 'Keep this window open while using the admin page. Press q to stop.'

# Open one ordinary browser tab after the server is ready.
$browserJob = Start-Job -ArgumentList $adminUrl, $chromePath -ScriptBlock {
    param($url, $chrome)
    for ($attempt = 0; $attempt -lt 120; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                if (Test-Path -LiteralPath $chrome) {
                    Start-Process -FilePath $chrome -ArgumentList $url -WindowStyle Normal
                } else {
                    Start-Process -FilePath $url
                }
                return
            }
        } catch {
            # The development server is still starting.
        }
        Start-Sleep -Seconds 1
    }
}

try {
    & $flutterPath run -d web-server --web-hostname=127.0.0.1 --web-port=7357 lib/main.dart
} finally {
    Stop-Job -Job $browserJob -ErrorAction SilentlyContinue
    Remove-Job -Job $browserJob -Force -ErrorAction SilentlyContinue
}
