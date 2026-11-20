
import UIKit

final class CallsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var calls: [CallRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Звонки"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"), style: .plain,
            target: self, action: #selector(newCall))

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CallCell")
        tableView.rowHeight = 68
        view.addSubview(tableView)

        reload()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
    }

    private func reload() {
        calls = Storage.shared.state.calls.sorted { $0.timestamp > $1.timestamp }
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        calls.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "История звонков"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CallCell", for: indexPath)
        let record = calls[indexPath.row]
        let user = Storage.shared.user(withID: record.userID)
        let name = user?.name ?? "Неизвестный"
        let p = ThemeManager.shared.current.palette

        cell.imageView?.image = AvatarFactory.avatar(name: name, seed: user?.avatarSeed ?? 1,
                                                     size: CGSize(width: 88, height: 88))
        cell.imageView?.layer.cornerRadius = 22
        cell.imageView?.layer.masksToBounds = true
        cell.textLabel?.text = name
        cell.textLabel?.textColor = record.missed ? p.red : p.text
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .semibold)

        let icon = record.missed ? "arrow.down.left.circle.fill" :
            (record.video ? "video.fill" : "phone.fill")
        let duration = record.duration > 0 ? " · \(record.duration / 60) мин" : ""
        cell.detailTextLabel?.text = "\(record.incoming ? "Входящий" : "Исходящий")\(duration)  \(record.timestamp.relativeString)"
        cell.detailTextLabel?.textColor = p.text2
        cell.accessoryView = UIImageView(image: UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate))
        cell.accessoryView?.tintColor = record.missed ? p.red : p.accent
        cell.backgroundColor = .clear
        let bg = UIView()
        bg.backgroundColor = p.surface
        cell.backgroundView = bg
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = calls[indexPath.row]
        guard let user = Storage.shared.user(withID: record.userID) else { return }
        presentCall(user: user, video: record.video)
    }

    @objc private func newCall() {
        let sheet = UIAlertController(title: "Новый звонок", message: "Выберите контакт", preferredStyle: .actionSheet)
        for user in Storage.shared.state.users.prefix(12) {
            sheet.addAction(UIAlertAction(title: user.name, style: .default) { [weak self] _ in
                self?.presentCall(user: user, video: false)
            })
        }
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }

    private func presentCall(user: PulseUser, video: Bool) {
        let overlay = CallOverlayViewController(user: user, video: video)
        overlay.modalPresentationStyle = .fullScreen
        present(overlay, animated: true)
    }
}
