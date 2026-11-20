
import UIKit

final class ChatCell: UITableViewCell {
    static let reuse = "ChatCell"

    private let avatarView = UIImageView()
    private let onlineDot = UIView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let timeLabel = UILabel()
    private let badgeLabel = UILabel()
    private let pinIcon = UIImageView()
    private let muteIcon = UIImageView()
    private let verifiedIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 26
        avatarView.layer.masksToBounds = true
        contentView.addSubview(avatarView)

        onlineDot.layer.borderWidth = 2
        onlineDot.layer.cornerRadius = 6
        onlineDot.layer.masksToBounds = true
        contentView.addSubview(onlineDot)

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        contentView.addSubview(nameLabel)

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.numberOfLines = 1
        contentView.addSubview(subtitleLabel)

        timeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)

        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.masksToBounds = true
        contentView.addSubview(badgeLabel)

        pinIcon.image = UIImage(systemName: "pin.fill")
        pinIcon.tintColor = .systemGray2
        contentView.addSubview(pinIcon)

        muteIcon.image = UIImage(systemName: "bell.slash.fill")
        muteIcon.tintColor = .systemGray2
        contentView.addSubview(muteIcon)

        verifiedIcon.image = UIImage(systemName: "checkmark.seal.fill")
        verifiedIcon.tintColor = .systemCyan
        contentView.addSubview(verifiedIcon)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            avatarView.widthAnchor.constraint(equalToConstant: 52),
            avatarView.heightAnchor.constraint(equalToConstant: 52),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            onlineDot.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 1),
            onlineDot.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 1),
            onlineDot.widthAnchor.constraint(equalToConstant: 12),
            onlineDot.heightAnchor.constraint(equalToConstant: 12),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeLabel.leadingAnchor, constant: -8),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 2),

            badgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            badgeLabel.centerYAnchor.constraint(equalTo: subtitleLabel.centerYAnchor),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20),

            pinIcon.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -6),
            pinIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 12),
            pinIcon.heightAnchor.constraint(equalToConstant: 12),

            muteIcon.trailingAnchor.constraint(equalTo: pinIcon.leadingAnchor, constant: -5),
            muteIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            muteIcon.widthAnchor.constraint(equalToConstant: 12),
            muteIcon.heightAnchor.constraint(equalToConstant: 12),

            verifiedIcon.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            verifiedIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            verifiedIcon.widthAnchor.constraint(equalToConstant: 13),
            verifiedIcon.heightAnchor.constraint(equalToConstant: 13)
        ])
        for view in [avatarView, onlineDot, nameLabel, subtitleLabel, timeLabel,
                     badgeLabel, pinIcon, muteIcon, verifiedIcon] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        badgeLabel.text = nil
        badgeLabel.isHidden = true
        onlineDot.isHidden = true
        pinIcon.isHidden = true
        muteIcon.isHidden = true
        verifiedIcon.isHidden = true
    }

    func configure(_ chat: Chat) {
        let p = ThemeManager.shared.current.palette
        nameLabel.text = chat.title
        nameLabel.textColor = p.text
        subtitleLabel.text = chat.subtitle
        subtitleLabel.textColor = chat.typing ? p.accent : p.text2
        timeLabel.text = chat.lastMessage?.timestamp.relativeString ?? ""
        timeLabel.textColor = p.text2

        avatarView.image = AvatarFactory.avatar(name: chat.title, seed: chat.avatarSeed,
                                                size: CGSize(width: 104, height: 104))
        onlineDot.isHidden = !(chat.kind == .direct && Storage.shared.state.showOnline &&
            (Storage.shared.user(withID: chat.memberIDs.last ?? "")?.online ?? false))
        onlineDot.backgroundColor = p.green
        onlineDot.layer.borderColor = p.bg.cgColor

        if chat.unread > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = chat.unread > 99 ? "99+" : "\(chat.unread)"
            badgeLabel.backgroundColor = chat.muted ? p.surface2 : p.accent
        }
        pinIcon.isHidden = !chat.pinned
        muteIcon.isHidden = !chat.muted || chat.pinned
        verifiedIcon.isHidden = !chat.verified
    }
}
