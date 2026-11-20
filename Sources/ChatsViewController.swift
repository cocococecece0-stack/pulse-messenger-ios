
import UIKit

final class ChatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()
    private let chipScrollView = UIScrollView()
    private var chips: [UIButton] = []
    private var visibleChats: [Chat] = []
    private var folder: Folder = .all
    private var query = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Чаты"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"), style: .plain,
            target: self, action: #selector(compose))
        buildHeader()
        buildTable()
        applyFilter()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyFilter()
        tableView.reloadData()
    }

    private func buildHeader() {
        let header = UIView()
        header.backgroundColor = .clear

        searchBar.placeholder = "Поиск по чатам и сообщениям"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(searchBar)

        chipScrollView.showsHorizontalScrollIndicator = false
        chipScrollView.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(chipScrollView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: header.topAnchor, constant: 2),
            searchBar.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 48),

            chipScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 2),
            chipScrollView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            chipScrollView.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            chipScrollView.heightAnchor.constraint(equalToConstant: 44)
        ])

        var lastX: CGFloat = 14
        for f in Folder.allCases {
            let button = UIButton(type: .system)
            button.setTitle(f.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            button.layer.cornerRadius = 15
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            button.tag = Folder.allCases.firstIndex(of: f) ?? 0
            button.sizeToFit()
            button.frame.origin = CGPoint(x: lastX, y: 6)
            button.frame.size.height = 30
            lastX += button.frame.width + 8
            chipScrollView.addSubview(button)
            chips.append(button)
        }
        chipScrollView.contentSize = CGSize(width: lastX + 10, height: 44)

        header.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 102)
        tableView.tableHeaderView = header
    }

    private func buildTable() {
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.reuse)
        tableView.separatorStyle = .none
        tableView.rowHeight = 76
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        view.addSubview(tableView)

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
        searchBar.tintColor = p.accent
        for (index, button) in chips.enumerated() {
            let f = Folder.allCases[index]
            button.backgroundColor = f == folder ? p.accent : p.surface
            button.setTitleColor(f == folder ? .white : p.text2, for: .normal)
        }
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard Folder.allCases.indices.contains(sender.tag) else { return }
        folder = Folder.allCases[sender.tag]
        Feedback.shared.tap()
        applyFilter()
        applyStyle()
    }

    @objc private func refreshData() {
        Feedback.shared.click()
        applyFilter()
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query = searchText
        applyFilter()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    private func applyFilter() {
        var result = Storage.shared.state.chats.filter { chat in
            switch folder {
            case .archived: return chat.archived
            default: return !chat.archived
            }
        }
        switch folder {
        case .unread: result = result.filter { $0.unread > 0 }
        case .groups: result = result.filter { $0.kind == .group }
        case .channels: result = result.filter { $0.kind == .channel }
        case .favorites: result = result.filter { Storage.shared.state.favorites.contains($0.id) }
        default: break
        }
        if !query.isEmpty {
            let q = query.lowercased()
            result = result.filter { chat in
                chat.title.lowercased().contains(q) ||
                (chat.lastMessage?.text.lowercased().contains(q) ?? false)
            }
        }
        result.sort { a, b in
            if a.pinned != b.pinned { return a.pinned }
            return (a.lastMessage?.timestamp ?? .distantPast) > (b.lastMessage?.timestamp ?? .distantPast)
        }
        visibleChats = result
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleChats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuse, for: indexPath) as! ChatCell
        cell.configure(visibleChats[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Feedback.shared.tap()
        open(visibleChats[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let chat = visibleChats[indexPath.row]
        let mute = UIContextualAction(style: .normal, title: chat.muted ? "Вкл. звук" : "Без звука") { _, _, done in
            Storage.shared.update { s in
                if let i = s.chats.firstIndex(where: { $0.id == chat.id }) { s.chats[i].muted.toggle() }
            }
            Feedback.shared.click()
            self.applyFilter()
            self.tableView.reloadData()
            done(true)
        }
        mute.backgroundColor = .systemOrange

        let archive = UIContextualAction(style: .normal, title: chat.archived ? "Вернуть" : "Архив") { _, _, done in
            Storage.shared.update { s in
                if let i = s.chats.firstIndex(where: { $0.id == chat.id }) { s.chats[i].archived.toggle() }
            }
            Feedback.shared.click()
            self.applyFilter()
            self.tableView.reloadData()
            done(true)
        }
        archive.backgroundColor = .systemBlue

        let remove = UIContextualAction(style: .destructive, title: "Удалить") { _, _, done in
            Storage.shared.update { s in
                s.chats.removeAll { $0.id == chat.id }
                s.messages.removeAll { $0.chatID == chat.id }
            }
            Feedback.shared.warning()
            self.applyFilter()
            self.tableView.reloadData()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [remove, archive, mute])
    }

    private func open(_ chat: Chat) {
        let vc = ChatViewController(chatID: chat.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func compose() {
        let sheet = UIAlertController(title: "Новый чат", message: "Выберите контакт", preferredStyle: .actionSheet)
        for user in Storage.shared.state.users.prefix(12) {
            sheet.addAction(UIAlertAction(title: user.name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                var chatID = ""
                if let existing = Storage.shared.state.chats.first(where: {
                    $0.kind == .direct && $0.memberIDs.contains(user.id)
                }) {
                    chatID = existing.id
                } else {
                    let new = Chat(id: "new_\(UUID().uuidString)", title: user.name,
                                   avatarSeed: user.avatarSeed, kind: .direct, pinned: false,
                                   muted: false, archived: false, unread: 0, draft: "", typing: false,
                                   lastMessage: nil, memberIDs: ["me", user.id],
                                   about: "Новый чат", verified: false)
                    chatID = new.id
                    Storage.shared.update { $0.chats.append(new) }
                }
                if let chat = Storage.shared.chat(withID: chatID) { self.open(chat) }
            })
        }
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }
}
