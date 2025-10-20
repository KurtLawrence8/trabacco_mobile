# PowerShell script to switch mobile app URLs back to Hostinger for production
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SWITCHING MOBILE TO PRODUCTION MODE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$updatedFiles = @()

# Step 1: Update api_config.dart
Write-Host "[1/3] Updating api_config.dart..." -ForegroundColor Yellow
$apiConfigFile = "lib\config\api_config.dart"
if (Test-Path $apiConfigFile) {
    $content = Get-Content $apiConfigFile -Raw
    $updated = $false
    
    # Enable production mode
    if ($content -match 'const bool isProduction = false;') {
        $content = $content -replace 'const bool isProduction = false;', 'const bool isProduction = true;'
        $updated = $true
    }
    
    # Ensure production host is set to Hostinger
    if ($content -notmatch "static const String _productionHost = 'navajowhite-chinchilla-897972\.hostingersite\.com';") {
        $content = $content -replace "static const String _productionHost = '[^']*';", "static const String _productionHost = 'navajowhite-chinchilla-897972.hostingersite.com';"
        $updated = $true
    }
    
    if ($updated) {
        Set-Content -Path $apiConfigFile -Value $content -NoNewline
        $updatedFiles += $apiConfigFile
        Write-Host "  [OK] Updated: $apiConfigFile (Production mode enabled)" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already set to Hostinger production mode" -ForegroundColor Gray
    }
} else {
    Write-Host "  [ERROR] $apiConfigFile not found!" -ForegroundColor Red
}

# Step 2: Update technician_profile_screen.dart
Write-Host ""
Write-Host "[2/3] Updating technician_profile_screen.dart..." -ForegroundColor Yellow
$techProfileFile = "lib\screens\technician_profile_screen.dart"
if (Test-Path $techProfileFile) {
    $content = Get-Content $techProfileFile -Raw
    $updated = $false
    
    # Replace localhost URLs with Hostinger
    $localhostUrl = "http://localhost:8000"
    $hostingerUrl = "https://navajowhite-chinchilla-897972.hostingersite.com"
    
    if ($content -match $localhostUrl) {
        $content = $content -replace $localhostUrl, $hostingerUrl
        $updated = $true
    }
    
    if ($updated) {
        Set-Content -Path $techProfileFile -Value $content -NoNewline
        $updatedFiles += $techProfileFile
        Write-Host "  [OK] Updated: $techProfileFile" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already set to Hostinger" -ForegroundColor Gray
    }
} else {
    Write-Host "  [ERROR] $techProfileFile not found!" -ForegroundColor Red
}

# Step 3: Update farm_worker_profile_screen.dart
Write-Host ""
Write-Host "[3/3] Updating farm_worker_profile_screen.dart..." -ForegroundColor Yellow
$workerProfileFile = "lib\screens\farm_worker_profile_screen.dart"
if (Test-Path $workerProfileFile) {
    $content = Get-Content $workerProfileFile -Raw
    $updated = $false
    
    # Replace localhost URLs with Hostinger
    $localhostUrl = "http://localhost:8000"
    $hostingerUrl = "https://navajowhite-chinchilla-897972.hostingersite.com"
    
    if ($content -match $localhostUrl) {
        $content = $content -replace $localhostUrl, $hostingerUrl
        $updated = $true
    }
    
    if ($updated) {
        Set-Content -Path $workerProfileFile -Value $content -NoNewline
        $updatedFiles += $workerProfileFile
        Write-Host "  [OK] Updated: $workerProfileFile" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already set to Hostinger" -ForegroundColor Gray
    }
} else {
    Write-Host "  [ERROR] $workerProfileFile not found!" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files updated: $($updatedFiles.Count)" -ForegroundColor Green
if ($updatedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Updated files:" -ForegroundColor Yellow
    foreach ($file in $updatedFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[SUCCESS] Mobile app is now configured for PRODUCTION!" -ForegroundColor Green
Write-Host "  Backend URL: https://navajowhite-chinchilla-897972.hostingersite.com" -ForegroundColor White
Write-Host ""
Write-Host "Remember to:" -ForegroundColor Yellow
Write-Host "  1. Hot restart your Flutter app (r + R)" -ForegroundColor Cyan
Write-Host "  2. Build for production if needed" -ForegroundColor Cyan
Write-Host "  3. Switch backend to production mode too" -ForegroundColor Cyan
Write-Host "     (cd ../TRABACCO-BACKEND && .\switch-to-hostinger.ps1)" -ForegroundColor Gray
Write-Host ""

