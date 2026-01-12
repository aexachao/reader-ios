import Foundation
import Combine

final class URLStore: ObservableObject {
    @Published private(set) var items: [URLItem] = []
    @Published var selectedID: UUID? = nil
    @Published var lastVisitedURLString: String? = nil

    private let userDefaultsKey = "阅读.urlstore.items.v1"
    private let userDefaultsSelectedKey = "阅读.urlstore.selected.v1"
    private let userDefaultsLastVisitedKey = "阅读.urlstore.lastVisited.v1"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        loadLastVisited()
        // 当 items 变化时自动保存
        $items
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)

        // 当 selectedID 变化时自动保存
        $selectedID
            .sink { [weak self] _ in self?.saveSelectedID() }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    func add(name: String, urlString: String) {
        let item = URLItem(name: name, urlString: urlString)
        items.append(item)
        if selectedID == nil { selectedID = item.id }
        log("Added URLItem: \(item)")
        // persist immediately to avoid race conditions
        save()
    }

    func update(id: UUID, name: String, urlString: String) {
        // prevent editing the currently selected (in-use) item
        if selectedID == id {
            log("Attempted to update selected item; operation ignored")
            return
        }
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].name = name
        items[idx].urlString = URLItem.normalized(urlString)
        log("Updated URLItem id=\(id)")
        save()
    }

    func remove(id: UUID) {
        // prevent removing the currently selected (in-use) item
        if selectedID == id {
            log("Attempted to remove selected item; operation ignored")
            return
        }
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let removed = items.remove(at: idx)
        log("Removed URLItem: \(removed)")
        save()
    }

    func select(id: UUID?) {
        selectedID = id
    }

    func setLastVisited(url: URL?) {
        lastVisitedURLString = url?.absoluteString
        saveLastVisited()
    }

    func lastVisitedURL() -> URL? {
        guard let s = lastVisitedURLString else { return nil }
        return URL(string: s)
    }

    func item(for id: UUID?) -> URLItem? {
        guard let id = id else { return nil }
        return items.first(where: { $0.id == id })
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            // also persist selectedID whenever items are saved
            saveSelectedID()
        } catch {
            log("Failed to save URLStore: \(error)")
        }
    }

    private func saveSelectedID() {
        if let id = selectedID {
            UserDefaults.standard.set(id.uuidString, forKey: userDefaultsSelectedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsSelectedKey)
        }
    }

    private func saveLastVisited() {
        UserDefaults.standard.set(lastVisitedURLString, forKey: userDefaultsLastVisitedKey)
    }

    private func loadLastVisited() {
        if let s = UserDefaults.standard.string(forKey: userDefaultsLastVisitedKey) {
            lastVisitedURLString = s
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            items = try JSONDecoder().decode([URLItem].self, from: data)
            log("Loaded \(items.count) URL items")
            // try to restore previously selected id
            if let s = UserDefaults.standard.string(forKey: userDefaultsSelectedKey), let uuid = UUID(uuidString: s), items.contains(where: { $0.id == uuid }) {
                selectedID = uuid
            } else if let first = items.first {
                // if there are items but no valid saved selected id, choose the first as sensible default
                selectedID = first.id
                saveSelectedID()
            } else {
                selectedID = nil
            }
        } catch {
            log("Failed to load URLStore: \(error)")
        }
    }

    // MARK: - Utilities

    private func log(_ message: String) {
        #if DEBUG
        print("[URLStore] \(message)")
        #endif
    }
}
