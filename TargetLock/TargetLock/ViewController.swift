import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - UI Elements
    var sceneView: ARSCNView!
    var infoLabel: UILabel!
    var infoBlurView: UIVisualEffectView!
    var confidenceBar: UIProgressView!
    var resetButton: UIButton!
    var diagnosticsButton: UIButton!
    var helpButton: UIButton!
    var undoButton: UIButton!
    var historyButton: UIButton!
    var settingsButton: UIButton!
    var autoDetectButton: UIButton!
    
    // MARK: - Logic Variables
    var startPoint: CGPoint? // Top of object
    var endPoint: CGPoint?   // Bottom of object
    var rectLayer: CAShapeLayer? // To draw the line/box on screen
    var markers: [CAShapeLayer] = [] // Track all markers for easy removal
    var recentDistances: [Float] = []
    var measurementHistory: [Measurement] = []
    var crosshairLayer = CAShapeLayer()
    var gridLayer = CAShapeLayer()
    var lastDistanceMeters: Float?
    var lastConfidence: Float?
    var lastAngleDegrees: Float?

    private let presetManager = PresetManager()
    private let measurementCalculator: MeasurementCalculating = MeasurementCalculator()
    private let haptics = HapticFeedbackManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsChange), name: .appSettingsDidChange, object: nil)
        
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

        applyTheme()
        
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

        updateGridVisibility()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .appSettingsDidChange, object: nil)
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
        let angleDegrees = abs(currentFrame.camera.eulerAngles.x) * 180.0 / .pi
        validateMeasurement(distanceMeters: distanceMeters)
        recordMeasurement(distanceMeters: distanceMeters, heightMeters: realHeightMeters, confidence: confidence)
        
        // Update UI
        DispatchQueue.main.async {
            self.updateInfoDisplay(distanceMeters: distanceMeters, confidence: confidence, angleDegrees: angleDegrees)
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

    private func formatDistanceLabel(distanceMeters: Float, confidence: Float, angleDegrees: Float) -> String {
        let feet = distanceMeters * 3.28084
        let confidenceText = String(format: "Confidence: %.0f%%", confidence * 100)
        let angleText = String(format: "Angle: %.0f°", angleDegrees)
        switch AppSettings.shared.displayUnit {
        case .meters:
            return String(format: "Distance: %.2f meters\n%@ • %@", distanceMeters, confidenceText, angleText)
        case .feet:
            return String(format: "Distance: %.1f ft\n%@ • %@", feet, confidenceText, angleText)
        case .both:
            return String(format: "Distance: %.2f meters (%.1f ft)\n%@ • %@", distanceMeters, feet, confidenceText, angleText)
        }
    }

    private func updateInfoDisplay(distanceMeters: Float, confidence: Float, angleDegrees: Float) {
        lastDistanceMeters = distanceMeters
        lastConfidence = confidence
        lastAngleDegrees = angleDegrees
        UIView.transition(with: infoLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.infoLabel.text = self.formatDistanceLabel(distanceMeters: distanceMeters, confidence: confidence, angleDegrees: angleDegrees)
        }
        confidenceBar.setProgress(confidence, animated: true)
        applyDistanceColor(distanceMeters: distanceMeters)
    }

    @objc private func handleSettingsChange() {
        applyTheme()
        updateGridVisibility()
        if let distance = lastDistanceMeters,
           let confidence = lastConfidence,
           let angle = lastAngleDegrees {
            updateInfoDisplay(distanceMeters: distance, confidence: confidence, angleDegrees: angle)
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

        Developer:
        Oleg Bourdo — https://www.linkedin.com/in/oleg-bourdo-8a2360139/
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

    @objc func autoDetectHuman() {
        guard let frame = sceneView.session.currentFrame else { return }

        let request = VNDetectHumanRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                self.presentSimpleAlert(title: "Auto Detect Failed", message: error.localizedDescription)
                return
            }

            // VNDetectHumanRectanglesRequest returns VNDetectedObjectObservation in iOS 13+
            guard let observation = (request.results as? [VNDetectedObjectObservation])?.first else {
                self.presentSimpleAlert(title: "No Person Found", message: "Try again with a clearer view of the person.")
                return
            }

            DispatchQueue.main.async {
                self.applyDetectedBoundingBox(observation.boundingBox, frame: frame)
            }
        }
        // Note: maximumObservations is not available in iOS 13, so we just use the first result

        let handler = VNImageRequestHandler(
            cvPixelBuffer: frame.capturedImage,
            orientation: cgImageOrientation(),
            options: [:]
        )
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.presentSimpleAlert(title: "Auto Detect Failed", message: error.localizedDescription)
                }
            }
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

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.5
        scale.toValue = 1.0
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.0
        fade.toValue = 1.0
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 0.2
        shape.add(group, forKey: "appear")
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
        rectLayer?.strokeEnd = 0
        if let layer = rectLayer {
            sceneView.layer.addSublayer(layer)
            let draw = CABasicAnimation(keyPath: "strokeEnd")
            draw.fromValue = 0
            draw.toValue = 1
            draw.duration = 0.25
            layer.add(draw, forKey: "drawLine")
            layer.strokeEnd = 1
        }
    }
    
    // MARK: - UI Setup (Boilerplate)
    func setupUI() {
        // AR Scene View
        sceneView = ARSCNView(frame: self.view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(sceneView)
        
        // Info Label + Blur
        infoBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
        infoBlurView.translatesAutoresizingMaskIntoConstraints = false
        infoBlurView.layer.cornerRadius = 12
        infoBlurView.clipsToBounds = true
        self.view.addSubview(infoBlurView)

        infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.backgroundColor = .clear
        infoLabel.textColor = .label
        infoLabel.textAlignment = .center
        infoLabel.text = "Tap top of object"
        infoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        infoLabel.numberOfLines = 0
        infoBlurView.contentView.addSubview(infoLabel)

        confidenceBar = UIProgressView(progressViewStyle: .default)
        confidenceBar.translatesAutoresizingMaskIntoConstraints = false
        confidenceBar.progressTintColor = UIColor.systemGreen
        confidenceBar.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        infoBlurView.contentView.addSubview(confidenceBar)
        
        // Reset Button
        resetButton = UIButton(type: .system)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.backgroundColor = UIColor.systemBlue
        configureIconButton(resetButton, title: "Reset", symbolName: "arrow.counterclockwise")
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetMeasurement), for: .touchUpInside)
        self.view.addSubview(resetButton)

        // Undo Button
        undoButton = UIButton(type: .system)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.backgroundColor = UIColor.systemOrange
        configureIconButton(undoButton, title: "Undo", symbolName: "arrow.uturn.backward")
        undoButton.setTitleColor(.white, for: .normal)
        undoButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        undoButton.layer.cornerRadius = 10
        undoButton.addTarget(self, action: #selector(undoLastTap), for: .touchUpInside)
        self.view.addSubview(undoButton)

        // Diagnostics Button
        diagnosticsButton = UIButton(type: .system)
        diagnosticsButton.translatesAutoresizingMaskIntoConstraints = false
        diagnosticsButton.backgroundColor = UIColor.systemGray
        configureIconButton(diagnosticsButton, title: "Diagnostics", symbolName: "wrench.and.screwdriver")
        diagnosticsButton.setTitleColor(.white, for: .normal)
        diagnosticsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        diagnosticsButton.layer.cornerRadius = 10
        diagnosticsButton.addTarget(self, action: #selector(showDiagnostics), for: .touchUpInside)
        self.view.addSubview(diagnosticsButton)

        // History Button
        historyButton = UIButton(type: .system)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.backgroundColor = UIColor.systemIndigo
        configureIconButton(historyButton, title: "History", symbolName: "clock.arrow.circlepath")
        historyButton.setTitleColor(.white, for: .normal)
        historyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        historyButton.layer.cornerRadius = 10
        historyButton.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
        self.view.addSubview(historyButton)

        // Settings Button
        settingsButton = UIButton(type: .system)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.backgroundColor = UIColor.systemPurple
        configureIconButton(settingsButton, title: "Settings", symbolName: "gearshape")
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        settingsButton.layer.cornerRadius = 10
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        self.view.addSubview(settingsButton)

        // Auto Detect Button
        autoDetectButton = UIButton(type: .system)
        autoDetectButton.translatesAutoresizingMaskIntoConstraints = false
        autoDetectButton.backgroundColor = UIColor.systemGreen
        configureIconButton(autoDetectButton, title: "Auto", symbolName: "person.crop.rectangle")
        autoDetectButton.setTitleColor(.white, for: .normal)
        autoDetectButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        autoDetectButton.layer.cornerRadius = 10
        autoDetectButton.addTarget(self, action: #selector(autoDetectHuman), for: .touchUpInside)
        self.view.addSubview(autoDetectButton)

        // Help Button
        helpButton = UIButton(type: .system)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.backgroundColor = UIColor.systemTeal
        configureIconButton(helpButton, title: "Help", symbolName: "questionmark.circle")
        helpButton.setTitleColor(.white, for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        helpButton.layer.cornerRadius = 10
        helpButton.addTarget(self, action: #selector(showHelp), for: .touchUpInside)
        self.view.addSubview(helpButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            infoBlurView.topAnchor.constraint(equalTo: helpButton.bottomAnchor, constant: 12),
            infoBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            infoLabel.topAnchor.constraint(equalTo: infoBlurView.contentView.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: infoBlurView.contentView.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: infoBlurView.contentView.trailingAnchor, constant: -12),

            confidenceBar.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 8),
            confidenceBar.leadingAnchor.constraint(equalTo: infoBlurView.contentView.leadingAnchor, constant: 12),
            confidenceBar.trailingAnchor.constraint(equalTo: infoBlurView.contentView.trailingAnchor, constant: -12),
            confidenceBar.bottomAnchor.constraint(equalTo: infoBlurView.contentView.bottomAnchor, constant: -10),
            
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

            autoDetectButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 8),
            autoDetectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            autoDetectButton.widthAnchor.constraint(equalToConstant: 90),
            autoDetectButton.heightAnchor.constraint(equalToConstant: 36),

            helpButton.topAnchor.constraint(equalTo: diagnosticsButton.bottomAnchor, constant: 8),
            helpButton.trailingAnchor.constraint(equalTo: diagnosticsButton.trailingAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 110),
            helpButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        applyButtonStyles()
        setupOverlays()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateOverlayPaths()
        updateGradientFrames()
    }

    private func setupOverlays() {
        crosshairLayer.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor
        crosshairLayer.lineWidth = 1.0
        crosshairLayer.fillColor = UIColor.clear.cgColor
        sceneView.layer.addSublayer(crosshairLayer)

        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.15).cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.fillColor = UIColor.clear.cgColor
        sceneView.layer.addSublayer(gridLayer)
    }

    private func updateOverlayPaths() {
        let bounds = sceneView.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let crosshair = UIBezierPath()
        crosshair.move(to: CGPoint(x: center.x - 16, y: center.y))
        crosshair.addLine(to: CGPoint(x: center.x + 16, y: center.y))
        crosshair.move(to: CGPoint(x: center.x, y: center.y - 16))
        crosshair.addLine(to: CGPoint(x: center.x, y: center.y + 16))
        crosshairLayer.path = crosshair.cgPath

        let grid = UIBezierPath()
        let thirdW = bounds.width / 3
        let thirdH = bounds.height / 3
        for i in 1...2 {
            let x = CGFloat(i) * thirdW
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: bounds.height))
            let y = CGFloat(i) * thirdH
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        gridLayer.path = grid.cgPath
    }

    private func updateGridVisibility() {
        gridLayer.isHidden = !AppSettings.shared.showGridOverlay
    }

    private func applyButtonStyles() {
        [resetButton, undoButton, diagnosticsButton, helpButton, historyButton, settingsButton, autoDetectButton].forEach {
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.2
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
            $0.layer.shadowRadius = 4
        }
    }

    private func updateGradientFrames() {
        [resetButton, undoButton, diagnosticsButton, helpButton, historyButton, settingsButton, autoDetectButton].forEach {
            applyGradient(to: $0)
        }
    }

    private func applyGradient(to button: UIButton) {
        let gradientName = "gradientLayer"
        button.layer.sublayers?.removeAll(where: { $0.name == gradientName })
        let gradient = CAGradientLayer()
        gradient.name = gradientName
        gradient.frame = button.bounds
        gradient.cornerRadius = button.layer.cornerRadius
        gradient.colors = [
            button.backgroundColor?.withAlphaComponent(0.9).cgColor ?? UIColor.systemBlue.cgColor,
            button.backgroundColor?.withAlphaComponent(1.0).cgColor ?? UIColor.systemTeal.cgColor
        ]
        button.layer.insertSublayer(gradient, at: 0)
    }

    private func configureIconButton(_ button: UIButton, title: String, symbolName: String) {
        let image = UIImage(systemName: symbolName)
        button.setImage(image, for: .normal)
        button.setTitle(" " + title, for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }

    private func applyTheme() {
        switch AppSettings.shared.theme {
        case .system:
            overrideUserInterfaceStyle = .unspecified
        case .light:
            overrideUserInterfaceStyle = .light
        case .dark:
            overrideUserInterfaceStyle = .dark
        }
    }

    private func applyDistanceColor(distanceMeters: Float) {
        let color: UIColor
        if distanceMeters < 3.0 {
            color = .systemGreen
        } else if distanceMeters < 10.0 {
            color = .systemYellow
        } else {
            color = .systemRed
        }
        infoLabel.textColor = color
        confidenceBar.progressTintColor = color
    }

    private func applyDetectedBoundingBox(_ bbox: CGRect, frame: ARFrame) {
        // Reset current measurement visuals
        resetMeasurement()

        let topNormalized = CGPoint(x: bbox.midX, y: bbox.maxY)
        let bottomNormalized = CGPoint(x: bbox.midX, y: bbox.minY)

        let topPoint = convertNormalizedPointToView(topNormalized, frame: frame)
        let bottomPoint = convertNormalizedPointToView(bottomNormalized, frame: frame)

        startPoint = topPoint
        endPoint = bottomPoint

        drawMarker(at: topPoint, isStart: true)
        drawMarker(at: bottomPoint, isStart: false)
        drawLine()

        askForObjectHeight()
    }

    private func convertNormalizedPointToView(_ point: CGPoint, frame: ARFrame) -> CGPoint {
        // Vision bounding box uses normalized coordinates with origin at bottom-left.
        let normalized = CGPoint(x: point.x, y: 1.0 - point.y)
        let interfaceOrientation = view.window?.windowScene?.interfaceOrientation ?? .portrait
        let transform = frame.displayTransform(for: interfaceOrientation, viewportSize: view.bounds.size)
        let transformed = normalized.applying(transform)
        return CGPoint(x: transformed.x * view.bounds.width, y: transformed.y * view.bounds.height)
    }

    private func cgImageOrientation() -> CGImagePropertyOrientation {
        let orientation = view.window?.windowScene?.interfaceOrientation ?? .portrait
        switch orientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }

    private func presentSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
}
