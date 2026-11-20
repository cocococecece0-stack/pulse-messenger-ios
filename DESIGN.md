# Дизайн: ПУЛЬС — Мессенджер

## Принцип

Полноценный клиент мессенджера без сервера: вся логика, данные и визуал живут в приложении. Внешний вид — тёмный неон, большие заголовки, стеклянные поверхности, мягкие градиенты, живые анимации и хаптики.

## Архитектура

| Слой | Файлы |
|---|---|
| Тема и дизайн-система | `Theme.swift`, `AvatarFactory.swift`, `Utils.swift` |
| Модели и данные | `Models.swift`, `SeedData.swift`, `Storage.swift` |
| Сервисы | `Feedback.swift`, `NotificationService.swift`, `SmartReply.swift` |
| Навигация | `RootTabBarController.swift` |
| Чаты | `ChatsViewController.swift`, `ChatCell.swift`, `ChatViewController.swift`, `MessageCell.swift`, `InputBarView.swift` |
| Звонки | `CallsViewController.swift`, `CallOverlayViewController.swift` |
| Истории | `StoriesViewController.swift`, `StoryViewerViewController.swift` |
| Контакты и профиль | `ContactsViewController.swift`, `ProfileViewController.swift` |
| Инструменты | `DiscoverViewController.swift`, `StatsViewController.swift`, `NotificationsViewController.swift`, `SavedMessagesViewController.swift`, `MediaGalleryViewController.swift` |
| Настройки и About | `SettingsViewController.swift`, `AboutWebViewController.swift` |

## Техника

- Swift 5, UIKit, iOS 15+, XcodeGen, без storyboard и внешних ассетов.
- Codable-состояние в `Documents/pulse-state.json` с атомарной записью.
- CI: `macos-26-intel`, `xcodebuild archive` без подписи, artifact + GitHub Release.
