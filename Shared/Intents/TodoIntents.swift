import AppIntents
import WidgetKit

/// ✅ 위젯 체크박스 — 앱을 열지 않고 위젯 안에서 바로 완료 처리 (iOS 17+ 인터랙티브 위젯)
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "할 일 완료 토글"
    static var isDiscoverable = false

    @Parameter(title: "미리 알림 ID") var reminderID: String

    init() {}
    init(reminderID: String) { self.reminderID = reminderID }

    func perform() async throws -> some IntentResult {
        try EventStoreService.shared.toggleCompletion(id: reminderID)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// ➕ 할 일 추가 — Siri · 단축어 · 액션 버튼에서 실행 가능
struct AddTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "할 일 추가"
    static var description = IntentDescription("미리 알림에 할 일을 추가하고 캘린더에도 표시해요.")

    @Parameter(title: "할 일", requestValueDialog: "할 일이 뭐예요?")
    var todoTitle: String

    @Parameter(title: "언제", requestValueDialog: "언제까지 할까요?")
    var due: Date?

    @Parameter(title: "캘린더에도 표시", default: true)
    var alsoCalendar: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try EventStoreService.shared.addTodo(title: todoTitle, due: due, hasTime: due != nil, alsoCalendar: alsoCalendar)
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "‘\(todoTitle)’ 추가했어요 ✅")
    }
}

/// 🔒 잠금화면 컨트롤 → 앱의 빠른 입력 화면 열기
struct OpenQuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "빠른 입력 열기"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { AppState.shared.showQuickAdd = true }
        return .result()
    }
}
