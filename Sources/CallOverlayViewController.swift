
import UIKit

final class CallOverlayViewController: UIViewController {
    private let user: PulseUser
    private let video: Bool

    private let ring = UIView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let durationLabel = UILabel()
    private let muteButton = UIButton(type: .system)
    private let speakerButton = UIButton(type: .system)
    private let videoButton = UIButton(type: .system)
    private let endButton = UIButton(type: .system)
    private let gradient = CAGradientLayer()

    private var timer: Timer?
    private var seconds = 0

    init(user: PulseUser, video: Bool) {
        self.user = user
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        user = PulseUser(id: "", name: "", handle: "", avatarSeed: 0, online: false,
                         status: "", bio: "", isContact: false)
        video = false
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        Feedback.shared.thud()
        statusLabel.text = "Соединение…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self = self else { return }
            self.statusLabel.text = self.video ? "Видеозвонок" : "Звонок идёт"
            self.startTimer()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    private func build() {
        let p = ThemeManager.shared.current.palette
        gradient.colors = [p.bg2.cgColor, p.bg.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradient, at: 0)

        ring.backgroundColor = p.accent.withAlphaComponent(0.16)
        ring.layer.cornerRadius = 130
        ring.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ring)

        avatarView.image = AvatarFactory.avatar(name: user.name, seed: user.avatarSeed,
                                                size: CGSize(width: 240, height: 240))
        avatarView.layer.cornerRadius = 100
        avatarView.layer.masksToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarView)

        nameLabel.text = user.name
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = p.text
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = p.text2
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        durationLabel.text = "00:00"
        durationLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        durationLabel.textColor = p.accent2
        durationLabel.textAlignment = .center
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(durationLabel)

        muteButton.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
        speakerButton.setImage(UIImage(systemName: "speaker.wave.3.fill"), for: .normal)
        videoButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        endButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)

        muteButton.addTarget(self, action: #selector(toggleMute(_:)), for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(toggleSpeaker(_:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(toggleVideo(_:)), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(endCall), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [muteButton, speakerButton, videoButton, endButton])
        stack.axis = .horizontal
        stack.spacing = 22
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        for button in [muteButton, speakerButton, videoButton, endButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 62).isActive = true
            button.heightAnchor.constraint(equalToConstant: 62).isActive = true
            button.layer.cornerRadius = 31
            button.backgroundColor = p.surface
            button.tintColor = .white
        }
        endButton.backgroundColor = p.red

        NSLayoutConstraint.activate([
            ring.widthAnchor.constraint(equalToConstant: 260),
            ring.heightAnchor.constraint(equalToConstant: 260),
            ring.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),

            avatarView.widthAnchor.constraint(equalToConstant: 200),
            avatarView.heightAnchor.constraint(equalToConstant: 200),
            avatarView.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: ring.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: ring.bottomAnchor, constant: 26),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            durationLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            stack.heightAnchor.constraint(equalToConstant: 62)
        ])

        UIView.animate(withDuration: 1.4, delay: 0,
                       options: [.repeat, .autoreverse, .allowUserInteraction],
                       animations: {
                        self.ring.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
                        self.ring.alpha = 0.25
                       })
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                     selector: #selector(tick), userInfo: nil, repeats: true)
    }

    @objc private func tick() {
        seconds += 1
        durationLabel.text = String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    @objc private func toggleMute(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.backgroundColor = sender.isSelected ? ThemeManager.shared.current.palette.accent : ThemeManager.shared.current.palette.surface
        Feedback.shared.tap()
    }

    @objc private func toggleSpeaker(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.backgroundColor = sender.isSelected ? ThemeManager.shared.current.palette.accent2 : ThemeManager.shared.current.palette.surface
        Feedback.shared.tap()
    }

    @objc private func toggleVideo(_ sender: UIButton) {
        sender.isSelected.toggle()
        statusLabel.text = sender.isSelected ? "Видео включено" : (video ? "Видеозвонок" : "Звонок идёт")
        Feedback.shared.tap()
    }

    @objc private func endCall() {
        timer?.invalidate()
        timer = nil
        Feedback.shared.warning()
        let userID = user.id
        Storage.shared.update { s in
            s.calls.insert(CallRecord(id: "call_\(UUID().uuidString)", userID: userID,
                                      incoming: false, video: self.video, missed: false,
                                      timestamp: Date(), duration: self.seconds), at: 0)
        }
        dismiss(animated: true)
    }
}
