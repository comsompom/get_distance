# How to Use TargetLock App

## Getting Started

1. **Launch the App**: Open the TargetLock app on your iPhone
2. **Grant Camera Permission**: When prompted, allow the app to access your camera
3. **Point at Target**: Point your iPhone camera at the object you want to measure (typically a person or animal)

This project was created to support the Moon Home Agency initiative: https://moonhome.agency/

## Step-by-Step Measurement Process

### Step 1: Tap the Top of the Object
- Look at the object through your camera view
- **Tap once** on the **top** of the object (e.g., the top of a person's head)
- You will see a **green marker** appear at the tap location
- The instruction label will change to "Tap bottom of object"

### Step 2: Tap the Bottom of the Object
- **Tap once** on the **bottom** of the object (e.g., the bottom of a person's feet or shoes)
- You will see a **red marker** appear at the tap location
- A **yellow dashed line** will connect the two markers
- A popup dialog will appear asking for the object's height

### Optional: Auto Detect
- Tap **Auto** to detect a person automatically
- The app marks the top and bottom points for you
- If detection fails, use manual taps as usual

### Step 3: Select the Object's Height
- Choose a **preset** from the list:
  - Adult Male (1.75m)
  - Adult Female (1.65m)
  - Child (1.20m)
  - Large Dog (0.70m)
  - Medium Dog (0.50m)
  - Small Dog (0.30m)
- Or tap **Custom…** to enter the **real-world height** in **meters**
- Tap **"Calculate"** to compute the distance

### Step 4: View the Result
- The distance will be displayed at the top of the screen
- Distance is shown in **meters** and **feet**
- Example: "Distance: 5.23 meters (17.2 ft)"
- A **Confidence** percentage is shown to indicate measurement reliability

## Diagnostics Screen

Use Diagnostics to validate your device and camera data:

1. Tap **Diagnostics** (top-right).
2. Review:
   - ARKit supported (yes/no)
   - Device model and iOS version
   - Camera intrinsics (fx, fy, cx, cy)
3. Tap **Refresh** to update values.
4. Tap **Close** to return to the camera view.

## Help Button

Tap **Help** to see short instructions on:
- How to measure (top tap, bottom tap, enter height)
- Optional calibration steps
- Tap **Tutorial** inside Help for a guided quick walkthrough

## Settings

- Tap **Settings** to choose how distances are displayed
- Options: meters, feet, or both
- Use **Show Grid Overlay** to toggle the alignment grid
- Choose **Theme** to use system, light, or dark appearance

## Starting a New Measurement

- Tap the **"Reset"** button in the bottom-right corner
- This clears all markers and measurements
- You can now start a new measurement

## Undo and Validation

- Tap **Undo** to remove the last tap (top or bottom) if you make a mistake
- If a measurement looks unrealistic or inconsistent, the app shows a warning
- If warnings appear often, consider recalibrating

## Measurement History

- Tap **History** to view recent measurements and stats
- The list shows distance, height, confidence, and timestamp
- Tap a row to **Share** or **Delete**
- Use **Clear All** to remove all saved measurements

## Tips for Best Results

### Accuracy Tips
1. **Hold Steady**: Keep your iPhone as steady as possible while tapping
2. **Tap Precisely**: Try to tap exactly on the top and bottom points
3. **Know the Height**: Use an accurate height value for best results
4. **Good Lighting**: Ensure adequate lighting for better camera performance
5. **Moderate Distance**: The app works best for objects between 2-20 meters away

### Common Use Cases

#### Measuring Distance to a Person
1. Point camera at the person
2. Tap the top of their head (green marker)
3. Tap the bottom of their feet (red marker)
4. Enter their height (e.g., 1.75 for 175 cm)
5. View the calculated distance

#### Measuring Distance to an Animal
1. Point camera at the animal
2. Tap the top of the animal (highest point)
3. Tap the bottom of the animal (lowest point, usually paws)
4. Enter estimated height (e.g., 0.6 for a medium dog)
5. View the calculated distance

### Troubleshooting

#### "AR Session Failed" Error
- Ensure you're using an iPhone 6s or newer
- Make sure ARKit is supported on your device
- Try restarting the app

#### Inaccurate Measurements
- Double-check that you tapped the exact top and bottom
- Verify the height value you entered is correct
- Ensure good lighting conditions
- Try measuring from a different angle

#### Markers Not Appearing
- Make sure you're tapping on the camera view
- Check that the app has camera permissions
- Try resetting and starting over

#### Camera Not Working
- Check Settings > Privacy > Camera to ensure the app has permission
- Close and reopen the app
- Restart your iPhone if the problem persists

## Understanding the Display

- **Green Marker**: Indicates the top point you tapped
- **Red Marker**: Indicates the bottom point you tapped
- **Yellow Dashed Line**: Shows the measured height on screen
- **Info Label**: Displays instructions and results
- **Reset Button**: Clears current measurement

## Limitations

- Requires objects of known height
- Accuracy depends on precise tapping
- Works best in good lighting conditions
- More accurate for moderate distances (2-20 meters)
- Requires ARKit-compatible device (iPhone 6s or newer)

## Advanced Usage

For more accurate measurements:
- Measure the same object multiple times and average the results
- Use a known reference object to verify accuracy
- Ensure the object is standing straight (not leaning)
- Measure when the object is perpendicular to your line of sight


