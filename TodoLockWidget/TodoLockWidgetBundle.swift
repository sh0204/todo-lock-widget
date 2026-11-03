import SwiftUI
import WidgetKit

@main
struct TodoLockWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()        // 잠금 사각형 · 홈 소형
        ProgressWidget()     // 잠금 원형
        NextEventWidget()    // 잠금 원형 · 인라인
        WeekWidget()         // 잠금 사각형 · 홈 중형
        MonthWidget()        // 홈 대형
        QuickAddControl()    // 잠금화면 하단 컨트롤 (iOS 18)
    }
}

/// 위젯 공통 래퍼 — 권한 체크 + 배경
private struct WidgetShell<Content: View>: View {
    let entry: TodoEntry
    @ViewBuilder let content: (CalendarSnapshot) -> Content
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if entry.snapshot.hasAccess { content(entry.snapshot) } else { NeedsAccessView() }
        }
        .widgetBackground(family)
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: Provider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("오늘 할 일")
        .description("오늘 할 일과 일정을 보고 바로 체크해요.")
        .supportedFamilies([.accessoryRectangular, .systemSmall])
    }
}
private struct TodayWidgetView: View {
    let entry: TodoEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        WidgetShell(entry: entry) { s in
            if family == .systemSmall { HomeTodayView(s: s) } else { LockTodayView(s: s) }
        }
    }
}

struct ProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ProgressWidget", provider: Provider()) { entry in
            WidgetShell(entry: entry) { LockProgressView(s: $0) }
        }
        .configurationDisplayName("할 일 진행률")
        .description("오늘 할 일을 얼마나 끝냈는지 보여줘요.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct NextEventWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextEventWidget", provider: Provider()) { entry in
            WidgetShell(entry: entry) { LockNextEventView(s: $0) }
        }
        .configurationDisplayName("다음 일정")
        .description("캘린더의 다음 일정을 보여줘요.")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

struct WeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekWidget", provider: Provider()) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName("주간 캘린더")
        .description("이번 주 일정과 할 일을 한눈에.")
        .supportedFamilies([.accessoryRectangular, .systemMedium])
    }
}
private struct WeekWidgetView: View {
    let entry: TodoEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        WidgetShell(entry: entry) { s in
            if family == .systemMedium { HomeWeekView(s: s) } else { LockWeekView(s: s) }
        }
    }
}

struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MonthWidget", provider: Provider()) { entry in
            WidgetShell(entry: entry) { HomeMonthView(s: $0) }
        }
        .configurationDisplayName("월간 캘린더")
        .description("한 달 일정과 할 일, 오늘 할 일 체크까지.")
        .supportedFamilies([.systemLarge])
    }
}

/// 🔒 잠금화면 하단 / 제어 센터 / 액션 버튼에 넣는 '할 일 추가' 버튼
struct QuickAddControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "QuickAddControl") {
            ControlWidgetButton(action: OpenQuickAddIntent()) {
                Label("할 일 추가", systemImage: "text.badge.plus")
            }
        }
        .displayName("할 일 추가")
        .description("잠금화면에서 바로 할 일을 입력해요.")
    }
}

#Preview("잠금 · 오늘", as: .accessoryRectangular) { TodayWidget() } timeline: { TodoEntry(date: .now, snapshot: .placeholder) }
#Preview("홈 · 주간", as: .systemMedium) { WeekWidget() } timeline: { TodoEntry(date: .now, snapshot: .placeholder) }
#Preview("홈 · 월간", as: .systemLarge) { MonthWidget() } timeline: { TodoEntry(date: .now, snapshot: .placeholder) }
