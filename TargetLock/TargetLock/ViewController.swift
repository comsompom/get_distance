import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - UI Elements
    var sceneView: ARSCNView!
    var infoLabel: UILabel!
    var resetButton: UIButton!
    var diagnosticsButton: UIButton!
    var helpButton: UIButton!
    var undoButton: UIButton!
    var historyButton: UIButton!
    var settingsButton: UIButton!
    
    // MARK: - Logic Variables
    var startPoint: CGPoint? // Top of object
    var endPoint: CGPoint?   // Bottom of object
    var rectLayer: CAShapeLayer? // To draw the line/box on screen
    var markers: [CAShapeLayer] = [] // Track all markers for easy removal
    var recentDistances: [Float] = []
    var measurementHistory: [Measurement] = []

    private let presetManager = PresetManager()
    private let measurementCalculator: MeasurementCalculating = MeasurementCalculator()
    private let haptics = HapticFeedbackManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Configure AR View
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = false
        sceneView.antialiasingMode = .none
        sceneView.preferredFramesPerSecond = 60
        
        // Add Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if ARKit is supported
        if !ARWorldTrackingConfiguration.isSupported {
            let alert = UIAlertController(
                title: "ARKit Not Supported",
                message: "This app requires ARKit which is not available on this device.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if presentedViewController == nil {
                present(alert, animated: true)
            }
            infoLabel.text = "ARKit not supported"
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.isLightEstimationEnabled = false
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        let alert = UIAlertController(
            title: "AR Session Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted
        infoLabel.text = "AR Session Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        infoLabel.text = "Tap top of object"
    }
    
    // MARK: - The Math Logic
    func calculateDistance(realHeightMeters: Float) {
        guard let start = startPoint, let end = endPoint, 
              let currentFrame = sceneView.session.currentFrame else { return }
        
        // 1. Calculate height of object on screen (in pixels)
        // We use the distance between the two tapped points in view points,
        // then scale to pixels to match camera intrinsics.
        let pixelHeightPoints = abs(start.y - end.y)
        let pixelHeight = Float(pixelHeightPoints * sceneView.contentScaleFactor)
        
        if pixelHeight == 0 { return }
        
        // 2. Get Focal Length from Camera Intrinsics
        // ARKit provides a 3x3 matrix. column 1, row 1 (yy) is the focal length in pixels for the Y axis.
        let focalLengthPixels = currentFrame.camera.intrinsics.columns.1.y
        
        // 3. Apply Formula: Distance = (FocalLength * RealHeight) / ImageHeight
        let distanceMeters = measurementCalculator.calculateDistanceMeters(
            focalLengthPixels: focalLengthPixels,
            realHeightMeters: realHeightMeters,
            pixelHeight: pixelHeight
        )

        let confidence = computeConfidence(
            distanceMeters: distanceMeters,
            pixelHeight: pixelHeight,
            frame: currentFrame
        )
        validateMeasurement(distanceMeters: distanceMeters)
        recordMeasurement(distanceMeters: distanceMeters, heightMeters: realHeightMeters, confidence: confidence)
        
        // Update UI
        DispatchQueue.main.async {
            self.infoLabel.text = self.formatDistanceLabel(distanceMeters: distanceMeters, confidence: confidence)
        }
    }

    // MARK: - Interaction
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        haptics.impactLight()
        
        if startPoint == nil {
            // First Tap (Top of head)
            startPoint = location
            infoLabel.text = "Tap bottom of object"
            drawMarker(at: location, isStart: true)
        } else if endPoint == nil {
            // Second Tap (Feet)
            endPoint = location
            drawMarker(at: location, isStart: false)
            drawLine()
            
            // Ask user for height
            askForObjectHeight()
        }
    }
    
    func askForObjectHeight() {
        let presets = presetManager.presets()

        let sheet = UIAlertController(
            title: "Select Height",
            message: "Choose a preset or enter a custom height (meters).",
            preferredStyle: .actionSheet
        )

        for preset in presets {
            sheet.addAction(UIAlertAction(title: preset.title, style: .default) { [weak self] _ in
                self?.calculateDistance(realHeightMeters: preset.heightMeters)
            })
        }

        sheet.addAction(UIAlertAction(title: "Custom…", style: .default) { [weak self] _ in
            self?.showCustomHeightPrompt()
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.resetMeasurement()
        })

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 80, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }

        if presentedViewController == nil {
            present(sheet, animated: true, completion: nil)
        }
    }

    private func showCustomHeightPrompt() {
        let alert = UIAlertController(
            title: "Custom Height",
            message: "Enter height in meters (e.g. 1.7)",
            preferredStyle: .alert
        )
        
        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
            textField.placeholder = "1.7"
            textField.text = "1.7" // Default average human height
        }
        
        let calculateAction = UIAlertAction(title: "Calculate", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text, let height = Float(text), height > 0 {
                self?.calculateDistance(realHeightMeters: height)
            } else {
                guard let self = self else { return }
                let errorAlert = UIAlertController(
                    title: "Invalid Input",
                    message: "Please enter a valid height greater than 0.",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                if self.presentedViewController == nil {
                    self.present(errorAlert, animated: true)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.resetMeasurement()
        }
        
        alert.addAction(calculateAction)
        alert.addAction(cancelAction)
        if presentedViewController == nil {
            present(alert, animated: true, completion: nil)
        }
    }

    private func computeConfidence(distanceMeters: Float, pixelHeight: Float, frame: ARFrame) -> Float {
        // Heuristic confidence score based on distance, tap size, lighting, and tracking quality.
        let distanceScore = clamp(value: 1.0 - (distanceMeters / 20.0), min: 0.2, max: 1.0)
        let pixelScore = clamp(value: Float(pixelHeight) / 300.0, min: 0.2, max: 1.0)

        let lightScore: Float
        if let light = frame.lightEstimate {
            // 1000 is neutral; below ~200 is dim.
            lightScore = clamp(value: Float(light.ambientIntensity) / 1000.0, min: 0.2, max: 1.0)
        } else {
            lightScore = 0.6
        }

        let trackingScore: Float
        switch frame.camera.trackingState {
        case .normal:
            trackingScore = 1.0
        case .limited:
            trackingScore = 0.6
        case .notAvailable:
            trackingScore = 0.3
        }

        // Weighted average.
        let raw = (0.35 * distanceScore) + (0.25 * pixelScore) + (0.20 * lightScore) + (0.20 * trackingScore)
        return clamp(value: raw, min: 0.1, max: 1.0)
    }

    private func clamp(value: Float, min: Float, max: Float) -> Float {
        if value < min { return min }
        if value > max { return max }
        return value
    }

    private func validateMeasurement(distanceMeters: Float) {
        var warnings: [String] = []

        if distanceMeters < 0.5 {
            warnings.append("Very close range (<0.5m). Results may be inaccurate.")
        } else if distanceMeters > 50.0 {
            warnings.append("Very long range (>50m). Results may be inaccurate.")
        }

        if let last = recentDistances.last {
            let delta = abs(distanceMeters - last)
            let changeRatio = delta / max(last, 0.1)
            if changeRatio > 0.5 {
                warnings.append("Large jump vs last measurement. Consider recalibration.")
            }
        }

        recentDistances.append(distanceMeters)
        if recentDistances.count > 5 {
            recentDistances.removeFirst()
        }

        if warnings.isEmpty { return }
        let message = warnings.joined(separator: "\n")
        let alert = UIAlertController(title: "Measurement Warning", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }

    private func recordMeasurement(distanceMeters: Float, heightMeters: Float, confidence: Float) {
        let measurement = Measurement(
            timestamp: Date(),
            distanceMeters: distanceMeters,
            heightMeters: heightMeters,
            confidence: confidence
        )
        measurementHistory.append(measurement)
        if measurementHistory.count > 50 {
            measurementHistory.removeFirst()
        }
    }

    private func formatDistanceLabel(distanceMeters: Float, confidence: Float) -> String {
        let feet = distanceMeters * 3.28084
        let confidenceText = String(format: "Confidence: %.0f%%", confidence * 100)
        switch AppSettings.shared.displayUnit {
        case .meters:
            return String(format: "Distance: %.2f meters\n%@", distanceMeters, confidenceText)
        case .feet:
            return String(format: "Distance: %.1f ft\n%@", feet, confidenceText)
        case .both:
            return String(format: "Distance: %.2f meters (%.1f ft)\n%@", distanceMeters, feet, confidenceText)
        }
    }
    
    // MARK: - Reset Logic
    @objc func resetMeasurement() {
        startPoint = nil
        endPoint = nil
        rectLayer?.removeFromSuperlayer()
        rectLayer = nil
        infoLabel.text = "Tap top of object"
        
        // Remove all markers
        markers.forEach { $0.removeFromSuperlayer() }
        markers.removeAll()
        recentDistances.removeAll()
    }

    @objc func undoLastTap() {
        if endPoint != nil {
            endPoint = nil
            rectLayer?.removeFromSuperlayer()
            rectLayer = nil
            if let lastMarker = markers.popLast() {
                lastMarker.removeFromSuperlayer()
            }
            infoLabel.text = "Tap bottom of object"
        } else if startPoint != nil {
            startPoint = nil
            if let lastMarker = markers.popLast() {
                lastMarker.removeFromSuperlayer()
            }
            infoLabel.text = "Tap top of object"
        }
    }

    @objc func showDiagnostics() {
        let diagnosticsVC = DiagnosticsViewController(session: sceneView.session)
        diagnosticsVC.modalPresentationStyle = .formSheet
        if presentedViewController == nil {
            present(diagnosticsVC, animated: true)
        }
    }

    @objc func showHistory() {
        let historyVC = HistoryViewController(measurements: measurementHistory)
        historyVC.onUpdate = { [weak self] updated in
            self?.measurementHistory = updated
        }
        let navController = UINavigationController(rootViewController: historyVC)
        navController.modalPresentationStyle = .formSheet
        if presentedViewController == nil {
            present(navController, animated: true)
        }
    }

    @objc func showHelp() {
        let message = """
        How to measure:
        1) Point the camera at the person/animal.
        2) Tap the top of the object.
        3) Tap the bottom of the object.
        4) Enter the real height in meters.

        Calibration (optional):
        • Stand 5m from a wall.
        • Mark a 1m height.
        • Measure the on‑screen pixel height (h).
        • Compute F = (5m × h) / 1m.
        • Use that F as a correction factor in code.

        Support note:
        This project was created to support the Moon Home Agency initiative:
        https://moonhome.agency/
        """

        let alert = UIAlertController(title: "Help", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tutorial", style: .default) { [weak self] _ in
            self?.showTutorial()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }

    @objc func showSettings() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .formSheet
        if presentedViewController == nil {
            present(navController, animated: true)
        }
    }

    @objc func showTutorial() {
        let tutorialVC = TutorialViewController()
        let navController = UINavigationController(rootViewController: tutorialVC)
        navController.modalPresentationStyle = .formSheet
        if presentedViewController == nil {
            present(navController, animated: true)
        }
    }

    // MARK: - Drawing Helpers (Visual Feedback)
    func drawMarker(at point: CGPoint, isStart: Bool) {
        let path = UIBezierPath(arcCenter: point, radius: 8, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = isStart ? UIColor.green.cgColor : UIColor.red.cgColor
        shape.strokeColor = UIColor.white.cgColor
        shape.lineWidth = 2.0
        sceneView.layer.addSublayer(shape)
        markers.append(shape)
    }
    
    func drawLine() {
        guard let start = startPoint, let end = endPoint else { return }
        
        // Remove old line if exists
        rectLayer?.removeFromSuperlayer()
        
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        
        rectLayer = CAShapeLayer()
        rectLayer?.path = path.cgPath
        rectLayer?.strokeColor = UIColor.yellow.cgColor
        rectLayer?.lineWidth = 3.0
        rectLayer?.lineDashPattern = [10, 5]
        if let layer = rectLayer {
            sceneView.layer.addSublayer(layer)
        }
    }
    
    // MARK: - UI Setup (Boilerplate)
    func setupUI() {
        // AR Scene View
        sceneView = ARSCNView(frame: self.view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(sceneView)
        
        // Info Label
        infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        infoLabel.textColor = .white
        infoLabel.textAlignment = .center
        infoLabel.text = "Tap top of object"
        infoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        infoLabel.layer.cornerRadius = 10
        infoLabel.clipsToBounds = true
        infoLabel.numberOfLines = 0
        self.view.addSubview(infoLabel)
        
        // Reset Button
        resetButton = UIButton(type: .system)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.backgroundColor = UIColor.systemBlue
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetMeasurement), for: .touchUpInside)
        self.view.addSubview(resetButton)

        // Undo Button
        undoButton = UIButton(type: .system)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.backgroundColor = UIColor.systemOrange
        undoButton.setTitle("Undo", for: .normal)
        undoButton.setTitleColor(.white, for: .normal)
        undoButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        undoButton.layer.cornerRadius = 10
        undoButton.addTarget(self, action: #selector(undoLastTap), for: .touchUpInside)
        self.view.addSubview(undoButton)

        // Diagnostics Button
        diagnosticsButton = UIButton(type: .system)
        diagnosticsButton.translatesAutoresizingMaskIntoConstraints = false
        diagnosticsButton.backgroundColor = UIColor.systemGray
        diagnosticsButton.setTitle("Diagnostics", for: .normal)
        diagnosticsButton.setTitleColor(.white, for: .normal)
        diagnosticsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        diagnosticsButton.layer.cornerRadius = 10
        diagnosticsButton.addTarget(self, action: #selector(showDiagnostics), for: .touchUpInside)
        self.view.addSubview(diagnosticsButton)

        // History Button
        historyButton = UIButton(type: .system)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.backgroundColor = UIColor.systemIndigo
        historyButton.setTitle("History", for: .normal)
        historyButton.setTitleColor(.white, for: .normal)
        historyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        historyButton.layer.cornerRadius = 10
        historyButton.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
        self.view.addSubview(historyButton)

        // Settings Button
        settingsButton = UIButton(type: .system)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.backgroundColor = UIColor.systemPurple
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        settingsButton.layer.cornerRadius = 10
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        self.view.addSubview(settingsButton)

        // Help Button
        helpButton = UIButton(type: .system)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.backgroundColor = UIColor.systemTeal
        helpButton.setTitle("Help", for: .normal)
        helpButton.setTitleColor(.white, for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        helpButton.layer.cornerRadius = 10
        helpButton.addTarget(self, action: #selector(showHelp), for: .touchUpInside)
        self.view.addSubview(helpButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: helpButton.bottomAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            infoLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 50),

            undoButton.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -10),
            undoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            undoButton.widthAnchor.constraint(equalToConstant: 100),
            undoButton.heightAnchor.constraint(equalToConstant: 44),

            diagnosticsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            diagnosticsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            diagnosticsButton.widthAnchor.constraint(equalToConstant: 110),
            diagnosticsButton.heightAnchor.constraint(equalToConstant: 36),

            historyButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            historyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            historyButton.widthAnchor.constraint(equalToConstant: 90),
            historyButton.heightAnchor.constraint(equalToConstant: 36),

            settingsButton.topAnchor.constraint(equalTo: historyButton.bottomAnchor, constant: 8),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            settingsButton.widthAnchor.constraint(equalToConstant: 90),
            settingsButton.heightAnchor.constraint(equalToConstant: 36),

            helpButton.topAnchor.constraint(equalTo: diagnosticsButton.bottomAnchor, constant: 8),
            helpButton.trailingAnchor.constraint(equalTo: diagnosticsButton.trailingAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 110),
            helpButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
}
