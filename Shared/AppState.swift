import Foundation

/// 잠금화면 컨트롤 / URL 로 앱이 열렸을 때 빠른 입력 시트를 띄우기 위한 상태
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    @Published var showQuickAdd = false
}
