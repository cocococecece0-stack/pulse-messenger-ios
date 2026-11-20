
import UIKit

final class ContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()
    private var sections: [(letter: String, users: [PulseUser])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Контакты"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.badge.plus"), style: .plain,
            target: self, action: #selector(addContact))

        searchBar.placeholder = "Поиск контактов"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = 66
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        applyStyle()
        reload()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle),
                                               name: .pulseThemeChanged, object: nil)
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        tableView.backgroundColor = p.bg
        searchBar.tintColor = p.accent
    }

    private func reload() {
        let query = (searchBar.text ?? "").lowercased()
        let filtered = Storage.shared.state.users.filter { user in
            query.isEmpty || user.name.lowercased().contains(query) || user.handle.lowercased().contains(query)
        }.sorted { $0.name < $1.name }

        var grouped: [String: [PulseUser]] = [:]
        for user in filtered {
            let letter = String(user.name.prefix(1)).uppercased()
            grouped[letter, default: []].append(user)
        }
        sections = grouped.keys.sorted().map { ($0, grouped[$0] ?? []) }
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { reload() }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].users.count
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sections.map { $0.letter }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].letter
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let user = sections[indexPath.section].users[indexPath.row]
        let p = ThemeManager.shared.current.palette

        cell.imageView?.image = AvatarFactory.avatar(name: user.name, seed: user.avatarSeed,
                                                     size: CGSize(width: 88, height: 88))
        cell.imageView?.layer.cornerRadius = 22
        cell.imageView?.layer.masksToBounds = true
        cell.textLabel?.text = user.name
        cell.textLabel?.textColor = p.text
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        cell.detailTextLabel?.text = "\(user.handle) · \(user.status)"
        cell.detailTextLabel?.textColor = user.online ? p.green : p.text2
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = sections[indexPath.section].users[indexPath.row]
        let profile = ProfileViewController(user: user)
        navigationController?.pushViewController(profile, animated: true)
    }

    @objc private func addContact() {
        let alert = UIAlertController(title: "Новый контакт", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Имя" }
        alert.addTextField { $0.placeholder = "Никнейм" }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            let handle = alert.textFields?[1].text ?? "@new"
            let user = PulseUser(id: "new_\(UUID().uuidString)", name: name, handle: handle,
                                 avatarSeed: Int.random(in: 1...9999), online: false,
                                 status: "новый контакт", bio: "Добавлен вручную", isContact: true)
            Storage.shared.update { $0.users.append(user) }
            Feedback.shared.success()
            self?.reload()
        })
        present(alert, animated: true)
    }
}
