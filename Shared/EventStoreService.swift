import EventKit
import Foundation

/// 아이폰 기본 앱(미리 알림 · 캘린더)과 연결되는 유일한 창구
final class EventStoreService {
    static let shared = EventStoreService()
    let store = EKEventStore()

    enum ServiceError: LocalizedError {
        case notFound, noDefaultList
        var errorDescription: String? {
            switch self {
            case .notFound: "해당 할 일을 찾을 수 없어요."
            case .noDefaultList: "기본 미리 알림 목록이 없어요."
            }
        }
    }

    // MARK: 권한

    var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .fullAccess &&
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    @discardableResult
    func requestAccess() async throws -> Bool {
        let reminders = try await store.requestFullAccessToReminders()
        let events = try await store.requestFullAccessToEvents()
        return reminders && events
    }

    // MARK: 읽기

    func snapshot(for date: Date = .now) async -> CalendarSnapshot {
        guard hasAccess else { return .empty(date) }
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let month = cal.dateInterval(of: .month, for: date)!
        let week = cal.dateInterval(of: .weekOfYear, for: date)!
        let rangeStart = min(month.start, week.start)
        let rangeEnd = max(month.end, week.end)

        let open = await fetchReminders(store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: rangeEnd, calendars: nil))
        let doneToday = await fetchReminders(store.predicateForCompletedReminders(
            withCompletionDateStarting: dayStart, ending: dayEnd, calendars: nil))
        let events = store.events(matching: store.predicateForEvents(
            withStart: rangeStart, end: rangeEnd, calendars: nil))

        func due(_ r: EKReminder) -> Date? { r.dueDateComponents.flatMap { cal.date(from: $0) } }
        func item(_ r: EKReminder) -> TodoItem {
            .init(id: r.calendarItemIdentifier, title: r.title ?? "", due: due(r), isCompleted: r.isCompleted)
        }

        // 오늘 할 일 = 오늘까지 마감(밀린 것 포함) + 오늘 완료한 것
        let todayOpen = open.filter { (due($0) ?? .distantFuture) < dayEnd }.map(item)
            .sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
        let todayDone = doneToday.map(item)

        // 달력 점 찍기
        var marks: [Date: DayMarks] = [:]
        for e in events {
            let key = cal.startOfDay(for: e.startDate)
            marks[key, default: DayMarks()].hasEvent = true
            marks[key, default: DayMarks()].eventTitles.append(e.title ?? "")
        }
        for r in open {
            guard let d = due(r), d >= rangeStart else { continue }
            let key = cal.startOfDay(for: d)
            marks[key, default: DayMarks()].hasTodo = true
            marks[key, default: DayMarks()].todoTitles.append(r.title ?? "")
        }

        let mapped = events.map {
            EventItem(id: $0.eventIdentifier ?? UUID().uuidString, title: $0.title ?? "",
                      start: $0.startDate, end: $0.endDate, isAllDay: $0.isAllDay)
        }
        let todayEvents = mapped.filter { cal.isDate($0.start, inSameDayAs: date) }.sorted { $0.start < $1.start }
        let next = mapped.filter { !$0.isAllDay && $0.end > date }.min { $0.start < $1.start }

        return .init(date: date, hasAccess: true,
                     todayTodos: todayOpen + todayDone, todayEvents: todayEvents,
                     nextEvent: next, marks: marks)
    }

    private func fetchReminders(_ predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { cont.resume(returning: $0 ?? []) }
        }
    }

    // MARK: 쓰기

    /// 미리 알림에 할 일 추가 (+ 원하면 캘린더 일정도 함께)
    func addTodo(title: String, due: Date?, hasTime: Bool, alsoCalendar: Bool) throws {
        guard let list = store.defaultCalendarForNewReminders() else { throw ServiceError.noDefaultList }
        let cal = Calendar.current
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = list
        if let due {
            let parts: Set<Calendar.Component> = hasTime ? [.year, .month, .day, .hour, .minute] : [.year, .month, .day]
            reminder.dueDateComponents = cal.dateComponents(parts, from: due)
            if hasTime { reminder.addAlarm(EKAlarm(absoluteDate: due)) }
        }
        try store.save(reminder, commit: !alsoCalendar)

        if alsoCalendar, let due {
            let event = EKEvent(eventStore: store)
            event.title = title
            event.calendar = store.defaultCalendarForNewEvents
            if hasTime {
                event.startDate = due
                event.endDate = due.addingTimeInterval(30 * 60)
            } else {
                event.isAllDay = true
                event.startDate = cal.startOfDay(for: due)
                event.endDate = event.startDate
            }
            try store.save(event, span: .thisEvent, commit: false)
            try store.commit()
        }
    }

    /// 위젯 체크박스 탭 → 완료/미완료 토글
    func toggleCompletion(id: String) throws {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { throw ServiceError.notFound }
        reminder.isCompleted.toggle()
        try store.save(reminder, commit: true)
    }
}
