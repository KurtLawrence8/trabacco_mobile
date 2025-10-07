# PowerShell script to switch mobile app URLs to localhost for local development
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SWITCHING MOBILE TO LOCAL MODE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$updatedFiles = @()

# Step 1: Update api_config.dart
Write-Host "[1/3] Updating api_config.dart..." -ForegroundColor Yellow
$apiConfigFile = "lib\config\api_config.dart"
if (Test-Path $apiConfigFile) {
    $content = Get-Content $apiConfigFile -Raw
    $updated = $false
    
    # Replace Hostinger URLs with localhost
    $hostingerUrl = "https://navajowhite-chinchilla-897972\.hostingersite\.com"
    $localhostUrl = "http://localhost:8000"
    
    if ($content -match $hostingerUrl) {
        $content = $content -replace $hostingerUrl, $localhostUrl
        $updated = $true
    }
    
    if ($updated) {
        Set-Content -Path $apiConfigFile -Value $content -NoNewline
        $updatedFiles += $apiConfigFile
        Write-Host "  [OK] Updated: $apiConfigFile" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already set to localhost" -ForegroundColor Gray
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
    
    # Replace Hostinger URLs with localhost
    $hostingerUrl = "https://navajowhite-chinchilla-897972\.hostingersite\.com"
    $localhostUrl = "http://localhost:8000"
    
    if ($content -match $hostingerUrl) {
        $content = $content -replace $hostingerUrl, $localhostUrl
        $updated = $true
    }
    
    if ($updated) {
        Set-Content -Path $techProfileFile -Value $content -NoNewline
        $updatedFiles += $techProfileFile
        Write-Host "  [OK] Updated: $techProfileFile" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already set to localhost" -ForegroundColor Gray
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
    
    # Replace Hostinger URLs with localhost
    $hostingerUrl = "https://navajowhite-chinchilla-897972\.hostingersite\.com"
    $localhostUrl = "http://localhost:8000"
    
    if ($content -match $hostingerUrl) {
        $content = $content -replace $hostingerUrl, $localhostUrl
        $updated = $true
    }
    
    if ($updated) {
        Set-Content -Path $workerProfileFile -Value $content -NoNewline
        $updatedFiles += $workerProfileFile
        Write-Host "  [OK] Updated: $workerProfileFile" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already set to localhost" -ForegroundColor Gray
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
Write-Host "[SUCCESS] Mobile app is now configured for LOCAL development!" -ForegroundColor Green
Write-Host "  Backend URL: http://localhost:8000" -ForegroundColor White
Write-Host ""
Write-Host "Remember to:" -ForegroundColor Yellow
Write-Host "  1. Hot restart your Flutter app (r + R)" -ForegroundColor Cyan
Write-Host "  2. Make sure backend is also in local mode" -ForegroundColor Cyan
Write-Host "     (cd ../TRABACCO-BACKEND && .\switch-to-local.ps1)" -ForegroundColor Gray
Write-Host "  3. For Android emulator, use 10.0.2.2:8000 instead of localhost" -ForegroundColor Cyan
Write-Host ""

