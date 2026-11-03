import AppIntents
import SwiftUI

@main
struct TodoLockApp: App {
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .onOpenURL { url in
                    if url.host == "add" { state.showQuickAdd = true }
                }
        }
    }
}

/// Siri · 단축어 앱에 '할 일 추가' 자동 등록
struct TodoLockShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTodoIntent(),
            phrases: ["\(.applicationName)에 할 일 추가", "\(.applicationName) 할 일"],
            shortTitle: "할 일 추가",
            systemImageName: "text.badge.plus")
    }
}
