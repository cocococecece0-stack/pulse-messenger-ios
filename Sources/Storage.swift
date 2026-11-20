
import Foundation

final class Storage {
    static let shared = Storage()

    private let fileURL: URL = {
        let dirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return dirs[dirs.count - 1].appendingPathComponent("pulse-state.json")
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private(set) var state: AppState

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode(AppState.self, from: data) {
            state = decoded
        } else {
            state = SeedData.make()
            save()
        }
        if let theme = ThemeID(rawValue: state.themeID) {
            ThemeManager.shared.set(theme)
        }
    }

    func save() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func update(_ block: (inout AppState) -> Void) {
        block(&state)
        save()
    }

    func resetDemo() {
        state = SeedData.make()
        save()
    }

    func user(withID id: String) -> PulseUser? {
        if id == state.me.id { return state.me }
        return state.users.first { $0.id == id }
    }

    func chat(withID id: String) -> Chat? {
        state.chats.first { $0.id == id }
    }

    func messages(in chatID: String) -> [Message] {
        state.messages.filter { $0.chatID == chatID }.sorted { $0.timestamp < $1.timestamp }
    }

    func send(text: String, in chatID: String, replyTo: String? = nil) -> Message {
        let message = Message(
            id: "sent_\(UUID().uuidString)",
            chatID: chatID,
            senderID: state.me.id,
            text: text,
            kind: .text,
            timestamp: Date(),
            outgoing: true,
            read: false,
            edited: false,
            pinned: false,
            replyToID: replyTo,
            reactions: [],
            duration: nil,
            mediaSeed: Int.random(in: 1...9999),
            fileName: nil,
            fileSize: nil,
            linkURL: nil,
            linkTitle: nil)
        update { s in
            s.messages.append(message)
            if let index = s.chats.firstIndex(where: { $0.id == chatID }) {
                s.chats[index].lastMessage = message
                s.chats[index].draft = ""
                s.chats[index].unread = 0
            }
        }
        return message
    }

    func receive(text: String, in chatID: String, from userID: String) {
        let message = Message(
            id: "recv_\(UUID().uuidString)",
            chatID: chatID,
            senderID: userID,
            text: text,
            kind: .text,
            timestamp: Date(),
            outgoing: false,
            read: true,
            edited: false,
            pinned: false,
            replyToID: nil,
            reactions: [],
            duration: nil,
            mediaSeed: Int.random(in: 1...9999),
            fileName: nil,
            fileSize: nil,
            linkURL: nil,
            linkTitle: nil)
        update { s in
            s.messages.append(message)
            if let index = s.chats.firstIndex(where: { $0.id == chatID }) {
                s.chats[index].lastMessage = message
                s.chats[index].unread += 1
                s.chats[index].typing = false
            }
        }
    }

    func exportData() -> String {
        guard let data = try? encoder.encode(state) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
