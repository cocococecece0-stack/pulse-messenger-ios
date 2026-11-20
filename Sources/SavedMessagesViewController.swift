
import UIKit

final class SavedMessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [Message] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Сохранённое"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"), style: .plain,
            target: self, action: #selector(saveLast))

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SavedCell")
        tableView.rowHeight = 76
        view.addSubview(tableView)

        reload()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle), name: .pulseThemeChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        items = Storage.shared.state.messages.filter { $0.pinned }
            .sorted { $0.timestamp > $1.timestamp }
        tableView.reloadData()
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
    }

    @objc private func saveLast() {
        guard let last = Storage.shared.state.messages.filter({ $0.outgoing }).last else {
            Feedback.shared.warning()
            return
        }
        Storage.shared.update { s in
            if let i = s.messages.firstIndex(where: { $0.id == last.id }) { s.messages[i].pinned = true }
        }
        Feedback.shared.success()
        reload()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        items.isEmpty ? "Нажмите +, чтобы сохранить последнее сообщение" : "Закреплённые сообщения"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCell", for: indexPath)
        let message = items[indexPath.row]
        let p = ThemeManager.shared.current.palette
        let chat = Storage.shared.state.chats.first { $0.id == message.chatID }

        cell.textLabel?.text = message.text
        cell.textLabel?.textColor = p.text
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        cell.detailTextLabel?.text = "\((chat?.title ?? "Чат")) · \(message.timestamp.relativeString)"
        cell.detailTextLabel?.textColor = p.text2
        cell.imageView?.image = UIImage(systemName: "pin.fill")?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.tintColor = p.accent
        cell.backgroundColor = p.surface
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = items[indexPath.row]
        guard let chat = Storage.shared.chat(withID: message.chatID) else { return }
        let vc = ChatViewController(chatID: chat.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let message = items[indexPath.row]
        let unpin = UIContextualAction(style: .destructive, title: "Открепить") { _, _, done in
            Storage.shared.update { s in
                if let i = s.messages.firstIndex(where: { $0.id == message.id }) { s.messages[i].pinned = false }
            }
            Feedback.shared.click()
            self.reload()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [unpin])
    }
}
