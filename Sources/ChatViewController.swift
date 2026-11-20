
import UIKit

final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, InputBarViewDelegate {
    private let chatID: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = InputBarView()
    private let titleAvatar = UIImageView(frame: CGRect(x: 0, y: 2, width: 40, height: 40))
    private let titleName = UILabel(frame: CGRect(x: 48, y: 3, width: 180, height: 20))
    private let titleStatus = UILabel(frame: CGRect(x: 48, y: 22, width: 180, height: 16))
    private var inputBottom: NSLayoutConstraint!
    private var messages: [Message] = []
    private var replyTo: String?

    init(chatID: String) {
        self.chatID = chatID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        chatID = ""
        super.init(coder: coder)
    }

    private var chat: Chat? { Storage.shared.chat(withID: chatID) }

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        Storage.shared.update { s in
            if let i = s.chats.firstIndex(where: { $0.id == self.chatID }) { s.chats[i].unread = 0 }
        }
        buildTitle()
        buildTable()
        buildInput()
        reload(animated: false)
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    private func buildTitle() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 236, height: 44))
        titleAvatar.layer.cornerRadius = 20
        titleAvatar.layer.masksToBounds = true
        titleName.font = .systemFont(ofSize: 15, weight: .semibold)
        titleStatus.font = .systemFont(ofSize: 11, weight: .medium)
        container.addSubview(titleAvatar)
        container.addSubview(titleName)
        container.addSubview(titleStatus)
        navigationItem.titleView = container

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "video.fill"), style: .plain,
                            target: self, action: #selector(videoCall)),
            UIBarButtonItem(image: UIImage(systemName: "phone.fill"), style: .plain,
                            target: self, action: #selector(voiceCall))
        ]
        updateTitle()
    }

    private func updateTitle() {
        guard let chat = chat else { return }
        let p = ThemeManager.shared.current.palette
        titleName.text = chat.title
        titleName.textColor = p.text
        titleAvatar.image = AvatarFactory.avatar(name: chat.title, seed: chat.avatarSeed,
                                                 size: CGSize(width: 80, height: 80))
        if chat.typing {
            titleStatus.text = "печатает…"
            titleStatus.textColor = p.accent
        } else {
            titleStatus.text = chat.kind == .channel ? "\(chat.memberIDs.count) подписчик" :
                (chat.kind == .group ? "\(chat.memberIDs.count) участников" : "был(а) недавно")
            titleStatus.textColor = p.text2
        }
    }

    private func buildTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuse)
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.delegate = self
        view.addSubview(inputBar)

        inputBottom = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottom,
            inputBar.heightAnchor.constraint(equalToConstant: 78)
        ])
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
        updateTitle()
    }

    @objc private func keyboardChanged(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let overlap = view.bounds.height - frame.origin.y
        inputBottom.constant = overlap > 0 ? -overlap : 0
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    private func reload(animated: Bool) {
        messages = Storage.shared.messages(in: chatID)
        tableView.reloadData()
        updateTitle()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let offset = self.tableView.contentSize.height - self.tableView.bounds.height
            if offset > 0 {
                self.tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuse, for: indexPath) as! MessageCell
        cell.configure(messages[indexPath.row])
        let long = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        cell.contentView.gestureRecognizers?.removeAll()
        cell.contentView.addGestureRecognizer(long)
        return cell
    }

    func inputBar(_ bar: InputBarView, didSend text: String) {
        _ = Storage.shared.send(text: text, in: chatID, replyTo: replyTo)
        replyTo = nil
        reload(animated: true)
        simulateTypingAndReply(for: text)
    }

    func inputBarDidTapAttach(_ bar: InputBarView) {
        let sheet = UIAlertController(title: "Прикрепить", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Фото", style: .default) { [weak self] _ in
            self?.sendService(kind: .image, text: "Фото отправлено")
        })
        sheet.addAction(UIAlertAction(title: "Файл", style: .default) { [weak self] _ in
            self?.sendService(kind: .file, text: "Документ.pdf")
        })
        sheet.addAction(UIAlertAction(title: "Геолокация", style: .default) { [weak self] _ in
            self?.sendService(kind: .location, text: "Москва, Тверская 12")
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.sourceView = bar
        present(sheet, animated: true)
    }

    func inputBarDidTapMic(_ bar: InputBarView) {
        sendService(kind: .voice, text: "Голосовое сообщение")
    }

    private func sendService(kind: MessageKind, text: String) {
        let message = Message(id: "svc_\(UUID().uuidString)", chatID: chatID, senderID: "me",
                              text: text, kind: kind, timestamp: Date(), outgoing: true, read: false,
                              edited: false, pinned: false, replyToID: nil, reactions: [], duration: kind == .voice ? 12 : nil,
                              mediaSeed: Int.random(in: 1...9999), fileName: kind == .file ? "Документ.pdf" : nil,
                              fileSize: kind == .file ? "340 КБ" : nil, linkURL: nil, linkTitle: nil)
        Storage.shared.update { s in
            s.messages.append(message)
            if let i = s.chats.firstIndex(where: { $0.id == self.chatID }) { s.chats[i].lastMessage = message }
        }
        Feedback.shared.click()
        reload(animated: true)
    }

    private func simulateTypingAndReply(for text: String) {
        Storage.shared.update { s in
            if let i = s.chats.firstIndex(where: { $0.id == self.chatID }) { s.chats[i].typing = true }
        }
        updateTitle()
        let reply = SmartReply.suggestions(for: text).first ?? "Ок 👌"
        let otherID = chat?.memberIDs.first { $0 != "me" } ?? "u1"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self = self else { return }
            Storage.shared.receive(text: reply, in: self.chatID, from: otherID)
            Feedback.shared.tap()
            self.reload(animated: true)
        }
    }

    @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let cell = gesture.view?.superview as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        let message = messages[indexPath.row]
        let sheet = UIAlertController(title: "Сообщение", message: message.text, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Ответить", style: .default) { [weak self] _ in
            self?.replyTo = message.id
            self?.inputBar.setReply(message.text)
        })
        sheet.addAction(UIAlertAction(title: "Копировать", style: .default) { _ in
            UIPasteboard.general.string = message.text
            Feedback.shared.tap()
        })
        if message.outgoing {
            sheet.addAction(UIAlertAction(title: "Редактировать", style: .default) { [weak self] _ in
                self?.edit(message)
            })
        }
        sheet.addAction(UIAlertAction(title: message.pinned ? "Открепить" : "Закрепить", style: .default) { [weak self] _ in
            Storage.shared.update { s in
                if let i = s.messages.firstIndex(where: { $0.id == message.id }) {
                    s.messages[i].pinned.toggle()
                }
            }
            self?.reload(animated: false)
        })
        sheet.addAction(UIAlertAction(title: "❤️ Реакция", style: .default) { [weak self] _ in
            Storage.shared.update { s in
                if let i = s.messages.firstIndex(where: { $0.id == message.id }) {
                    s.messages[i].reactions.append(Reaction(emoji: "❤️", count: 1))
                }
            }
            Feedback.shared.success()
            self?.reload(animated: false)
        })
        sheet.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            Storage.shared.update { s in s.messages.removeAll { $0.id == message.id } }
            self?.reload(animated: false)
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.sourceView = cell.contentView
        present(sheet, animated: true)
    }

    private func edit(_ message: Message) {
        let alert = UIAlertController(title: "Редактирование", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = message.text }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            Storage.shared.update { s in
                if let i = s.messages.firstIndex(where: { $0.id == message.id }) {
                    s.messages[i].text = text
                    s.messages[i].edited = true
                }
                if let i = s.chats.firstIndex(where: { $0.id == message.chatID }),
                   s.chats[i].lastMessage?.id == message.id {
                    s.chats[i].lastMessage?.text = text
                }
            }
            self?.reload(animated: false)
        })
        present(alert, animated: true)
    }

    @objc private func voiceCall() {
        presentCall(video: false)
    }

    @objc private func videoCall() {
        presentCall(video: true)
    }

    private func presentCall(video: Bool) {
        let userID = chat?.memberIDs.first { $0 != "me" } ?? "u1"
        let user = Storage.shared.user(withID: userID) ?? Storage.shared.state.users[0]
        let call = CallOverlayViewController(user: user, video: video)
        call.modalPresentationStyle = .fullScreen
        present(call, animated: true)
    }
}
