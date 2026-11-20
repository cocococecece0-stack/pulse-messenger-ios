
import Foundation
import UIKit

struct PulseUser: Codable, Hashable, Identifiable {
    let id: String
    var name: String
    var handle: String
    var avatarSeed: Int
    var online: Bool
    var status: String
    var bio: String
    var isContact: Bool
}

enum ChatKind: String, Codable {
    case direct, group, channel
}

enum MessageKind: String, Codable {
    case text, image, voice, file, location, link, sticker, system
}

struct Reaction: Codable, Hashable {
    let emoji: String
    let count: Int
}

struct Message: Codable, Hashable, Identifiable {
    let id: String
    let chatID: String
    var senderID: String
    var text: String
    var kind: MessageKind
    var timestamp: Date
    var outgoing: Bool
    var read: Bool
    var edited: Bool
    var pinned: Bool
    var replyToID: String?
    var reactions: [Reaction]
    var duration: Double?
    var mediaSeed: Int
    var fileName: String?
    var fileSize: String?
    var linkURL: String?
    var linkTitle: String?

    var reactionSummary: String {
        reactions.map { "\($0.emoji) \($0.count)" }.joined(separator: "  ")
    }
}

struct Chat: Codable, Hashable, Identifiable {
    let id: String
    var title: String
    var avatarSeed: Int
    var kind: ChatKind
    var pinned: Bool
    var muted: Bool
    var archived: Bool
    var unread: Int
    var draft: String
    var typing: Bool
    var lastMessage: Message?
    var memberIDs: [String]
    var about: String
    var verified: Bool

    var subtitle: String {
        if typing { return "печатает…" }
        if let last = lastMessage {
            let prefix = last.outgoing ? "Вы: " : ""
            switch last.kind {
            case .image: return prefix + "Фото"
            case .voice: return prefix + "Голосовое сообщение"
            case .file: return prefix + "Файл"
            case .location: return prefix + "Геолокация"
            case .link: return prefix + "Ссылка"
            case .sticker: return prefix + "Стикер"
            case .system: return last.text
            case .text: return prefix + last.text
            }
        }
        return "Начните общение"
    }
}

struct Story: Codable, Hashable, Identifiable {
    let id: String
    let userID: String
    var gradientSeed: Int
    var caption: String
    var timestamp: Date
    var seen: Bool
    var likes: Int
}

struct CallRecord: Codable, Hashable, Identifiable {
    let id: String
    let userID: String
    var incoming: Bool
    var video: Bool
    var missed: Bool
    var timestamp: Date
    var duration: Int
}

enum Folder: String, CaseIterable {
    case all, unread, groups, channels, archived, favorites

    var title: String {
        switch self {
        case .all: return "Все"
        case .unread: return "Непрочитанные"
        case .groups: return "Группы"
        case .channels: return "Каналы"
        case .archived: return "Архив"
        case .favorites: return "Избранное"
        }
    }
}

struct AppState: Codable {
    var version: Int = 1
    var me: PulseUser
    var users: [PulseUser]
    var chats: [Chat]
    var messages: [Message]
    var stories: [Story]
    var calls: [CallRecord]
    var themeID: String = "midnight"
    var notificationsOn: Bool = true
    var hapticsOn: Bool = true
    var showOnline: Bool = true
    var readReceipts: Bool = true
    var compactMode: Bool = false
    var blockedIDs: [String] = []
    var favorites: [String] = []
}
