# How to Deploy TargetLock App to iPhone

This guide provides step-by-step instructions for building and deploying the TargetLock app to your iPhone without using the App Store. This process uses Xcode's direct deployment feature.

## Prerequisites

Before you begin, ensure you have:

1. **Mac Computer** with macOS installed
2. **Xcode** installed (version 12.0 or later recommended)
   - Download from Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
3. **iPhone** (iPhone 6s or newer) with iOS 13.0 or later
4. **USB Cable** to connect your iPhone to your Mac
5. **Apple ID** (free Apple Developer account is sufficient for personal deployment)

## Step 1: Install Xcode

1. Open the **App Store** on your Mac
2. Search for **"Xcode"**
3. Click **"Get"** or **"Install"** to download and install Xcode
4. Wait for installation to complete (this may take some time)
5. Open Xcode and accept the license agreement if prompted
6. Install additional components when prompted (Command Line Tools, etc.)

## Step 2: Open the Project in Xcode

1. **Locate the Project Folder**: Navigate to the `TargetLock` folder in your workspace
2. **Open in Xcode**: 
   - Option A: Double-click `TargetLock.xcodeproj` if it exists
   - Option B: Open Xcode, go to **File > Open**, and select the `TargetLock` folder
   - Option C: Drag the `TargetLock` folder onto the Xcode icon in your Dock

## Step 3: Create Xcode Project (If Not Already Created)

If the `.xcodeproj` file doesn't exist, you'll need to create it:

1. Open **Xcode**
2. Select **"Create a new Xcode project"**
3. Choose **"App"** under iOS
4. Click **"Next"**
5. Fill in the project details:
   - **Product Name**: `TargetLock`
   - **Team**: Select your Apple ID (or leave blank for now)
   - **Organization Identifier**: `com.yourname` (use your own identifier)
   - **Interface**: **Storyboard** (we'll use programmatic UI)
   - **Language**: **Swift**
   - **Use Core Data**: Unchecked
   - **Include Tests**: Optional
6. Click **"Next"**
7. Choose the location (your workspace folder)
8. Click **"Create"**

## Step 4: Add Source Files to Project

1. In Xcode, right-click on the project name in the navigator
2. Select **"Add Files to [Project Name]"**
3. Navigate to and select:
   - `ViewController.swift`
   - `DiagnosticsViewController.swift`
   - `AppDelegate.swift`
   - `SceneDelegate.swift`
   - `Info.plist`
4. Make sure **"Copy items if needed"** is checked
5. Make sure your target is selected
6. Click **"Add"**

## Step 5: Configure Project Settings

1. **Select the Project** in the navigator (top item)
2. **Select the Target** "TargetLock"
3. Go to the **"General"** tab:
   - **Bundle Identifier**: Change to something unique (e.g., `com.yourname.TargetLock`)
   - **Version**: `1.0`
   - **Build**: `1`
   - **Minimum Deployments**: iOS 13.0

4. Go to the **"Signing & Capabilities"** tab:
   - Check **"Automatically manage signing"**
   - **Team**: Select your Apple ID
     - If you don't see your team, click **"Add Account"** and sign in with your Apple ID
   - Xcode will automatically create a provisioning profile

5. Go to the **"Info"** tab (or edit `Info.plist`):
   - Ensure `NSCameraUsageDescription` is present with a description
   - Ensure `UIRequiredDeviceCapabilities` includes `arkit`
   - Ensure `UILaunchStoryboardName` is set to `LaunchScreen`

## Step 6: Connect Your iPhone

1. **Unlock your iPhone**
2. **Connect iPhone to Mac** using USB cable
3. On your iPhone, you may see a prompt: **"Trust This Computer?"**
   - Tap **"Trust"**
   - Enter your iPhone passcode if prompted
4. On your Mac, you may see a prompt asking to trust the device - click **"Trust"**

## Step 7: Select Your iPhone as the Build Target

1. In Xcode, look at the top toolbar
2. Click on the device selector (next to the Play/Stop buttons)
3. Select your connected iPhone from the list
   - It should appear as "iPhone" or "[Your Name]'s iPhone"
   - If it doesn't appear, make sure:
     - iPhone is unlocked
     - USB cable is properly connected
     - You've trusted the computer on both devices

## Step 8: Build and Run the App

1. **Click the Play button** (▶️) in the top-left of Xcode, or press **Cmd + R**
2. Xcode will:
   - Build the project
   - Sign the app with your Apple ID
   - Install it on your iPhone
   - Launch the app

3. **First Launch**: On your iPhone, you may see:
   - **"Untrusted Developer"** message
   - Go to **Settings > General > VPN & Device Management** (or **Profiles & Device Management**)
   - Tap on your Apple ID/Developer profile
   - Tap **"Trust [Your Apple ID]"**
   - Tap **"Trust"** in the confirmation dialog
   - Return to the app and launch it again

## Step 9: Grant Permissions

1. When the app launches, it will request **Camera** permission
2. Tap **"OK"** or **"Allow"** to grant camera access
3. The app should now display the camera view
4. Optional: Tap **Diagnostics** to verify ARKit support and intrinsics
5. Optional: Tap **Help** for quick usage and calibration tips

## Troubleshooting Common Issues

### Issue: "No signing certificate found"
**Solution**: 
- Go to **Signing & Capabilities** tab
- Select your Apple ID in the Team dropdown
- If needed, click **"Add Account"** and sign in

### Issue: "Device not found" or iPhone not appearing
**Solutions**:
- Unlock your iPhone
- Disconnect and reconnect the USB cable
- Trust the computer on both devices
- Try a different USB port or cable
- Restart Xcode

### Issue: "Untrusted Developer" after installation
**Solution**:
- On iPhone: **Settings > General > VPN & Device Management**
- Find your developer profile
- Tap **"Trust"**

### Issue: "ARKit is not supported"
**Solution**:
- Ensure you're using iPhone 6s or newer
- Check iOS version is 13.0 or later
- Some older devices don't support ARKit

### Issue: Build errors
**Solutions**:
- Check that all Swift files are added to the target
- Ensure `Info.plist` is properly configured
- Clean build folder: **Product > Clean Build Folder** (Shift + Cmd + K)
- Check for missing imports or syntax errors

### Issue: App crashes on launch
**Solutions**:
- Check Console in Xcode for error messages
- Verify camera permissions in Settings
- Ensure ARKit is supported on your device
- Check that all required frameworks are linked

## Updating the App

When you make changes to the code:

1. Make your code changes
2. Click **Play** button again (or **Cmd + R**)
3. Xcode will rebuild and reinstall the app
4. The app will automatically launch on your iPhone

## App Expiration

**Important**: Apps installed via this method (using a free Apple Developer account) will expire after **7 days**. To continue using the app:

- Rebuild and redeploy before expiration, OR
- Sign up for a paid Apple Developer Program ($99/year) for apps that don't expire

## Alternative: Using Xcode Command Line

If you prefer using the command line:

```bash
# Navigate to project directory
cd /path/to/TargetLock

# Build for device
xcodebuild -project TargetLock.xcodeproj \
           -scheme TargetLock \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           build

# Install to connected device
xcrun devicectl device install app --device [DEVICE_ID] [APP_PATH]
```

## Summary Checklist

- [ ] Xcode installed on Mac
- [ ] Project opened in Xcode
- [ ] All source files added to project
- [ ] Project configured (Bundle ID, Signing, etc.)
- [ ] iPhone connected via USB
- [ ] iPhone selected as build target
- [ ] App built and installed successfully
- [ ] Developer profile trusted on iPhone
- [ ] Camera permission granted
- [ ] App running on iPhone

## Need Help?

If you encounter issues:
1. Check Xcode's **Issue Navigator** (⚠️ icon) for build errors
2. Check the **Console** for runtime errors
3. Verify all prerequisites are met
4. Ensure your iPhone meets the requirements (iPhone 6s+, iOS 13+)

Congratulations! You should now have the TargetLock app running on your iPhone.


