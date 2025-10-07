# PowerShell script to switch ALL projects (Frontend, Backend, Mobile) to local development
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  SWITCHING ENTIRE STACK TO LOCAL MODE" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# Switch Frontend
Write-Host ">>> FRONTEND <<<" -ForegroundColor Yellow
Push-Location "..\TRABACCO-FRONTEND"
& ".\switch-to-local.ps1"
Pop-Location

# Switch Backend
Write-Host ""
Write-Host ">>> BACKEND <<<" -ForegroundColor Yellow
Push-Location "..\TRABACCO-BACKEND"
& ".\switch-to-local.ps1"
Pop-Location

# Switch Mobile
Write-Host ""
Write-Host ">>> MOBILE <<<" -ForegroundColor Yellow
& ".\switch-to-local.ps1"

# Final Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  COMPLETE! ALL PROJECTS ARE NOW LOCAL" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Now start your servers:" -ForegroundColor Green
Write-Host "  Backend:  cd TRABACCO-BACKEND; php artisan serve" -ForegroundColor Cyan
Write-Host "  Frontend: cd TRABACCO-FRONTEND; npm run dev" -ForegroundColor Cyan
Write-Host "  Mobile:   flutter run" -ForegroundColor Cyan
Write-Host ""
Write-Host "URLs:" -ForegroundColor Yellow
Write-Host "  Frontend: http://localhost:5173" -ForegroundColor White
Write-Host "  Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "  Mobile:   Uses http://localhost:8000" -ForegroundColor White
Write-Host ""