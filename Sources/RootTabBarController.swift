
import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let chats = UINavigationController(rootViewController: ChatsViewController())
        chats.tabBarItem = UITabBarItem(title: "Чаты", image: UIImage(systemName: "bubble.left.and.bubble.right.fill"), tag: 0)

        let calls = UINavigationController(rootViewController: CallsViewController())
        calls.tabBarItem = UITabBarItem(title: "Звонки", image: UIImage(systemName: "phone.fill"), tag: 1)

        let stories = UINavigationController(rootViewController: StoriesViewController())
        stories.tabBarItem = UITabBarItem(title: "Истории", image: UIImage(systemName: "play.circle.fill"), tag: 2)

        let contacts = UINavigationController(rootViewController: ContactsViewController())
        contacts.tabBarItem = UITabBarItem(title: "Контакты", image: UIImage(systemName: "person.2.fill"), tag: 3)

        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.tabBarItem = UITabBarItem(title: "Ещё", image: UIImage(systemName: "ellipsis.circle.fill"), tag: 4)

        viewControllers = [chats, calls, stories, contacts, settings]
        applyStyle()

        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        tabBar.tintColor = p.accent
        tabBar.unselectedItemTintColor = p.text2
        tabBar.barTintColor = p.surface
        tabBar.isTranslucent = false
        view.backgroundColor = p.bg
        for controller in viewControllers ?? [] {
            (controller as? UINavigationController)?.applyPulseStyle()
        }
    }
}
