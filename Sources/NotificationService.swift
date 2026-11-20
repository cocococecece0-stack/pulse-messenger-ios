import Foundation
import UIKit
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDemo() {
        guard Storage.shared.state.notificationsOn else { return }
        let content = UNMutableNotificationContent()
        content.title = "ПУЛЬС"
        content.body = "Марина: Привет! Ты видел новое сообщение? 👋"
        content.sound = .default
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
        let request = UNNotificationRequest(identifier: "pulse.welcome", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
