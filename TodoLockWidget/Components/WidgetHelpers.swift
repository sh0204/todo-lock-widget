import SwiftUI
import WidgetKit

extension WidgetFamily {
    var isAccessory: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }
}

extension View {
    /// 잠금화면은 반투명 배경, 홈 화면은 시스템 배경
    func widgetBackground(_ family: WidgetFamily) -> some View {
        containerBackground(for: .widget) {
            if family.isAccessory { AccessoryWidgetBackground() } else { Color(.systemBackground) }
        }
    }
}

extension Date {
    /// 14:00 형식
    var hm: String { formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) }
}

/// 권한이 없을 때 표시
struct NeedsAccessView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "lock.shield")
            Text("앱에서 권한을 허용해 주세요").font(.caption2).multilineTextAlignment(.center)
        }
        .widgetURL(URL(string: "todolock://open"))
    }
}

let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

/// 오늘이 속한 주의 7일 (일요일 시작)
func daysOfWeek(containing date: Date) -> [Date] {
    var cal = Calendar.current
    cal.firstWeekday = 1
    let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
    return (0..<7).map { cal.date(byAdding: .day, value: $0, to: start)! }
}

/// "11월 1주"
func weekTitle(_ date: Date) -> String {
    let cal = Calendar.current
    return "\(cal.component(.month, from: date))월 \(cal.component(.weekOfMonth, from: date))주"
}
