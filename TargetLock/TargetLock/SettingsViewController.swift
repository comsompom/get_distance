import UIKit

class SettingsViewController: UITableViewController {

    private let units = [
        (title: "Meters", value: DisplayUnit.meters),
        (title: "Feet", value: DisplayUnit.feet),
        (title: "Both", value: DisplayUnit.both)
    ]
    private let themes = [
        (title: "System", value: AppTheme.system),
        (title: "Light", value: AppTheme.light),
        (title: "Dark", value: AppTheme.dark)
    ]
    private let overlayOptions = [
        (title: "Show Grid Overlay", key: "show_grid")
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
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return units.count
        case 1:
            return themes.count
        default:
            return overlayOptions.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        if indexPath.section == 0 {
            let unit = units[indexPath.row]
            cell.textLabel?.text = unit.title
            cell.accessoryType = (AppSettings.shared.displayUnit == unit.value) ? .checkmark : .none
            cell.accessoryView = nil
            return cell
        } else if indexPath.section == 1 {
            let theme = themes[indexPath.row]
            cell.textLabel?.text = theme.title
            cell.accessoryType = (AppSettings.shared.theme == theme.value) ? .checkmark : .none
            cell.accessoryView = nil
            return cell
        } else {
            let option = overlayOptions[indexPath.row]
            cell.textLabel?.text = option.title
            let toggle = UISwitch()
            toggle.isOn = AppSettings.shared.showGridOverlay
            toggle.addTarget(self, action: #selector(gridToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.accessoryType = .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let unit = units[indexPath.row]
            AppSettings.shared.displayUnit = unit.value
        } else if indexPath.section == 1 {
            let theme = themes[indexPath.row]
            AppSettings.shared.theme = theme.value
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Units"
        case 1:
            return "Theme"
        default:
            return "Overlays"
        }
    }

    @objc private func gridToggleChanged(_ sender: UISwitch) {
        AppSettings.shared.showGridOverlay = sender.isOn
    }
}
