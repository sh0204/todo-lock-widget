import SwiftUI
import WidgetKit

// MARK: - 소형 · 오늘

struct HomeTodayView: View {
    let s: CalendarSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(s.date, format: .dateTime.day()).font(.system(size: 30, weight: .bold))
                VStack(alignment: .leading, spacing: 0) {
                    Text(s.date, format: .dateTime.weekday(.wide)).font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.event)
                    Text(s.date, format: .dateTime.month(.wide)).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            if let e = s.todayEvents.first { EventRowView(event: e) }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(s.todayTodos.prefix(s.todayEvents.isEmpty ? 4 : 2)) { TodoRowView(item: $0) }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 중형 · 주간

struct HomeWeekView: View {
    let s: CalendarSnapshot
    var body: some View {
        let days = daysOfWeek(containing: s.date)
        let todoCount = days.reduce(0) { $0 + s.marks(on: $1).todoTitles.count }
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Text(weekTitle(s.date)).font(.system(size: 14, weight: .bold))
                Text("\(days.first!.formatted(.dateTime.month(.defaultDigits).day())) – \(days.last!.formatted(.dateTime.month(.defaultDigits).day()))")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Text("할 일 \(todoCount)").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.todo)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Theme.todo.opacity(0.14)))
            }
            HStack(alignment: .top, spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let m = s.marks(on: day)
                    let chips = m.eventTitles.map { ($0, Theme.event) } + m.todoTitles.map { ($0, Theme.todo) }
                    VStack(spacing: 4) {
                        Text(weekdaySymbols[i]).font(.system(size: 10, weight: .medium))
                            .foregroundStyle(i == 0 ? Theme.sunday : .secondary)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isToday ? .white : (i == 0 ? Theme.sunday : .primary))
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(isToday ? Theme.event : .clear))
                        ForEach(Array(chips.prefix(2).enumerated()), id: \.offset) { _, chip in
                            Text(chip.0).font(.system(size: 9, weight: .bold)).foregroundStyle(chip.1).lineLimit(1)
                                .frame(maxWidth: .infinity).padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(chip.1.opacity(0.15)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 대형 · 월간

struct HomeMonthView: View {
    let s: CalendarSnapshot
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let cal = Calendar.current
        let monthStart = cal.dateInterval(of: .month, for: s.date)!.start
        let count = cal.range(of: .day, in: .month, for: s.date)!.count
        let leading = cal.component(.weekday, from: monthStart) - 1
        let cells: [Date?] = Array(repeating: nil, count: leading)
            + (0..<count).map { cal.date(byAdding: .day, value: $0, to: monthStart) }

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(s.date, format: .dateTime.month(.wide)).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.event)
                Text(s.date, format: .dateTime.year()).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                Legend(color: Theme.event, text: "일정")
                Legend(color: Theme.todo, text: "할 일")
            }
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdaySymbols[i]).font(.system(size: 10, weight: .medium))
                        .foregroundStyle(i == 0 ? Theme.sunday : .secondary)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { idx, day in
                    if let day { DayCell(day: day, column: idx % 7, marks: s.marks(on: day)) }
                    else { Color.clear.frame(height: 36) }
                }
            }
            Divider()
            HStack(alignment: .top, spacing: 14) {
                if let e = s.todayEvents.first { EventRowView(event: e) }
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(s.todayTodos.prefix(2)) { TodoRowView(item: $0) }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private struct Legend: View {
        let color: Color; let text: String
        var body: some View {
            HStack(spacing: 3) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(text).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }

    private struct DayCell: View {
        let day: Date; let column: Int; let marks: DayMarks
        var body: some View {
            let isToday = Calendar.current.isDateInToday(day)
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isToday ? .white : (column == 0 ? Theme.sunday : .primary))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(isToday ? Theme.event : .clear))
                HStack(spacing: 2) {
                    if marks.hasEvent { Circle().fill(Theme.event).frame(width: 5, height: 5) }
                    if marks.hasTodo { Circle().fill(Theme.todo).frame(width: 5, height: 5) }
                }
                .frame(height: 5)
            }
            .frame(height: 36)
        }
    }
}
