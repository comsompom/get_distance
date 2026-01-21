# TargetLock - AR Distance Measurement App

![TargetLock app icon](TargetLock_icon.png)

[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![ARKit](https://img.shields.io/badge/ARKit-Required-green.svg)](https://developer.apple.com/arkit/)

## 📱 Overview

**TargetLock** is a professional iOS application that measures the distance to objects using your iPhone's camera and ARKit technology. The app uses stadiametric rangefinding, a computer vision technique based on the pinhole camera model, to calculate distances without requiring LiDAR or other specialized hardware.

This project was created to support the Moon Home Agency initiative: https://moonhome.agency/

Developer: Oleg Bourdo — https://www.linkedin.com/in/oleg-bourdo-8a2360139/

### ✨ Key Highlights

- 🎯 **Precise Measurements** - Accurate distance calculations using camera intrinsics
- 📐 **Simple Interface** - Two-tap measurement process
- 🔬 **Built-in Diagnostics** - Validate device and camera capabilities
- 📚 **Helpful Guides** - In-app instructions and calibration tips
- 🔒 **Privacy First** - All processing done locally, no data collection

## How It Works

The application uses the mathematical formula:

**D = (F × H) / h**

Where:
- **D** = Distance to the object (in meters)
- **F** = Focal length (in pixels) - automatically retrieved from your iPhone's camera intrinsics
- **H** = Real height of the object (e.g., 1.7 meters for an average human)
- **h** = Height of the object on the screen (in pixels)

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **AR-Based Measurement** | Uses ARKit for accurate camera tracking and focal length detection |
| 👆 **Simple Two-Tap Interface** | Tap the top and bottom of an object to measure its height on screen |
| 🧍 **Quick Height Presets** | Choose common heights (adult, child, pets) or enter custom |
| 🔧 **Automatic Calibration** | Uses factory-calibrated camera intrinsics from your iPhone (iPhone 6s and newer) |
| 📊 **Real-Time Display** | Shows distance in both meters and feet simultaneously |
| 🎨 **Visual Feedback** | Green and red markers with connecting yellow line for clear visualization |
| 🔄 **Reset Functionality** | Easy reset button to start a new measurement |
| 🔬 **Diagnostics Screen** | View ARKit support, device model, and camera intrinsics |
| ❓ **Help Button** | Quick in‑app usage and calibration guidance |
| ✅ **Confidence Score** | Heuristic confidence based on tracking, lighting, and distance |
| ↩️ **Undo Tap** | Undo the last tap to correct mistakes |
| ⚠️ **Measurement Validation** | Warns on unrealistic distances or inconsistent results |
| 🧾 **Measurement History** | Save and review recent measurements with stats |
| 📤 **Share/Export** | Share a measurement summary via system share sheet |
| ⚙️ **Settings** | Choose units display (meters, feet, or both) |
| 📘 **Tutorial** | Built-in quick tutorial for first-time users |

## Technical Requirements

- **iOS Version**: iOS 13.0 or later
- **Device**: iPhone 6s or newer (devices with ARKit support)
- **Camera**: Requires camera access permission
- **Frameworks Used**:
  - ARKit - For AR tracking and camera intrinsics
  - SceneKit - For AR scene rendering
  - UIKit - For user interface

## 🎯 Use Cases

- 👥 **People Measurement** - Measure distance to adults, children, or any person
- 🐕 **Animal Tracking** - Measure distance to pets or wildlife (when height is known)
- 📦 **Object Measurement** - Measure distance to any object of known height
- 🎓 **Educational** - Learn computer vision principles and stadiametric rangefinding
- 🏗️ **Construction** - Quick distance estimates on job sites
- 🎯 **Sports & Recreation** - Measure distances in outdoor activities

## 🆚 Comparison

| Feature | TargetLock | Typical Rangefinder App |
|---|---|---|
| ARKit-based measurement | ✅ | ❌ |
| Manual calibration option | ✅ | ⚠️ (varies) |
| Diagnostics (intrinsics/ARKit) | ✅ | ❌ |
| Offline-only, no data collection | ✅ | ⚠️ (varies) |
| Quick height presets | ✅ | ❌ |

## Accuracy Considerations

The accuracy of measurements depends on several factors:
- **User Precision**: How accurately you tap the top and bottom of the object
- **Known Height**: The accuracy of the real-world height you input
- **Camera Quality**: The device's camera calibration
- **Distance**: Generally more accurate for objects at moderate distances (2-20 meters)

## 🔒 Privacy & Security

TargetLock is designed with privacy in mind:

✅ **No Data Collection** - The app does not collect, store, or transmit any user data  
✅ **No Network Access** - Works completely offline, no internet connection required  
✅ **No Location Tracking** - Location services are not used  
✅ **Local Processing Only** - All calculations performed on-device  
✅ **No Image Storage** - Camera feed is processed in real-time, never saved  

Your privacy is our priority. All measurements and calculations remain on your device.

## 🛠️ Development

### Tech Stack

- **Language**: Swift 5.0+
- **Interface**: Programmatic UI (no Storyboard)
- **Minimum iOS**: 13.0
- **Architecture**: Scene-based app lifecycle
- **Frameworks**: ARKit, SceneKit, UIKit

### Project Structure

```
TargetLock/
├── TargetLock/
│   ├── ViewController.swift          # Main AR view controller
│   ├── DiagnosticsViewController.swift # Diagnostics screen
│   ├── AppDelegate.swift             # App lifecycle
│   ├── SceneDelegate.swift           # Scene management
│   └── Assets.xcassets/              # App icons and assets
└── TargetLock.xcodeproj/            # Xcode project
```

## 📚 Documentation

- [How to Use](How_to_use.md) - Detailed usage instructions
- [Deployment Guide](how_to_deploy.md) - Step-by-step deployment to iPhone
- [Project Structure](TargetLock/PROJECT_STRUCTURE.md) - Project organization
- [Improvement Suggestions](IMPROVEMENTS_SUGGESTIONS.md) - Future enhancements
- [Changelog](CHANGELOG.md) - Version history
- [Roadmap](ROADMAP.md) - Planned work
- [Known Issues](KNOWN_ISSUES.md) - Current limitations and bugs
- [Contributing](CONTRIBUTING.md) - How to contribute
- [Credits](CREDITS.md) - Acknowledgments
- [FAQ](FAQ.md) - Frequently asked questions
- [Video Demo](VIDEO_DEMO.md) - Demo link
- [Screenshots](SCREENSHOTS/) - App screenshots

## 🚀 Quick Start

1. Open `TargetLock.xcodeproj` in Xcode
2. Connect your iPhone (iOS 13.0+)
3. Select your device and build (⌘R)
4. Grant camera permission when prompted
5. Start measuring!

## ❓ FAQ

**Does TargetLock require internet?**  
No. All processing is on-device.

**What devices are supported?**  
iPhone 6s or newer with iOS 13+ (ARKit required).

**Why are my measurements inconsistent?**  
Tap accuracy, lighting, and object angle all affect results.

## 🛠️ Troubleshooting

- **AR Session Failed**: Restart the app and confirm ARKit support.
- **Inaccurate Measurements**: Re-tap carefully and verify height input.
- **Camera Not Working**: Check camera permissions in Settings.

## 📝 License

This project is provided as-is for educational and personal use.

## 🤝 Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📧 Support

For issues, questions, or suggestions, please refer to the documentation files or create an issue in the project repository.

---

**Made with ❤️ using ARKit and Swift**


