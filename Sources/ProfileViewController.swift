
import UIKit

final class ProfileViewController: UIViewController {
    private let user: PulseUser
    private let scroll = UIScrollView()
    private let content = UIView()
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let bioLabel = UILabel()
    private let statusView = UIView()

    init(user: PulseUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        user = PulseUser(id: "", name: "", handle: "", avatarSeed: 0, online: false,
                         status: "", bio: "", isContact: false)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Профиль"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"), style: .plain,
            target: self, action: #selector(edit))
        build()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    private func build() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor)
        ])

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 60
        avatar.layer.masksToBounds = true
        avatar.layer.borderWidth = 4
        content.addSubview(avatar)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textAlignment = .center
        content.addSubview(nameLabel)

        handleLabel.translatesAutoresizingMaskIntoConstraints = false
        handleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        handleLabel.textAlignment = .center
        content.addSubview(handleLabel)

        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.font = .systemFont(ofSize: 15)
        bioLabel.textAlignment = .center
        bioLabel.numberOfLines = 0
        content.addSubview(bioLabel)

        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.layer.cornerRadius = 18
        content.addSubview(statusView)

        let stats = UIStackView()
        stats.axis = .horizontal
        stats.distribution = .fillEqually
        stats.spacing = 10
        stats.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stats)

        let state = Storage.shared.state
        let items: [(String, String)] = [
            ("\(state.chats.count)", "чатов"),
            ("\(state.messages.count)", "сообщений"),
            ("\(state.stories.count)", "историй"),
            ("\(state.calls.count)", "звонков")
        ]
        for item in items {
            let card = UIView()
            card.layer.cornerRadius = 16
            let value = UILabel()
            value.text = item.0
            value.font = .systemFont(ofSize: 22, weight: .bold)
            value.textAlignment = .center
            value.translatesAutoresizingMaskIntoConstraints = false
            let caption = UILabel()
            caption.text = item.1
            caption.font = .systemFont(ofSize: 11)
            caption.textAlignment = .center
            caption.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(value)
            card.addSubview(caption)
            NSLayoutConstraint.activate([
                value.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                value.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                value.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                caption.topAnchor.constraint(equalTo: value.bottomAnchor, constant: 4),
                caption.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                caption.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                caption.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
            ])
            card.tag = 1
            stats.addArrangedSubview(card)
        }

        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: content.topAnchor, constant: 28),
            avatar.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 120),
            avatar.heightAnchor.constraint(equalToConstant: 120),
            nameLabel.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            handleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            handleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            handleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            statusView.topAnchor.constraint(equalTo: handleLabel.bottomAnchor, constant: 14),
            statusView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            statusView.widthAnchor.constraint(equalToConstant: 120),
            statusView.heightAnchor.constraint(equalToConstant: 34),
            bioLabel.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 18),
            bioLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            bioLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            stats.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 26),
            stats.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stats.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stats.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -40)
        ])

        avatar.image = AvatarFactory.avatar(name: user.name, seed: user.avatarSeed,
                                            size: CGSize(width: 240, height: 240))
        nameLabel.text = user.name
        handleLabel.text = user.handle
        bioLabel.text = user.bio

        let status = UILabel()
        status.text = user.online ? "● в сети" : "○ не в сети"
        status.font = .systemFont(ofSize: 12, weight: .bold)
        status.textAlignment = .center
        status.translatesAutoresizingMaskIntoConstraints = false
        statusView.addSubview(status)
        status.pinToSuperview()
        status.tag = 2
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        content.backgroundColor = .clear
        nameLabel.textColor = p.text
        handleLabel.textColor = p.accent
        bioLabel.textColor = p.text2
        statusView.backgroundColor = p.surface
        avatar.layer.borderColor = p.accent.cgColor
        if let status = statusView.viewWithTag(2) as? UILabel { status.textColor = p.green }
        for view in content.subviews where view.tag == 1 {
            view.backgroundColor = p.surface
            for sub in view.subviews as? [UILabel] ?? [] {
                sub.textColor = sub.font.pointSize > 20 ? p.text : p.text2
            }
        }
    }

    @objc private func edit() {
        let alert = UIAlertController(title: "Редактировать профиль", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = Storage.shared.state.me.name }
        alert.addTextField { $0.text = Storage.shared.state.me.handle }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            let handle = alert.textFields?[1].text ?? Storage.shared.state.me.handle
            Storage.shared.update { s in
                s.me.name = name
                s.me.handle = handle
            }
            self?.navigationController?.popViewController(animated: true)
            Feedback.shared.success()
        })
        present(alert, animated: true)
    }
}
