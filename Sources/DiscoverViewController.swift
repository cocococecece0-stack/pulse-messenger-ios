
import UIKit

final class DiscoverViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    private let searchBar = UISearchBar()
    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var cards: [DiscoverCard] = []

    struct DiscoverCard {
        let title: String
        let subtitle: String
        let icon: String
        let seed: Int
        let action: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Обзор"
        build()
        cards = Self.makeCards()
        collection.reloadData()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle), name: .pulseThemeChanged, object: nil)
    }

    private func build() {
        searchBar.placeholder = "Поиск по сервисам"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 30, right: 16)
        collection.collectionViewLayout = layout
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(DiscoverCardCell.self, forCellWithReuseIdentifier: "DiscoverCardCell")
        collection.alwaysBounceVertical = true
        view.addSubview(collection)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            collection.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        collection.backgroundColor = .clear
        searchBar.tintColor = p.accent
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let all = Self.makeCards()
        if searchText.isEmpty { cards = all }
        else {
            let q = searchText.lowercased()
            cards = all.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
        }
        collection.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }

    private static func makeCards() -> [DiscoverCard] {
        return [
            DiscoverCard(title: "ПУЛЬС Дайджест", subtitle: "Главное за неделю в одном месте", icon: "newspaper.fill", seed: 11, action: "channel"),
            DiscoverCard(title: "Неон-студия", subtitle: "Арт, графика и вдохновение", icon: "paintbrush.fill", seed: 27, action: "channel"),
            DiscoverCard(title: "Нейро-новости", subtitle: "ИИ и технологии каждый день", icon: "brain.head.profile", seed: 43, action: "channel"),
            DiscoverCard(title: "Продуктовые заметки", subtitle: "Как делать продукт, который любят", icon: "lightbulb.fill", seed: 58, action: "channel"),
            DiscoverCard(title: "Ночные кофе", subtitle: "Сообщество тех, кто не спит", icon: "cup.and.saucer.fill", seed: 71, action: "group"),
            DiscoverCard(title: "Дизайн-ревью", subtitle: "Разбор макетов и типографики", icon: "square.on.square", seed: 89, action: "group"),
            DiscoverCard(title: "Книжный клуб", subtitle: "Что читаем на этой неделе", icon: "book.fill", seed: 104, action: "group"),
            DiscoverCard(title: "Планы на выходные", subtitle: "Планируем большую поездку", icon: "airplane", seed: 120, action: "group"),
            DiscoverCard(title: "Безопасность", subtitle: "Советы по приватности и данным", icon: "lock.shield.fill", seed: 135, action: "info"),
            DiscoverCard(title: "Статистика", subtitle: "Ваша активность за 30 дней", icon: "chart.bar.fill", seed: 151, action: "stats"),
            DiscoverCard(title: "Избранное", subtitle: "Сообщения и чаты под рукой", icon: "star.fill", seed: 167, action: "favorites"),
            DiscoverCard(title: "Архив", subtitle: "Тихие чаты в отдельном месте", icon: "archivebox.fill", seed: 183, action: "archive")
        ]
    }

    private func cardSize() -> CGSize {
        let width = floor((view.bounds.width - 32 - 14) / 2)
        return CGSize(width: width, height: 168)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { cards.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverCardCell", for: indexPath) as! DiscoverCardCell
        cell.configure(cards[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { cardSize() }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = cards[indexPath.item]
        Feedback.shared.tap()
        switch card.action {
        case "channel", "group":
            if let chat = Storage.shared.state.chats.first(where: { $0.title == card.title }) {
                let vc = ChatViewController(chatID: chat.id)
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            } else {
                showInfo(card)
            }
        case "favorites", "archive":
            tabBarController?.selectedIndex = 0
            showInfo(card)
        default:
            showInfo(card)
        }
    }

    private func showInfo(_ card: DiscoverCard) {
        let alert = UIAlertController(title: card.title, message: card.subtitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Открыть", style: .default) { _ in
            Feedback.shared.success()
        })
        alert.addAction(UIAlertAction(title: "Понятно", style: .cancel))
        present(alert, animated: true)
    }
}

final class DiscoverCardCell: UICollectionViewCell {
    private let image = UIImageView()
    private let shade = UIView()
    private let icon = UIImageView()
    private let title = UILabel()
    private let subtitle = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true

        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(image)

        shade.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shade)

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        contentView.addSubview(icon)

        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 15, weight: .bold)
        title.textColor = .white
        title.numberOfLines = 2
        contentView.addSubview(title)

        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .systemFont(ofSize: 11, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.78)
        subtitle.numberOfLines = 2
        contentView.addSubview(subtitle)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: contentView.topAnchor),
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            image.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            shade.topAnchor.constraint(equalTo: contentView.topAnchor),
            shade.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shade.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shade.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            icon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            title.bottomAnchor.constraint(equalTo: subtitle.topAnchor, constant: -4),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            subtitle.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(_ card: DiscoverViewController.DiscoverCard) {
        image.image = AvatarFactory.gradientImage(seed: card.seed, size: CGSize(width: 360, height: 360))
        shade.backgroundColor = UIColor.black.withAlphaComponent(0.38)
        icon.image = UIImage(systemName: card.icon)
        title.text = card.title
        subtitle.text = card.subtitle
    }
}
