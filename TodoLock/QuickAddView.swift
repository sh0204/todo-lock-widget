import SwiftUI
import WidgetKit

/// Figma ‘② 빠른 입력’ 화면
struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss

    enum DatePreset: String, CaseIterable, Identifiable {
        case today = "오늘", tomorrow = "내일", weekend = "이번 주말", custom = "날짜 선택"
        var id: Self { self }
    }

    @State private var title = ""
    @State private var preset: DatePreset = .today
    @State private var customDate = Date.now
    @State private var hasTime = true
    @State private var time = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: .now)!
    @State private var alsoCalendar = true
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("할 일 추가", systemImage: "checklist").font(.headline)
                Spacer()
                Button("취소") { dismiss() }.foregroundStyle(.secondary)
            }

            TextField("할 일이 뭐예요?", text: $title)
                .font(.title3.weight(.medium))
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(.quaternary))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.event, lineWidth: focused ? 1.5 : 0))
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(save)

            Text("언제").font(.footnote.weight(.medium)).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DatePreset.allCases) { p in
                        Button(p.rawValue) { preset = p }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(preset == p ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.quaternary)))
                            .foregroundStyle(preset == p ? Color(.systemBackground) : .primary)
                    }
                }
            }
            if preset == .custom {
                DatePicker("날짜", selection: $customDate, displayedComponents: .date).datePickerStyle(.compact)
            }

            VStack(spacing: 0) {
                Toggle(isOn: $hasTime) { Label("시간", systemImage: "clock") }.padding(12)
                if hasTime {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute).labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing).padding(.horizontal, 12).padding(.bottom, 8)
                }
                Divider()
                Toggle(isOn: $alsoCalendar) { Label("캘린더에도 표시", systemImage: "calendar") }.padding(12)
            }
            .tint(.green)
            .background(RoundedRectangle(cornerRadius: 14).fill(.quaternary.opacity(0.6)))

            Button(action: save) {
                Text("추가하기").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent).tint(Theme.event)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(20)
        .onAppear { focused = true }
        .alert("저장 실패", isPresented: .constant(error != nil)) { Button("확인") { error = nil } } message: { Text(error ?? "") }
    }

    private var dueDate: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let day: Date = switch preset {
        case .today: today
        case .tomorrow: cal.date(byAdding: .day, value: 1, to: today)!
        case .weekend: cal.nextDate(after: today.addingTimeInterval(-1), matching: DateComponents(weekday: 7), matchingPolicy: .nextTime)!
        case .custom: cal.startOfDay(for: customDate)
        }
        guard hasTime else { return day }
        let hm = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(bySettingHour: hm.hour ?? 9, minute: hm.minute ?? 0, second: 0, of: day)!
    }

    private func save() {
        let text = title.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        do {
            try EventStoreService.shared.addTodo(title: text, due: dueDate, hasTime: hasTime, alsoCalendar: alsoCalendar)
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview { QuickAddView() }
