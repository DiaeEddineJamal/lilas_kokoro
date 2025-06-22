@echo off
echo ============================================
echo   SAMSUNG ICON FIX SCRIPT
echo ============================================
echo.
echo This script will fix Samsung launcher icon caching issues.
echo.
echo Step 1: Cleaning Flutter project...
call flutter clean
echo.
echo Step 2: Getting dependencies...
call flutter pub get
echo.
echo Step 3: Regenerating launcher icons...
call dart run flutter_launcher_icons
echo.
echo Step 4: Building APK...
call flutter build apk --release
echo.
echo ============================================
echo   MANUAL STEPS REQUIRED ON SAMSUNG DEVICE:
echo ============================================
echo.
echo 1. COMPLETELY UNINSTALL the app from your Samsung device
echo    - Go to Settings ^> Apps ^> Lilas Kokoro ^> Uninstall
echo    - OR long press the app icon and select Uninstall
echo.
echo 2. RESTART your Samsung device (this clears launcher cache)
echo.
echo 3. Install the fresh APK:
echo    flutter install
echo.
echo 4. If icon still doesn't appear, try:
echo    - Clear Samsung Launcher cache:
echo      Settings ^> Apps ^> Samsung Launcher ^> Storage ^> Clear Cache
echo    - Restart device again
echo.
echo ============================================
pause 