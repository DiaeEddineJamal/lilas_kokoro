# Samsung Device Icon Fix Guide

## The Problem
Samsung devices are known for aggressive launcher icon caching, which can cause apps to display the default Flutter icon even when a custom icon is properly configured. This happens because:

1. Samsung's launcher caches icons more aggressively than stock Android
2. The launcher doesn't always refresh the icon when an app is updated
3. Adaptive icons sometimes conflict with Samsung's icon theming system

## The Solution

### Step 1: Complete App Removal
1. **Uninstall the app completely** from your Samsung device:
   - Go to `Settings > Apps > Lilas Kokoro > Uninstall`
   - OR long press the app icon and select "Uninstall"

2. **Clear launcher cache** (important!):
   - Go to `Settings > Apps > Samsung Launcher > Storage > Clear Cache`
   - OR `Settings > Apps > One UI Home > Storage > Clear Cache`

### Step 2: Device Restart
**Restart your Samsung device completely.** This is crucial as it clears all cached launcher data.

### Step 3: Fresh Installation
1. Install the fresh APK that was just built with Samsung-specific fixes:
   ```bash
   flutter install
   ```

2. Or manually install the APK located at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

### Step 4: Verify Icon Display
After installation, check if the correct icon appears. If it still shows the default Flutter icon, try these additional steps:

#### Option A: Clear System Cache
1. Turn off your Samsung device
2. Hold `Volume Up + Power + Home` (or `Volume Up + Power + Bixby` on newer devices)
3. Use volume keys to navigate to "Wipe Cache Partition"
4. Press Power to select
5. Restart the device

#### Option B: Change Launcher Temporarily
1. Install a third-party launcher (like Nova Launcher)
2. Set it as default
3. Check if the icon appears correctly
4. Switch back to Samsung's launcher

#### Option C: Icon Theme Reset
1. Go to `Settings > Themes`
2. Apply a different theme, then switch back to your preferred theme
3. This forces the launcher to refresh all icons

## Technical Details

### What Was Fixed
1. **Adaptive Icon Configuration**: Updated to be more Samsung-compatible
2. **Inset Adjustment**: Reduced from 16% to 10% for better visibility
3. **Monochrome Support**: Added for Android 13+ themed icons
4. **Round Icon Support**: Added explicit round launcher icon
5. **Fallback Icons**: Ensured traditional icons are available as fallbacks

### Files Modified
- `pubspec.yaml`: Updated flutter_launcher_icons configuration
- `android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml`: Optimized adaptive icon
- `android/app/src/main/res/mipmap-anydpi-v26/launcher_icon_round.xml`: Added round icon support

## Why This Happens
Samsung devices use a customized version of Android with their own launcher (One UI Home/Samsung Launcher) that:
- Caches icons more aggressively than stock Android
- Sometimes prioritizes adaptive icon backgrounds over foregrounds
- May not immediately refresh icons when apps are updated
- Has its own icon theming system that can interfere with custom icons

## Prevention
To avoid this issue in the future:
1. Always uninstall the previous version before installing a new one during development
2. Test on both emulators AND real Samsung devices
3. Consider using the batch script `scripts/fix_samsung_icon.bat` for automated cleaning

## Still Having Issues?
If the icon still doesn't appear after following all steps:
1. Try installing on a different Android device to confirm the icon works
2. Check if Samsung's "Icon Frame" feature is affecting your icon
3. Consider creating a more traditional icon design that works better with Samsung's theming

## Success Indicators
You'll know the fix worked when:
- The custom app icon appears immediately after installation
- The icon looks consistent with your design
- The icon appears correctly in all contexts (launcher, recent apps, settings) 