
import UIKit

final class StoryViewerViewController: UIViewController {
    private var stories: [Story]
    private var index: Int

    private let background = UIImageView()
    private let shade = UIView()
    private let progressStack = UIStackView()
    private var progressFills: [UIView] = []
    private var progressTracks: [UIView] = []
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let caption = UILabel()
    private let closeButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private let replyField = UITextField()

    private var timer: Timer?
    private var progress: CGFloat = 0

    init(stories: [Story], index: Int) {
        self.stories = stories
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        stories = []
        index = 0
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        show(index)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    private func build() {
        background.contentMode = .scaleAspectFill
        background.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(background)

        shade.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        shade.isUserInteractionEnabled = false
        shade.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shade)

        progressStack.axis = .horizontal
        progressStack.spacing = 4
        progressStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressStack)

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 18
        avatar.layer.masksToBounds = true
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = UIColor.white.cgColor
        view.addSubview(avatar)

        nameLabel.font = .systemFont(ofSize: 14, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeLabel)

        caption.font = .systemFont(ofSize: 30, weight: .bold)
        caption.textColor = .white
        caption.textAlignment = .center
        caption.numberOfLines = 4
        caption.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(caption)

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)

        likeButton.setTitle("❤️", for: .normal)
        likeButton.titleLabel?.font = .systemFont(ofSize: 22)
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.addTarget(self, action: #selector(like), for: .touchUpInside)
        view.addSubview(likeButton)

        replyField.placeholder = "Ответить истории…"
        replyField.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        replyField.layer.cornerRadius = 20
        replyField.textColor = .white
        replyField.font = .systemFont(ofSize: 14)
        replyField.setLeftPaddingPoints(14)
        replyField.translatesAutoresizingMaskIntoConstraints = false
        replyField.delegate = self
        view.addSubview(replyField)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            shade.topAnchor.constraint(equalTo: view.topAnchor),
            shade.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shade.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shade.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            progressStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            progressStack.heightAnchor.constraint(equalToConstant: 3),

            avatar.topAnchor.constraint(equalTo: progressStack.bottomAnchor, constant: 14),
            avatar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),
            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: avatar.topAnchor, constant: 1),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            closeButton.topAnchor.constraint(equalTo: progressStack.bottomAnchor, constant: 14),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            caption.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            caption.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            caption.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            likeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            likeButton.bottomAnchor.constraint(equalTo: replyField.topAnchor, constant: -14),

            replyField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            replyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            replyField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            replyField.heightAnchor.constraint(equalToConstant: 44)
        ])

        let leftTap = UITapGestureRecognizer(target: self, action: #selector(rewindStory))
        leftTap.numberOfTapsRequired = 1
        let leftZone = UIView()
        leftZone.backgroundColor = .clear
        leftZone.addGestureRecognizer(leftTap)
        leftZone.isUserInteractionEnabled = true
        leftZone.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(leftZone, at: 1)

        let rightTap = UITapGestureRecognizer(target: self, action: #selector(advanceStory))
        let rightZone = UIView()
        rightZone.backgroundColor = .clear
        rightZone.addGestureRecognizer(rightTap)
        rightZone.isUserInteractionEnabled = true
        rightZone.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(rightZone, at: 2)
        NSLayoutConstraint.activate([
            leftZone.topAnchor.constraint(equalTo: progressStack.bottomAnchor),
            leftZone.bottomAnchor.constraint(equalTo: replyField.topAnchor),
            leftZone.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftZone.trailingAnchor.constraint(equalTo: view.centerXAnchor),
            rightZone.topAnchor.constraint(equalTo: progressStack.bottomAnchor),
            rightZone.bottomAnchor.constraint(equalTo: replyField.topAnchor),
            rightZone.leadingAnchor.constraint(equalTo: view.centerXAnchor),
            rightZone.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func show(_ i: Int) {
        guard stories.indices.contains(i) else { close(); return }
        index = i
        let story = stories[i]
        let user = Storage.shared.user(withID: story.userID)

        background.image = AvatarFactory.gradientImage(seed: story.gradientSeed,
                                                       size: CGSize(width: 800, height: 1400))
        avatar.image = AvatarFactory.avatar(name: user?.name ?? "?", seed: user?.avatarSeed ?? 1,
                                            size: CGSize(width: 72, height: 72))
        nameLabel.text = user?.name ?? "Пользователь"
        timeLabel.text = story.timestamp.relativeString
        caption.text = story.caption

        for track in progressTracks {
            track.removeFromSuperview()
        }
        progressTracks.removeAll()
        progressFills.removeAll()
        for _ in stories {
            let track = UIView()
            track.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            track.layer.cornerRadius = 1.5
            track.translatesAutoresizingMaskIntoConstraints = false
            progressStack.addArrangedSubview(track)
            progressTracks.append(track)
            let fill = UIView()
            fill.backgroundColor = .white
            fill.layer.cornerRadius = 1.5
            fill.transform = CGAffineTransform(scaleX: 0, y: 1)
            fill.translatesAutoresizingMaskIntoConstraints = false
            track.addSubview(fill)
            fill.pinToSuperview()
            progressFills.append(fill)
        }

        Storage.shared.update { s in
            if let i = s.stories.firstIndex(where: { $0.id == story.id }) { s.stories[i].seen = true }
        }

        progress = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self,
                                     selector: #selector(tick), userInfo: nil, repeats: true)
    }

    @objc private func tick() {
        progress += 0.01
        if index < progressFills.count {
            progressFills[index].transform = CGAffineTransform(scaleX: progress, y: 1)
        }
        if progress >= 1 { advanceStory() }
    }

    @objc private func advanceStory() {
        if index + 1 < stories.count { show(index + 1) } else { close() }
    }

    @objc private func rewindStory() {
        if index > 0 { show(index - 1) } else { progress = 0 }
    }

    @objc private func close() {
        timer?.invalidate()
        dismiss(animated: true)
    }

    @objc private func like() {
        let storyID = stories[index].id
        Storage.shared.update { s in
            if let i = s.stories.firstIndex(where: { $0.id == storyID }) { s.stories[i].likes += 1 }
        }
        likeButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        UIView.animate(withDuration: 0.25) { self.likeButton.transform = .identity }
        Feedback.shared.success()
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        leftView = view
        leftViewMode = .always
    }
}

extension StoryViewerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        Feedback.shared.success()
        return true
    }
}
