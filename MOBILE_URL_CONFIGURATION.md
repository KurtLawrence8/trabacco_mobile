# Mobile App URL Configuration Guide

## Overview
Ang mobile app ay naka-configure na para madaling mag-switch between **local development** at **production (Hostinger)** environments. All 3 files with URLs ay automatic na ma-uupdate with a single command!

## Available Scripts

### Individual Scripts

#### 1. Switch Mobile Only to Local
```powershell
.\switch-to-local.ps1
```
Updates:
- `lib/config/api_config.dart` - Main API configuration
- `lib/screens/technician_profile_screen.dart` - Technician profile URLs
- `lib/screens/farm_worker_profile_screen.dart` - Farm worker profile URLs

#### 2. Switch Mobile Only to Hostinger
```powershell
.\switch-to-hostinger.ps1
```
Updates:
- `lib/config/api_config.dart` - Main API configuration
- `lib/screens/technician_profile_screen.dart` - Technician profile URLs
- `lib/screens/farm_worker_profile_screen.dart` - Farm worker profile URLs

### Combined Scripts (RECOMMENDED!)

#### 3. Switch ALL Projects (Frontend + Backend + Mobile) to Local
```powershell
.\switch-all-to-local.ps1
```
This is the **easiest way** - switches all three projects in one command!

#### 4. Switch ALL Projects (Frontend + Backend + Mobile) to Hostinger
```powershell
.\switch-all-to-hostinger.ps1
```
Perfect for preparing deployment - switches everything to production mode!

## Files Automatically Updated

The scripts automatically update **3 files**:

### 1. Main Configuration
- **`lib/config/api_config.dart`** - Main API configuration file
  - `baseUrl` getter (lines 10, 12, 13)
  - `imageBaseUrl` getter (lines 31, 33, 34)

### 2. Profile Screens
- **`lib/screens/technician_profile_screen.dart`** - Technician profile screen
  - Image upload URLs (lines 67, 70, 71)

- **`lib/screens/farm_worker_profile_screen.dart`** - Farm worker profile screen
  - Test URL (line 57)

## Quick Start Workflow

### For Local Development (RECOMMENDED)
```powershell
# Switch ALL projects to local
cd trabacco_mobile
.\switch-all-to-local.ps1

# Start backend server (in new terminal)
cd TRABACCO-BACKEND
php artisan serve

# Start frontend dev server (in new terminal)
cd TRABACCO-FRONTEND
npm run dev

# Run mobile app (in new terminal)
cd trabacco_mobile
flutter run
```

### For Production Deployment
```powershell
# Switch ALL to production
cd trabacco_mobile
.\switch-all-to-hostinger.ps1

# Build frontend
cd TRABACCO-FRONTEND
npm run build

# Deploy to Hostinger
# (Follow your deployment process)
```

## What Gets Updated

### Local Mode
```
All URLs changed from:
https://navajowhite-chinchilla-897972.hostingersite.com
→ http://localhost:8000
```

### Production Mode
```
All URLs changed from:
http://localhost:8000
→ https://navajowhite-chinchilla-897972.hostingersite.com
```

## Mobile-Specific Notes

### Android Emulator
For Android emulator, you might need to use `10.0.2.2:8000` instead of `localhost:8000`:
- The mobile app will automatically handle this through the `ApiConfig` class
- Android emulator maps `10.0.2.2` to the host machine's `localhost`

### Network Security
The mobile app already has network security configuration in:
- `android/app/src/main/res/xml/network_security_config.xml`
- Allows cleartext traffic for localhost, 127.0.0.1, and 10.0.2.2

### Hot Restart Required
After switching URLs, you need to **hot restart** (not just hot reload):
```bash
# In Flutter terminal, press:
r + R  # Hot restart
```

## Script Features

### ✅ Smart Detection
- Checks if files are already in the correct mode
- Only updates files that need updating
- Shows detailed list of updated files

### ✅ Comprehensive Coverage
- Updates main API configuration
- Updates all profile screens with hardcoded URLs
- Handles both API and image URLs

### ✅ Clear Feedback
- Shows progress for each step
- Lists all updated files
- Provides summary and next steps
- Color-coded output for easy reading

## Troubleshooting

### Scripts Won't Run
If PowerShell blocks the scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Check Current Configuration
```powershell
# Check main config file
Get-Content "lib\config\api_config.dart" | Select-String "hostingersite.com\|localhost"

# Search for any remaining hardcoded URLs
Get-ChildItem -Path "lib" -Recurse -Include "*.dart" | Select-String "hostingersite.com"
```

### Flutter Not Picking Up Changes
```bash
# Hot restart (not just hot reload)
# In Flutter terminal: r + R

# Or stop and restart completely
flutter run
```

### Android Emulator Issues
If localhost doesn't work on Android emulator:
1. Make sure backend is running on `http://localhost:8000`
2. The mobile app should automatically use `10.0.2.2:8000` for Android
3. Check network security config is properly set

## Important Notes

1. **After Switching**: Always hot restart your Flutter app (r + R)
2. **Git**: All configuration files are tracked in git
3. **Production URL Saved**: The Hostinger URL is safely stored in the scripts
4. **All Must Match**: Make sure frontend, backend, and mobile are in the same mode

## Related Files

### Frontend Configuration
- `TRABACCO-FRONTEND/switch-to-local.ps1` - Switch frontend to local
- `TRABACCO-FRONTEND/switch-to-hostinger.ps1` - Switch frontend to production
- `TRABACCO-FRONTEND/FRONTEND_URL_CONFIGURATION.md` - Frontend guide

### Backend Configuration
- `TRABACCO-BACKEND/switch-to-local.ps1` - Switch backend to local
- `TRABACCO-BACKEND/switch-to-hostinger.ps1` - Switch backend to production
- `TRABACCO-BACKEND/BACKEND_URL_CONFIGURATION.md` - Backend guide

## Summary

**Zero manual editing needed!** Just run:
```powershell
# For development
.\switch-all-to-local.ps1

# For production
.\switch-all-to-hostinger.ps1
```

That's it! All 3 mobile files + frontend + backend automatically updated! 🚀

## Complete Stack URLs

### Local Development
- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:8000
- **Mobile**: Uses http://localhost:8000 (or 10.0.2.2:8000 for Android emulator)

### Production
- **Frontend**: https://navajowhite-chinchilla-897972.hostingersite.com
- **Backend**: https://navajowhite-chinchilla-897972.hostingersite.com
- **Mobile**: Uses https://navajowhite-chinchilla-897972.hostingersite.com
