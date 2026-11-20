
import UIKit

final class NotificationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private struct Item {
        let icon: String
        let title: String
        let body: String
        let time: String
        let chatID: String?
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Уведомления"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Прочитать", style: .plain, target: self, action: #selector(markAllRead))

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.rowHeight = 78
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
        let s = Storage.shared.state
        var result: [Item] = []
        for chat in s.chats.filter({ $0.unread > 0 }).sorted(by: {
            ($0.lastMessage?.timestamp ?? .distantPast) > ($1.lastMessage?.timestamp ?? .distantPast)
        }) {
            result.append(Item(icon: "bubble.left.and.bubble.right.fill",
                               title: chat.title,
                               body: chat.subtitle,
                               time: chat.lastMessage?.timestamp.relativeString ?? "сейчас",
                               chatID: chat.id))
        }
        for story in s.stories.filter({ !$0.seen }).prefix(4) {
            let user = Storage.shared.user(withID: story.userID)
            result.append(Item(icon: "play.circle.fill",
                               title: "\(user?.name ?? "Друг") опубликовал историю",
                               body: story.caption,
                               time: story.timestamp.relativeString,
                               chatID: nil))
        }
        for call in s.calls.filter({ $0.missed }).prefix(3) {
            let user = Storage.shared.user(withID: call.userID)
            result.append(Item(icon: "phone.down.fill",
                               title: "Пропущенный звонок",
                               body: user?.name ?? "Неизвестный",
                               time: call.timestamp.relativeString,
                               chatID: nil))
        }
        items = result
        tableView.reloadData()
    }

    @objc private func markAllRead() {
        Storage.shared.update { s in
            for i in s.chats.indices { s.chats[i].unread = 0 }
            for i in s.stories.indices { s.stories[i].seen = true }
        }
        Feedback.shared.success()
        reload()
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        items.isEmpty ? "Новых уведомлений нет" : "\(items.count) событий"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath)
        let item = items[indexPath.row]
        let p = ThemeManager.shared.current.palette

        cell.imageView?.image = UIImage(systemName: item.icon)?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.tintColor = p.accent
        cell.imageView?.layer.cornerRadius = 18
        cell.imageView?.layer.masksToBounds = true

        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = p.text
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        cell.detailTextLabel?.text = "\(item.body) · \(item.time)"
        cell.detailTextLabel?.textColor = p.text2
        cell.detailTextLabel?.numberOfLines = 2
        cell.backgroundColor = p.surface
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        guard let chatID = item.chatID, let chat = Storage.shared.chat(withID: chatID) else {
            Feedback.shared.tap()
            return
        }
        let vc = ChatViewController(chatID: chat.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
