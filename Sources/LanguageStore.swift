//
//  LanguageStore.swift
//  Fuchen
//
//  Observable language preference. UI observes `current` for live
//  zh-Hans ↔ en switching; persistence stays in Store.
//

import Combine
import Foundation

extension Notification.Name {
    static let fuchenLanguageDidChange = Notification.Name("fuchenLanguageDidChange")
    static let fuchenNavigate = Notification.Name("fuchenNavigate")
}

@MainActor
final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()

    @Published private(set) var current: AppLanguage

    private init() {
        current = Store.language
        NotificationCenter.default.addObserver(
            forName: .fuchenLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, let lang = note.object as? AppLanguage else { return }
            self.current = lang
        }
    }

    func setLanguage(_ language: AppLanguage) {
        guard current != language else { return }
        Store.language = language
    }
}
