import Foundation

/// 미리 알림 한 건
struct TodoItem: Identifiable, Hashable {
    let id: String          // EKReminder.calendarItemIdentifier
    let title: String
    let due: Date?
    let isCompleted: Bool
}

/// 캘린더 일정 한 건
struct EventItem: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
}

/// 달력 칸에 찍히는 점 (보라 = 일정, 주황 = 할 일)
struct DayMarks: Hashable {
    var hasEvent = false
    var hasTodo = false
    var eventTitles: [String] = []
    var todoTitles: [String] = []
}

/// 위젯 한 번 그릴 때 필요한 데이터 묶음
struct CalendarSnapshot {
    var date: Date
    var hasAccess: Bool
    var todayTodos: [TodoItem]
    var todayEvents: [EventItem]
    var nextEvent: EventItem?
    /// key = 그 날의 startOfDay
    var marks: [Date: DayMarks]

    var completedCount: Int { todayTodos.filter(\.isCompleted).count }
    var totalCount: Int { todayTodos.count }
    var remainingCount: Int { totalCount - completedCount }

    func marks(on day: Date) -> DayMarks {
        marks[Calendar.current.startOfDay(for: day)] ?? DayMarks()
    }

    static func empty(_ date: Date = .now, hasAccess: Bool = false) -> CalendarSnapshot {
        .init(date: date, hasAccess: hasAccess, todayTodos: [], todayEvents: [], nextEvent: nil, marks: [:])
    }

    /// 위젯 갤러리 / 미리보기용 샘플 데이터 (Figma 디자인과 동일)
    static var placeholder: CalendarSnapshot {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func at(_ h: Int) -> Date { cal.date(bySettingHour: h, minute: 0, second: 0, of: today)! }
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: today)! }
        let review = EventItem(id: "e1", title: "디자인 리뷰", start: at(14), end: at(15), isAllDay: false)
        var marks: [Date: DayMarks] = [:]
        marks[today] = DayMarks(hasEvent: true, hasTodo: true, eventTitles: ["리뷰"], todoTitles: ["장보기"])
        marks[day(1)] = DayMarks(hasTodo: true, todoTitles: ["치과"])
        marks[day(2)] = DayMarks(hasEvent: true, eventTitles: ["회식"])
        marks[day(4)] = DayMarks(hasEvent: true, hasTodo: true, eventTitles: ["여행"], todoTitles: ["청소"])
        marks[day(9)] = DayMarks(hasTodo: true)
        marks[day(11)] = DayMarks(hasEvent: true)
        return .init(
            date: .now, hasAccess: true,
            todayTodos: [
                .init(id: "r1", title: "치과 예약 전화", due: at(15), isCompleted: false),
                .init(id: "r2", title: "운동 30분", due: at(19), isCompleted: false),
                .init(id: "r3", title: "장보기", due: at(10), isCompleted: true),
            ],
            todayEvents: [review], nextEvent: review, marks: marks)
    }
}
