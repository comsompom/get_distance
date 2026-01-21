import UIKit

class HistoryViewController: UITableViewController {

    private(set) var measurements: [Measurement]
    var onUpdate: (([Measurement]) -> Void)?
    private let statsLabel = UILabel()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(measurements: [Measurement]) {
        self.measurements = measurements
        super.init(style: .insetGrouped)
        title = "Measurement History"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        setupHeader()
        setupNavigation()
        refreshStats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshStats()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderLayout()
    }

    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(clearAllTapped))
    }

    private func setupHeader() {
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.numberOfLines = 0
        statsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statsLabel.textColor = .secondaryLabel

        let header = UIView()
        header.addSubview(statsLabel)

        NSLayoutConstraint.activate([
            statsLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            statsLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            statsLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12)
        ])

        tableView.tableHeaderView = header
        updateHeaderLayout()
    }

    private func updateHeaderLayout() {
        guard let header = tableView.tableHeaderView else { return }
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = header.systemLayoutSizeFitting(targetSize)
        if header.frame.size.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
    }

    private func refreshStats() {
        guard !measurements.isEmpty else {
            statsLabel.text = "No measurements yet."
            return
        }

        let distances = measurements.map { $0.distanceMeters }
        let avg = distances.reduce(0, +) / Float(distances.count)
        let minVal = distances.min() ?? 0
        let maxVal = distances.max() ?? 0

        statsLabel.text = String(format: "Count: %d  •  Avg: %.2fm  •  Min: %.2fm  •  Max: %.2fm",
                                 distances.count, avg, minVal, maxVal)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func clearAllTapped() {
        measurements.removeAll()
        onUpdate?(measurements)
        tableView.reloadData()
        refreshStats()
    }

    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return measurements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let measurement = measurements[indexPath.row]
        let timestamp = dateFormatter.string(from: measurement.timestamp)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = formatMeasurementText(measurement: measurement, timestamp: timestamp)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let measurement = measurements[indexPath.row]

        let actionSheet = UIAlertController(title: "Measurement", message: "Choose an action.", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            self?.shareMeasurement(measurement)
        })
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteMeasurement(at: indexPath)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }

        present(actionSheet, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteMeasurement(at: indexPath)
        }
    }

    private func deleteMeasurement(at indexPath: IndexPath) {
        measurements.remove(at: indexPath.row)
        onUpdate?(measurements)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        refreshStats()
    }

    private func shareMeasurement(_ measurement: Measurement) {
        let text = formatMeasurementShareText(measurement: measurement)
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        present(activity, animated: true)
    }

    private func formatMeasurementText(measurement: Measurement, timestamp: String) -> String {
        let feet = measurement.distanceMeters * 3.28084
        let heightFeet = measurement.heightMeters * 3.28084
        switch AppSettings.shared.displayUnit {
        case .meters:
            return String(
                format: "%.2fm • H=%.2fm • %.0f%%\n%@",
                measurement.distanceMeters,
                measurement.heightMeters,
                measurement.confidence * 100,
                timestamp
            )
        case .feet:
            return String(
                format: "%.1fft • H=%.1fft • %.0f%%\n%@",
                feet,
                heightFeet,
                measurement.confidence * 100,
                timestamp
            )
        case .both:
            return String(
                format: "%.2fm (%.1fft) • H=%.2fm (%.1fft) • %.0f%%\n%@",
                measurement.distanceMeters,
                feet,
                measurement.heightMeters,
                heightFeet,
                measurement.confidence * 100,
                timestamp
            )
        }
    }

    private func formatMeasurementShareText(measurement: Measurement) -> String {
        let feet = measurement.distanceMeters * 3.28084
        let heightFeet = measurement.heightMeters * 3.28084
        let time = dateFormatter.string(from: measurement.timestamp)
        switch AppSettings.shared.displayUnit {
        case .meters:
            return String(
                format: "TargetLock Measurement\nDistance: %.2fm\nHeight: %.2fm\nConfidence: %.0f%%\nTime: %@",
                measurement.distanceMeters,
                measurement.heightMeters,
                measurement.confidence * 100,
                time
            )
        case .feet:
            return String(
                format: "TargetLock Measurement\nDistance: %.1fft\nHeight: %.1fft\nConfidence: %.0f%%\nTime: %@",
                feet,
                heightFeet,
                measurement.confidence * 100,
                time
            )
        case .both:
            return String(
                format: "TargetLock Measurement\nDistance: %.2fm (%.1fft)\nHeight: %.2fm (%.1fft)\nConfidence: %.0f%%\nTime: %@",
                measurement.distanceMeters,
                feet,
                measurement.heightMeters,
                heightFeet,
                measurement.confidence * 100,
                time
            )
        }
    }
}
