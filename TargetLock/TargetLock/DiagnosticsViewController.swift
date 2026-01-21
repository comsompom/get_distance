import UIKit
import ARKit

class DiagnosticsViewController: UIViewController {

    private weak var session: ARSession?
    private let infoLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)

    init(session: ARSession?) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        refreshDiagnostics()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDiagnostics()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func refreshTapped() {
        refreshDiagnostics()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Diagnostics"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center

        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        infoLabel.textColor = .label

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [refreshButton, closeButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually

        view.addSubview(titleLabel)
        view.addSubview(infoLabel)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func refreshDiagnostics() {
        let device = UIDevice.current
        let arSupported = ARWorldTrackingConfiguration.isSupported
        let frame = session?.currentFrame
        let intrinsics = frame?.camera.intrinsics
        let fx = intrinsics?.columns.0.x
        let fy = intrinsics?.columns.1.y
        let cx = intrinsics?.columns.2.x
        let cy = intrinsics?.columns.2.y

        let intrinsicsText: String
        if let fx, let fy, let cx, let cy {
            intrinsicsText = String(
                format: "Intrinsics (px)\nfx: %.2f\nfy: %.2f\ncx: %.2f\ncy: %.2f",
                fx, fy, cx, cy
            )
        } else {
            intrinsicsText = "Intrinsics: unavailable"
        }

        infoLabel.text = """
        ARKit supported: \(arSupported ? "yes" : "no")
        Device model: \(device.model)
        System: \(device.systemName) \(device.systemVersion)

        \(intrinsicsText)
        """
    }
}
