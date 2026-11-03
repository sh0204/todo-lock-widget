import SwiftUI
import WidgetKit

// MARK: - 사각형 · 오늘 할 일

struct LockTodayView: View {
    let s: CalendarSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                Text("오늘 할 일").fontWeight(.bold)
                Spacer()
                Text("\(s.remainingCount)").font(.system(size: 13, weight: .bold, design: .rounded)).opacity(0.75)
            }
            .font(.system(size: 12))
            if s.todayTodos.isEmpty {
                Text("할 일 없음 🎉").font(.system(size: 12)).opacity(0.7)
            } else {
                ForEach(s.todayTodos.prefix(2)) { TodoRowView(item: $0, tint: .primary) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 원형 · 진행률

struct LockProgressView: View {
    let s: CalendarSnapshot
    var body: some View {
        Gauge(value: Double(s.completedCount), in: 0...Double(max(s.totalCount, 1))) {
            Image(systemName: "checklist")
        } currentValueLabel: {
            VStack(spacing: -2) {
                Text("\(s.completedCount)/\(s.totalCount)").font(.system(size: 15, weight: .bold, design: .rounded))
                Text("완료").font(.system(size: 8))
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

// MARK: - 원형 / 인라인 · 다음 일정

struct LockNextEventView: View {
    let s: CalendarSnapshot
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if family == .accessoryInline {
            if let e = s.nextEvent {
                Label("\(e.start.hm) \(e.title)", systemImage: "calendar")
            } else {
                Label("남은 일정 없음", systemImage: "calendar")
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "calendar").font(.system(size: 10))
                    Text(s.nextEvent?.start.hm ?? "--:--")
                        .font(.system(size: 15, weight: .bold, design: .rounded)).minimumScaleFactor(0.6)
                    Text(s.nextEvent?.title ?? "없음").font(.system(size: 8)).lineLimit(1)
                }
                .padding(6)
            }
        }
    }
}

// MARK: - 사각형 · 주간 스트립

struct LockWeekView: View {
    let s: CalendarSnapshot
    var body: some View {
        let days = daysOfWeek(containing: s.date)
        let todoCount = days.reduce(0) { $0 + s.marks(on: $1).todoTitles.count }
        VStack(spacing: 2) {
            HStack {
                Text(weekTitle(s.date)).font(.system(size: 11, weight: .bold))
                Spacer()
                Text("할 일 \(todoCount)").font(.system(size: 10, weight: .medium)).opacity(0.75)
            }
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let m = s.marks(on: day)
                    VStack(spacing: 1) {
                        Text(weekdaySymbols[i]).font(.system(size: 8, weight: .medium)).opacity(0.65)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(isToday ? Color.primary : .clear))
                            .foregroundStyle(isToday ? Color.black : .primary)
                        Circle().frame(width: 4, height: 4).opacity(m.hasEvent || m.hasTodo ? 0.9 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
