
import UIKit

protocol InputBarViewDelegate: AnyObject {
    func inputBar(_ bar: InputBarView, didSend text: String)
    func inputBarDidTapAttach(_ bar: InputBarView)
    func inputBarDidTapMic(_ bar: InputBarView)
}

final class InputBarView: UIView, UITextViewDelegate {
    weak var delegate: InputBarViewDelegate?

    private let textView = UITextView()
    private let attachButton = UIButton(type: .system)
    private let micButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let replyLabel = UILabel()
    private var replyHeight: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        replyLabel.font = .systemFont(ofSize: 11, weight: .medium)
        replyLabel.numberOfLines = 1
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(replyLabel)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.delegate = self
        textView.layer.cornerRadius = 20
        textView.layer.masksToBounds = true
        addSubview(textView)

        attachButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        for button in [attachButton, micButton, sendButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = .white
            addSubview(button)
        }
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        replyHeight = replyLabel.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            replyLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            replyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            replyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            replyHeight,

            textView.topAnchor.constraint(equalTo: replyLabel.bottomAnchor, constant: 2),
            textView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -4),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            attachButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            attachButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            attachButton.widthAnchor.constraint(equalToConstant: 34),
            attachButton.heightAnchor.constraint(equalToConstant: 34),

            micButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -2),
            micButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            micButton.widthAnchor.constraint(equalToConstant: 34),
            micButton.heightAnchor.constraint(equalToConstant: 34),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 38),
            sendButton.heightAnchor.constraint(equalToConstant: 38)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
        applyStyle()
        updateSendState()
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        backgroundColor = p.bg.withAlphaComponent(0.92)
        textView.backgroundColor = p.surface
        textView.textColor = p.text
        replyLabel.textColor = p.text2
        attachButton.tintColor = p.text2
        micButton.tintColor = p.text2
        sendButton.tintColor = p.accent
        layer.borderColor = p.border.cgColor
        layer.borderWidth = 0.5
    }

    func setReply(_ text: String) {
        replyLabel.text = "↳ " + text
        replyHeight.constant = 20
    }

    func clearReply() {
        replyLabel.text = nil
        replyHeight.constant = 0
    }

    func clearText() {
        textView.text = ""
        updateSendState()
    }

    func currentText() -> String { textView.text ?? "" }

    func textViewDidChange(_ textView: UITextView) { updateSendState() }

    private func updateSendState() {
        let hasText = !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isEnabled = hasText
        sendButton.alpha = hasText ? 1 : 0.35
        micButton.isHidden = hasText
    }

    @objc private func sendTapped() {
        let text = currentText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        clearText()
        clearReply()
        Feedback.shared.click()
        delegate?.inputBar(self, didSend: text)
    }

    @objc private func attachTapped() {
        Feedback.shared.tap()
        delegate?.inputBarDidTapAttach(self)
    }

    @objc private func micTapped() {
        Feedback.shared.tap()
        delegate?.inputBarDidTapMic(self)
    }
}
