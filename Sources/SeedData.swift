
import Foundation
import UIKit

struct SeededRandom {
    private var state: UInt64

    init(_ seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state >> 33
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        let count = range.upperBound - range.lowerBound + 1
        return range.lowerBound + Int(next() % UInt64(count))
    }

    mutating func bool(_ percent: Int = 50) -> Bool {
        int(0...99) < percent
    }

    mutating func element<T>(_ array: [T]) -> T {
        array[int(0...(array.count - 1))]
    }
}

enum SeedData {
    static func make() -> AppState {
        var r = SeededRandom(20261120)

        let me = PulseUser(id: "me", name: "Алексей", handle: "@alex", avatarSeed: 7,
                           online: true, status: "в сети", bio: "Пишу код, пью кофе, собираю идеи.",
                           isContact: true)

        let names = ["Марина", "Даниил", "София", "Артём", "Ксения", "Илья", "Полина", "Максим",
                     "Алина", "Никита", "Дарья", "Егор", "Вера", "Тимур", "Юлия", "Роман",
                     "Лера", "Глеб", "Настя", "Олег", "Кristina", "Саша", "Женя", "Марк"]
        let statuses = ["в сети", "был(а) недавно", "в деле", "не беспокоить", "в поездке", "скоро вернусь"]
        var users: [PulseUser] = []
        for (index, name) in names.enumerated() {
            let user = PulseUser(
                id: "u\(index + 1)",
                name: name,
                handle: "@\(name.lowercased().replacingOccurrences(of: " ", with: ""))\(index + 1)",
                avatarSeed: index + 11,
                online: r.bool(45),
                status: r.element(statuses),
                bio: "Хороший человек. Любит общаться в ПУЛЬСЕ.",
                isContact: true)
            users.append(user)
        }

        let texts = [
            "Привет! Как дела? 👋", "Скинь, пожалуйста, файл", "Ок, сейчас посмотрю",
            "Класс! Это именно то, что нужно", "Давай созвонимся вечером",
            "Я в дороге, напишу позже", "Спасибо! Ты спаситель 🙌",
            "Послушай, что я нашёл", "Это нужно обсудить", "Хорошей тебе ночи ✨",
            "Отправил всё на почту", "Как прошла встреча?", "Не совсем понял, повтори?",
            "Вот поэтому я и люблю этот город", "Срочно глянь канал",
            "У меня отличная идея 💡", "Договорились!", "Не забудь про кофе ☕️",
            "Проверь, пожалуйста, ещё раз", "Со мной всё ок", "Это просто огонь 🔥",
            "Давай сделаем это прямо сейчас", "Я уже дома", "Фото прикрепил",
            "Напиши, когда будет удобно", "Принял, работаю над этим"
        ]
        let captions = ["Новый день ☀️", "В пути 🚀", "Вот оно! ✨", "Тихий вечер 🌙",
                        "Собрал команду 💪", "Неон города 🏙", "Кофе и код ☕️",
                        "Маленькая победа 🎉", "Смотри, что получилось"]
        let fileNames = ["Договор.pdf", "Дизайн-макет.sketch", "Отчёт.xlsx", "Презентация.key", "Архив.zip"]

        var counter = 0
        func nextID(_ prefix: String) -> String {
            counter += 1
            return "\(prefix)_\(counter)"
        }

        func makeMessage(chatID: String, senderID: String, outgoing: Bool, index: Int, previousID: String?) -> Message {
            let roll = r.int(0...99)
            var kind: MessageKind = .text
            if roll < 64 { kind = .text }
            else if roll < 72 { kind = .image }
            else if roll < 79 { kind = .voice }
            else if roll < 85 { kind = .file }
            else if roll < 89 { kind = .location }
            else if roll < 94 { kind = .link }
            else if roll < 98 { kind = .sticker }
            else { kind = .system }

            var text = r.element(texts)
            var fileName: String?
            var fileSize: String?
            var linkURL: String?
            var linkTitle: String?
            var duration: Double?

            switch kind {
            case .image: text = r.element(captions)
            case .voice: duration = Double(r.int(3...58))
            case .file:
                fileName = r.element(fileNames)
                fileSize = "\(r.int(120...8900)) КБ"
                text = fileName ?? "Файл"
            case .location: text = r.element(["Москва, Тверская 12", "Питер, Невский 48", "Кафе «Неон»", "Аэропорт Шереметьево"])
            case .link:
                linkURL = "https://pulse.messenger/story/\(r.int(100...999))"
                linkTitle = r.element(["Внутренний формат", "Новая подборка", "Разбор недели", "Ссылка от команды"])
                text = linkTitle ?? "Ссылка"
            case .sticker: text = r.element(["🔥", "🚀", "💜", "😎", "🎉", "👾"])
            case .system: text = r.element(["Чат создан", "Пользователь вошёл в чат", "Сообщение закреплено"])
            case .text: break
            }

            var reactions: [Reaction] = []
            if r.bool(22) {
                reactions.append(Reaction(emoji: r.element(["❤️", "🔥", "👍", "😂", "💜"]), count: r.int(1...6)))
            }

            return Message(
                id: nextID("m"),
                chatID: chatID,
                senderID: senderID,
                text: text,
                kind: kind,
                timestamp: Date().addingTimeInterval(-Double(r.int(0...(29 * 24 * 3600)))),
                outgoing: outgoing,
                read: outgoing ? r.bool(80) : true,
                edited: r.bool(6),
                pinned: false,
                replyToID: previousID != nil && r.bool(14) ? previousID : nil,
                reactions: reactions,
                duration: duration,
                mediaSeed: r.int(1...9999),
                fileName: fileName,
                fileSize: fileSize,
                linkURL: linkURL,
                linkTitle: linkTitle)
        }

        var chats: [Chat] = []
        var messages: [Message] = []

        // Личные чаты
        for (index, user) in users.prefix(17).enumerated() {
            let chatID = "c\(index + 1)"
            var chatMessages: [Message] = []
            let count = r.int(6...18)
            var previous: String? = nil
            for m in 0..<count {
                let outgoing = m % 3 != 0
                let msg = makeMessage(chatID: chatID, senderID: outgoing ? "me" : user.id,
                                      outgoing: outgoing, index: m, previousID: previous)
                previous = msg.id
                chatMessages.append(msg)
            }
            messages.append(contentsOf: chatMessages)
            let kind: ChatKind = index == 9 ? .channel : .direct
            chats.append(Chat(
                id: chatID,
                title: user.name,
                avatarSeed: user.avatarSeed,
                kind: kind,
                pinned: index < 3,
                muted: r.bool(18),
                archived: false,
                unread: r.int(0...6),
                draft: "",
                typing: r.bool(8),
                lastMessage: chatMessages.last,
                memberIDs: ["me", user.id],
                about: "Личная переписка",
                verified: false))
        }

        // Группы
        let groupDefs: [(String, String)] = [
            ("ПУЛЬС: команда", "Внутренний чат разработки"),
            ("Ночные кофе", "Кофе, код и мемы"),
            ("Дизайн-ревью", "Вёрстка, типографика, вайб"),
            ("Планы на выходные", "Планируем поездку"),
            ("Соседи", "Двор, подъезд, новости"),
            ("Книжный клуб", "Что читаем на этой неделе")
        ]
        for (index, def) in groupDefs.enumerated() {
            let chatID = "g\(index + 1)"
            let shuffled = users.shuffled()
            let members = ["me"] + Array(shuffled.prefix(r.int(5...12))).map { $0.id }
            var chatMessages: [Message] = []
            var previous: String? = nil
            for m in 0..<r.int(8...16) {
                let sender = r.element(members)
                let outgoing = sender == "me"
                let msg = makeMessage(chatID: chatID, senderID: sender, outgoing: outgoing,
                                      index: m, previousID: previous)
                previous = msg.id
                chatMessages.append(msg)
            }
            messages.append(contentsOf: chatMessages)
            chats.append(Chat(
                id: chatID,
                title: def.0,
                avatarSeed: 100 + index,
                kind: .group,
                pinned: index == 0,
                muted: r.bool(35),
                archived: false,
                unread: r.int(0...9),
                draft: "",
                typing: r.bool(12),
                lastMessage: chatMessages.last,
                memberIDs: members,
                about: def.1,
                verified: false))
        }

        // Каналы
        let channelDefs: [(String, String)] = [
            ("ПУЛЬС Дайджест", "Главное за неделю"),
            ("Нейро-новости", "ИИ и технологии каждый день"),
            ("Неон-студия", "Арт, графика, вдохновение"),
            ("Продуктовые заметки", "Как делать продукт")
        ]
        for (index, def) in channelDefs.enumerated() {
            let chatID = "ch\(index + 1)"
            var chatMessages: [Message] = []
            for m in 0..<r.int(10...20) {
                let msg = makeMessage(chatID: chatID, senderID: "channel\(index)",
                                      outgoing: false, index: m, previousID: nil)
                chatMessages.append(msg)
            }
            messages.append(contentsOf: chatMessages)
            chats.append(Chat(
                id: chatID,
                title: def.0,
                avatarSeed: 200 + index,
                kind: .channel,
                pinned: false,
                muted: true,
                archived: false,
                unread: r.int(1...12),
                draft: "",
                typing: false,
                lastMessage: chatMessages.last,
                memberIDs: ["me"],
                about: def.1,
                verified: true))
        }

        // Архивные чаты
        for index in 0..<2 {
            let chatID = "a\(index + 1)"
            let user = users[20 + index]
            let msg = makeMessage(chatID: chatID, senderID: user.id, outgoing: false, index: 0, previousID: nil)
            messages.append(msg)
            chats.append(Chat(
                id: chatID, title: user.name, avatarSeed: user.avatarSeed, kind: .direct,
                pinned: false, muted: true, archived: true, unread: 0, draft: "", typing: false,
                lastMessage: msg, memberIDs: ["me", user.id], about: "Архив", verified: false))
        }

        var stories: [Story] = []
        for index in 0..<14 {
            let user = users[index]
            stories.append(Story(
                id: "s\(index + 1)",
                userID: user.id,
                gradientSeed: index * 17 + 3,
                caption: r.element(captions),
                timestamp: Date().addingTimeInterval(-Double(r.int(0...(20 * 3600)))),
                seen: r.bool(35),
                likes: r.int(2...84)))
        }

        var calls: [CallRecord] = []
        for index in 0..<18 {
            let user = users[r.int(0...users.count - 1)]
            calls.append(CallRecord(
                id: "call\(index + 1)",
                userID: user.id,
                incoming: r.bool(50),
                video: r.bool(30),
                missed: r.bool(25),
                timestamp: Date().addingTimeInterval(-Double(r.int(0...(14 * 24 * 3600)))),
                duration: r.int(0...1800)))
        }

        return AppState(
            version: 1,
            me: me,
            users: users,
            chats: chats,
            messages: messages,
            stories: stories,
            calls: calls,
            themeID: "midnight",
            notificationsOn: true,
            hapticsOn: true,
            showOnline: true,
            readReceipts: true,
            compactMode: false,
            blockedIDs: [],
            favorites: [])
    }
}
