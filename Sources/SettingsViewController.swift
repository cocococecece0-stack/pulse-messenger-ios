
import UIKit

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ещё"
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        view.addSubview(tableView)
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
    }

    func numberOfSections(in tableView: UITableView) -> Int { 6 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return ThemeID.allCases.count
        case 2: return 5
        case 3: return 5
        case 4: return 2
        case 5: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Профиль"
        case 1: return "Оформление"
        case 2: return "Поведение"
        case 3: return "Инструменты"
        case 4: return "Данные"
        case 5: return "О приложении"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        let s = Storage.shared.state
        let p = ThemeManager.shared.current.palette
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        cell.imageView?.image = nil
        cell.textLabel?.textColor = p.text
        cell.detailTextLabel?.textColor = p.text2
        cell.backgroundColor = p.surface
        cell.accessoryType = .none
        cell.accessoryView = nil
        cell.selectionStyle = .default

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = s.me.name
            cell.detailTextLabel?.text = s.me.handle
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = AvatarFactory.avatar(name: s.me.name, seed: s.me.avatarSeed,
                                                         size: CGSize(width: 80, height: 80))
            cell.imageView?.layer.cornerRadius = 20
            cell.imageView?.layer.masksToBounds = true
        case 1:
            let theme = ThemeID.allCases[indexPath.row]
            cell.textLabel?.text = theme.title
            cell.detailTextLabel?.text = theme.subtitle
            cell.accessoryType = ThemeManager.shared.currentID == theme ? .checkmark : .none
        case 2:
            let titles = ["Уведомления", "Хаптики", "Показывать статус", "Отчёты о прочтении", "Компактный режим"]
            cell.textLabel?.text = titles[indexPath.row]
            let toggle = UISwitch()
            toggle.tag = indexPath.row
            toggle.isOn = [s.notificationsOn, s.hapticsOn, s.showOnline, s.readReceipts, s.compactMode][indexPath.row]
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
            toggle.onTintColor = p.accent
            cell.accessoryView = toggle
        case 3:
            let items = [
                ("Обзор сервисов", "compass.circle.fill"),
                ("Статистика", "chart.bar.fill"),
                ("Уведомления", "bell.badge.fill"),
                ("Сохранённое", "pin.fill"),
                ("Медиатека", "photo.stack.fill")
            ]
            cell.textLabel?.text = items[indexPath.row].0
            cell.imageView?.image = UIImage(systemName: items[indexPath.row].1)?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = p.accent
            cell.accessoryType = .disclosureIndicator
        case 4:
            cell.textLabel?.text = indexPath.row == 0 ? "Экспортировать данные" : "Сбросить демо-данные"
            cell.imageView?.image = UIImage(systemName: indexPath.row == 0 ? "square.and.arrow.up.fill" : "arrow.counterclockwise.circle.fill")?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = p.accent2
            cell.accessoryType = .disclosureIndicator
        default:
            cell.textLabel?.text = "Как это сделано"
            cell.imageView?.image = UIImage(systemName: "info.circle.fill")?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = p.accent
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        Feedback.shared.tap()
        switch indexPath.section {
        case 0:
            navigationController?.pushViewController(ProfileViewController(user: Storage.shared.state.me), animated: true)
        case 1:
            let theme = ThemeID.allCases[indexPath.row]
            ThemeManager.shared.set(theme)
            Storage.shared.update { $0.themeID = theme.rawValue }
            tableView.reloadData()
        case 3:
            let controllers: [UIViewController] = [
                DiscoverViewController(), StatsViewController(),
                NotificationsViewController(), SavedMessagesViewController(),
                MediaGalleryViewController()
            ]
            navigationController?.pushViewController(controllers[indexPath.row], animated: true)
        case 4:
            if indexPath.row == 0 {
                let activity = UIActivityViewController(activityItems: [Storage.shared.exportData()],
                                                        applicationActivities: nil)
                activity.popoverPresentationController?.sourceView = tableView
                present(activity, animated: true)
            } else {
                let alert = UIAlertController(title: "Сбросить?", message: "Весь демо-контент будет восстановлен.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                alert.addAction(UIAlertAction(title: "Сбросить", style: .destructive) { [weak self] _ in
                    Storage.shared.resetDemo()
                    self?.tableView.reloadData()
                    Feedback.shared.warning()
                })
                present(alert, animated: true)
            }
        case 5:
            navigationController?.pushViewController(AboutWebViewController(), animated: true)
        default:
            break
        }
    }

    @objc private func toggleChanged(_ toggle: UISwitch) {
        Feedback.shared.click()
        Storage.shared.update { s in
            switch toggle.tag {
            case 0: s.notificationsOn = toggle.isOn
            case 1: s.hapticsOn = toggle.isOn
            case 2: s.showOnline = toggle.isOn
            case 3: s.readReceipts = toggle.isOn
            case 4: s.compactMode = toggle.isOn
            default: break
            }
        }
    }
}
