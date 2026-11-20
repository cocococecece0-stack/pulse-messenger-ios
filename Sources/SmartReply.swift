
import Foundation

enum SmartReply {
    static func suggestions(for text: String) -> [String] {
        let t = text.lowercased()
        if t.contains("привет") || t.contains("здрав") {
            return ["Привет! 👋", "Йо! Как дела?", "Давай на связи"]
        }
        if t.contains("как дела") || t.contains("как ты") {
            return ["Всё отлично!", "Нормально, работаю 💻", "Давай встретимся и обсудим"]
        }
        if t.contains("файл") || t.contains("скинь") {
            return ["Сейчас скину", "Уже отправил", "Напиши, куда лучше"]
        }
        if t.contains("созвон") || t.contains("позвон") {
            return ["Давай вечером", "Сейчас удобно", "Напиши ссылку"]
        }
        if t.contains("спасибо") {
            return ["Пожалуйста 🙌", "Не за что!", "Обращайся"]
        }
        if t.contains("?" ) {
            return ["Дай подумать", "Сейчас отвечу", "Хороший вопрос 💡"]
        }
        return ["Ок 👌", "Понял", "Сейчас посмотрю", "Хорошо!"]
    }
}
