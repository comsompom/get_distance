# Project Structure

This document describes the structure of the Focal Distance Xcode project.

## Directory Structure

```
FocalDistance/
├── FocalDistance/                    # Main application folder
│   ├── AppDelegate.swift             # Application lifecycle delegate
│   ├── SceneDelegate.swift           # Scene lifecycle delegate (iOS 13+)
│   ├── ViewController.swift          # Main AR view controller with distance measurement logic
│   ├── Info.plist                    # App configuration and permissions
│   ├── Assets.xcassets/              # App assets (icons, images)
│   │   └── Contents.json
│   └── Base.lproj/                    # Localization resources
│       └── LaunchScreen.storyboard    # Launch screen
└── FocalDistance.xcodeproj/           # Xcode project file
    ├── project.pbxproj                # Project configuration
    └── xcshareddata/
        └── xcschemes/
            └── FocalDistance.xcscheme # Build scheme
```

## Key Files

### ViewController.swift
- Main AR view controller
- Implements ARSCNViewDelegate
- Handles tap gestures for measurement
- Calculates distance using stadiametric rangefinding formula
- Manages UI elements (labels, buttons, markers)

### AppDelegate.swift
- Application entry point
- Handles app lifecycle events
- Configures scene sessions

### SceneDelegate.swift
- Manages scene lifecycle (iOS 13+)
- Creates and configures the main window
- Sets ViewController as root view controller

### Info.plist
- Camera usage description (required for camera access)
- ARKit requirement
- Supported interface orientations
- Scene configuration

## Frameworks Used

- **ARKit**: For AR tracking and camera intrinsics
- **SceneKit**: For AR scene rendering
- **UIKit**: For user interface components

## Build Requirements

- iOS 13.0 or later
- Xcode 12.0 or later
- Swift 5.0 or later
- ARKit-compatible device (iPhone 6s or newer)

## Opening the Project

1. Double-click `FocalDistance.xcodeproj` to open in Xcode
2. Or open Xcode and select File > Open, then navigate to this folder

## Next Steps

1. Open the project in Xcode
2. Configure signing (see `how_to_deploy.md`)
3. Connect your iPhone
4. Build and run!

For detailed deployment instructions, see `how_to_deploy.md` in the root directory.
