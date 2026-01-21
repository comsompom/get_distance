import UIKit

class SettingsViewController: UITableViewController {

    private let units = [
        (title: "Meters", value: DisplayUnit.meters),
        (title: "Feet", value: DisplayUnit.feet),
        (title: "Both", value: DisplayUnit.both)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(closeTapped))
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return units.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        let unit = units[indexPath.row]
        cell.textLabel?.text = unit.title
        cell.accessoryType = (AppSettings.shared.displayUnit == unit.value) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let unit = units[indexPath.row]
        AppSettings.shared.displayUnit = unit.value
        tableView.reloadData()
    }
}
