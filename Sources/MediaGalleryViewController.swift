
import UIKit

final class MediaGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private struct MediaItem {
        let seed: Int
        let caption: String
        let time: String
    }

    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var items: [MediaItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Медиатека"
        build()
        reload()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle), name: .pulseThemeChanged, object: nil)
    }

    private func build() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 4
        let columns: CGFloat = 3
        let side = floor((view.bounds.width - spacing * (columns - 1)) / columns)
        layout.itemSize = CGSize(width: side, height: side)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing

        collection.collectionViewLayout = layout
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        collection.alwaysBounceVertical = true
        view.addSubview(collection)
        collection.pinToSuperview()
    }

    private func reload() {
        let s = Storage.shared.state
        var result: [MediaItem] = []
        for message in s.messages where message.kind == .image || message.kind == .location {
            result.append(MediaItem(seed: message.mediaSeed, caption: message.text, time: message.timestamp.relativeString))
        }
        for story in s.stories {
            result.append(MediaItem(seed: story.gradientSeed, caption: story.caption, time: story.timestamp.relativeString))
        }
        if result.isEmpty {
            for i in 0..<18 {
                result.append(MediaItem(seed: i * 37 + 5, caption: "Медиа \(i + 1)", time: "сейчас"))
            }
        }
        items = result
        collection.reloadData()
    }

    @objc private func applyStyle() {
        view.backgroundColor = ThemeManager.shared.current.palette.bg
        collection.backgroundColor = .clear
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
        let item = items[indexPath.item]
        cell.imageView.image = AvatarFactory.gradientImage(seed: item.seed, size: CGSize(width: 240, height: 240))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        Feedback.shared.tap()
        let preview = MediaPreviewViewController(image: AvatarFactory.gradientImage(
            seed: item.seed, size: CGSize(width: 900, height: 1400)), caption: item.caption)
        preview.modalPresentationStyle = .fullScreen
        present(preview, animated: true)
    }
}

final class MediaCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.pinToSuperview()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

final class MediaPreviewViewController: UIViewController {
    private let image: UIImage
    private let caption: String
    private let imageView = UIImageView()
    private let captionLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    init(image: UIImage, caption: String) {
        self.image = image
        self.caption = caption
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        image = UIImage()
        caption = ""
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        captionLabel.text = caption
        captionLabel.textColor = .white
        captionLabel.font = .systemFont(ofSize: 22, weight: .bold)
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 3
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captionLabel)

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)

        shareButton.setImage(UIImage(systemName: "square.and.arrow.up.circle.fill"), for: .normal)
        shareButton.tintColor = .white
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        view.addSubview(shareButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            captionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            captionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 34),
            closeButton.heightAnchor.constraint(equalToConstant: 34),
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            shareButton.widthAnchor.constraint(equalToConstant: 34),
            shareButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    @objc private func close() { dismiss(animated: true) }

    @objc private func share() {
        let activity = UIActivityViewController(activityItems: [image, caption], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = view
        present(activity, animated: true)
    }
}
