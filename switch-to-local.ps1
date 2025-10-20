# PowerShell script to switch mobile app to local development
Write-Host "Switching mobile app to local development..." -ForegroundColor Green

$apiConfigFile = "lib/config/api_config.dart"

if (Test-Path $apiConfigFile) {
    $content = Get-Content $apiConfigFile -Raw
    
    # Update production flag to false
    $content = $content -replace 'const bool isProduction = true;', 'const bool isProduction = false;'
    
    Set-Content -Path $apiConfigFile -Value $content -NoNewline
    
    Write-Host "Development mode enabled" -ForegroundColor Yellow
    Write-Host "Will use local IP: 192.168.100.21 for physical devices" -ForegroundColor Yellow
    Write-Host "Will use localhost for web/emulator" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Mobile app is now configured for local development!" -ForegroundColor Green
    Write-Host "Run 'flutter run' to test locally" -ForegroundColor Cyan
} else {
    Write-Host "Error: api_config.dart file not found!" -ForegroundColor Red
    Write-Host "Please make sure you are in the trabacco_mobile directory" -ForegroundColor Red
}