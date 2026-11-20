
import UIKit

final class StoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var stories: [Story] = []
    private var ringCollection: UICollectionView!
    private var feedCollection: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Истории"
        buildRings()
        buildFeed()
        reload()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func buildRings() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 78, height: 106)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        ringCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        ringCollection.translatesAutoresizingMaskIntoConstraints = false
        ringCollection.showsHorizontalScrollIndicator = false
        ringCollection.dataSource = self
        ringCollection.delegate = self
        ringCollection.register(StoryRingCell.self, forCellWithReuseIdentifier: "RingCell")
        view.addSubview(ringCollection)

        NSLayoutConstraint.activate([
            ringCollection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            ringCollection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ringCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ringCollection.heightAnchor.constraint(equalToConstant: 122)
        ])
    }

    private func buildFeed() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16)

        feedCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        feedCollection.translatesAutoresizingMaskIntoConstraints = false
        feedCollection.dataSource = self
        feedCollection.delegate = self
        feedCollection.register(StoryCardCell.self, forCellWithReuseIdentifier: "CardCell")
        view.addSubview(feedCollection)

        NSLayoutConstraint.activate([
            feedCollection.topAnchor.constraint(equalTo: ringCollection.bottomAnchor, constant: 2),
            feedCollection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feedCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            feedCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        ringCollection.backgroundColor = .clear
        feedCollection.backgroundColor = .clear
    }

    private func reload() {
        stories = Storage.shared.state.stories.sorted { $0.timestamp > $1.timestamp }
        ringCollection.reloadData()
        feedCollection.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stories.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let story = stories[indexPath.item]
        let user = Storage.shared.user(withID: story.userID)
        let name = user?.name ?? "Пользователь"

        if collectionView === ringCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RingCell", for: indexPath) as! StoryRingCell
            cell.configure(name: name, seed: story.gradientSeed, seen: story.seen)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! StoryCardCell
        cell.configure(story: story, name: name)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === ringCollection { return CGSize(width: 78, height: 106) }
        return CGSize(width: view.bounds.width - 32, height: 400)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Feedback.shared.tap()
        var updated = Storage.shared.state
        if updated.stories.indices.contains(indexPath.item) {
            updated.stories[indexPath.item].seen = true
            Storage.shared.update { s in
                if let i = s.stories.firstIndex(where: { $0.id == self.stories[indexPath.item].id }) {
                    s.stories[i].seen = true
                }
            }
            _ = updated
        }
        let viewer = StoryViewerViewController(stories: stories, index: indexPath.item)
        viewer.modalPresentationStyle = .fullScreen
        present(viewer, animated: true)
    }
}

final class StoryRingCell: UICollectionViewCell {
    private let avatar = UIImageView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 31
        avatar.layer.masksToBounds = true
        avatar.layer.borderWidth = 3
        contentView.addSubview(avatar)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatar.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 64),
            avatar.heightAnchor.constraint(equalToConstant: 64),
            nameLabel.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(name: String, seed: Int, seen: Bool) {
        let p = ThemeManager.shared.current.palette
        avatar.image = AvatarFactory.gradientImage(seed: seed, size: CGSize(width: 128, height: 128))
        avatar.layer.borderColor = (seen ? p.surface2 : p.accent).cgColor
        nameLabel.text = name
        nameLabel.textColor = p.text2
    }
}

final class StoryCardCell: UICollectionViewCell {
    private let background = UIImageView()
    private let shade = UIView()
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let captionLabel = UILabel()
    private let likeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true

        background.contentMode = .scaleAspectFill
        background.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(background)

        shade.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shade)

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 17
        avatar.layer.masksToBounds = true
        avatar.layer.borderWidth = 2
        contentView.addSubview(avatar)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 14, weight: .bold)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        contentView.addSubview(timeLabel)

        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = .systemFont(ofSize: 22, weight: .bold)
        captionLabel.textColor = .white
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 3
        contentView.addSubview(captionLabel)

        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.setTitle("❤️", for: .normal)
        likeButton.titleLabel?.font = .systemFont(ofSize: 18)
        contentView.addSubview(likeButton)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: contentView.topAnchor),
            background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            shade.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shade.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shade.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            shade.heightAnchor.constraint(equalToConstant: 180),

            avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: avatar.topAnchor, constant: 2),

            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            likeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(story: Story, name: String) {
        let user = Storage.shared.user(withID: story.userID)
        background.image = AvatarFactory.gradientImage(seed: story.gradientSeed,
                                                       size: CGSize(width: 600, height: 800))
        avatar.image = AvatarFactory.avatar(name: name, seed: user?.avatarSeed ?? 1,
                                            size: CGSize(width: 72, height: 72))
        avatar.layer.borderColor = UIColor.white.cgColor
        nameLabel.text = name
        timeLabel.text = story.timestamp.relativeString
        captionLabel.text = story.caption
        shade.backgroundColor = UIColor.black.withAlphaComponent(0.35)
    }
}
