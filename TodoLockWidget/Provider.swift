import WidgetKit

struct TodoEntry: TimelineEntry {
    let date: Date
    let snapshot: CalendarSnapshot
}

/// 미리 알림 · 캘린더에서 데이터를 읽어 위젯 타임라인을 만든다
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        if context.isPreview { return completion(placeholder(in: context)) }
        Task { completion(TodoEntry(date: .now, snapshot: await EventStoreService.shared.snapshot())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        Task {
            let now = Date.now
            let snap = await EventStoreService.shared.snapshot(for: now)
            // 다음 일정 시작 · 30분 후 · 자정 중 가장 빠른 시점에 갱신
            let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
            var refresh = min(now.addingTimeInterval(30 * 60), midnight)
            if let next = snap.nextEvent, next.start > now { refresh = min(refresh, next.start) }
            completion(Timeline(entries: [TodoEntry(date: now, snapshot: snap)], policy: .after(refresh)))
        }
    }
}
