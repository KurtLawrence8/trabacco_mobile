# PowerShell script to switch ALL projects (Frontend, Backend, Mobile) to production (Hostinger)
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  SWITCHING ENTIRE STACK TO PRODUCTION" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# Switch Frontend
Write-Host ">>> FRONTEND <<<" -ForegroundColor Yellow
Push-Location "..\TRABACCO-FRONTEND"
& ".\switch-to-hostinger.ps1"
Pop-Location

# Switch Backend
Write-Host ""
Write-Host ">>> BACKEND <<<" -ForegroundColor Yellow
Push-Location "..\TRABACCO-BACKEND"
& ".\switch-to-hostinger.ps1"
Pop-Location

# Switch Mobile
Write-Host ""
Write-Host ">>> MOBILE <<<" -ForegroundColor Yellow
& ".\switch-to-hostinger.ps1"

# Final Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  COMPLETE! ALL PROJECTS ARE NOW PRODUCTION" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ready for deployment!" -ForegroundColor Green
Write-Host "  Don't forget to build and deploy all projects" -ForegroundColor Cyan
Write-Host ""
Write-Host "Production URLs:" -ForegroundColor Yellow
Write-Host "  Frontend: https://navajowhite-chinchilla-897972.hostingersite.com" -ForegroundColor White
Write-Host "  Backend:  https://navajowhite-chinchilla-897972.hostingersite.com" -ForegroundColor White
Write-Host "  Mobile:   Uses https://navajowhite-chinchilla-897972.hostingersite.com" -ForegroundColor White
Write-Host ""