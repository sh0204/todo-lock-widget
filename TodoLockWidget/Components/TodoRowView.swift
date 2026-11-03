import AppIntents
import SwiftUI

/// ✅ 탭하면 위젯 안에서 바로 완료 처리되는 체크 버튼 행
struct TodoRowView: View {
    let item: TodoItem
    var tint: Color = Theme.todo
    var fontSize: CGFloat = 12

    var body: some View {
        Button(intent: ToggleTodoIntent(reminderID: item.id)) {
            HStack(spacing: 6) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: fontSize + 2))
                    .foregroundStyle(tint)
                Text(item.title)
                    .font(.system(size: fontSize, weight: .medium))
                    .strikethrough(item.isCompleted)
                    .opacity(item.isCompleted ? 0.45 : 1)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 일정 한 줄 (왼쪽 컬러 바)
struct EventRowView: View {
    let event: EventItem
    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.event).frame(width: 3)
            VStack(alignment: .leading, spacing: 0) {
                Text(event.title).font(.system(size: 12, weight: .bold)).lineLimit(1)
                Text(event.isAllDay ? "하루 종일" : "\(event.start.hm) – \(event.end.hm)")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
