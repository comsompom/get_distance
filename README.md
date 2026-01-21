# Focal Distance - AR Distance Measurement App

## Overview

**Focal Distance** is an iOS application that measures the distance to objects using your iPhone's camera and ARKit technology. The app uses stadiametric rangefinding, a computer vision technique based on the pinhole camera model, to calculate distances without requiring LiDAR or other specialized hardware.

## How It Works

The application uses the mathematical formula:

**D = (F × H) / h**

Where:
- **D** = Distance to the object (in meters)
- **F** = Focal length (in pixels) - automatically retrieved from your iPhone's camera intrinsics
- **H** = Real height of the object (e.g., 1.7 meters for an average human)
- **h** = Height of the object on the screen (in pixels)

## Key Features

- **AR-Based Measurement**: Uses ARKit for accurate camera tracking and focal length detection
- **Simple Two-Tap Interface**: Tap the top and bottom of an object to measure its height on screen
- **Automatic Calibration**: Uses factory-calibrated camera intrinsics from your iPhone (iPhone 6s and newer)
- **Real-Time Distance Display**: Shows distance in both meters and feet
- **Visual Feedback**: Green and red markers indicate top and bottom points, with a yellow line connecting them
- **Reset Functionality**: Easy reset button to start a new measurement

## Technical Requirements

- **iOS Version**: iOS 13.0 or later
- **Device**: iPhone 6s or newer (devices with ARKit support)
- **Camera**: Requires camera access permission
- **Frameworks Used**:
  - ARKit - For AR tracking and camera intrinsics
  - SceneKit - For AR scene rendering
  - UIKit - For user interface

## Use Cases

- Measuring distance to people (adults, children)
- Measuring distance to animals (when you know their approximate height)
- Measuring distance to any object of known height
- Educational purposes to understand computer vision principles

## Accuracy Considerations

The accuracy of measurements depends on several factors:
- **User Precision**: How accurately you tap the top and bottom of the object
- **Known Height**: The accuracy of the real-world height you input
- **Camera Quality**: The device's camera calibration
- **Distance**: Generally more accurate for objects at moderate distances (2-20 meters)

## Privacy

The app requires camera access to function but does not:
- Store or transmit any images or video
- Collect any personal data
- Require internet connection
- Track user location

All processing is done locally on your device.

## Development

This project is built with:
- **Language**: Swift 5.0+
- **Interface**: Programmatic UI (no Storyboard)
- **Minimum iOS**: 13.0
- **Architecture**: Scene-based app lifecycle

## License

This project is provided as-is for educational and personal use.
