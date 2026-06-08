//
//  LanguageToggle.swift
//  Fuchen
//
//  Segmented 简体中文 / English switcher used in Settings, top nav,
//  and the menu-bar HUD.
//

import SwiftUI

struct LanguageToggle: View {
    @ObservedObject private var languageStore = LanguageStore.shared
    var compact: Bool = false

    var body: some View {
        Picker("", selection: Binding(
            get: { languageStore.current },
            set: { languageStore.setLanguage($0) }
        )) {
            Text(compact ? "中文" : AppLanguage.zhHans.displayName).tag(AppLanguage.zhHans)
            Text(compact ? "EN" : AppLanguage.en.displayName).tag(AppLanguage.en)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: compact ? 96 : 180)
        .colorScheme(.dark)
    }
}
