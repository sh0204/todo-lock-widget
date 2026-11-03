import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var snapshot = CalendarSnapshot.empty()
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if !snapshot.hasAccess {
                    Section {
                        Button("미리 알림 · 캘린더 권한 허용하기") { Task { await requestAccess() } }
                    } footer: {
                        Text("위젯이 기본 미리 알림 · 캘린더 앱의 데이터를 사용해요.")
                    }
                }
                Section("오늘 일정") {
                    if snapshot.todayEvents.isEmpty { Text("일정 없음").foregroundStyle(.secondary) }
                    ForEach(snapshot.todayEvents) { e in
                        HStack {
                            RoundedRectangle(cornerRadius: 2).fill(Theme.event).frame(width: 4)
                            Text(e.title)
                            Spacer()
                            Text(e.isAllDay ? "하루 종일" : e.start.formatted(date: .omitted, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("오늘 할 일 · \(snapshot.completedCount)/\(snapshot.totalCount)") {
                    ForEach(snapshot.todayTodos) { t in
                        Button { toggle(t) } label: {
                            Label {
                                Text(t.title).strikethrough(t.isCompleted).foregroundStyle(t.isCompleted ? .secondary : .primary)
                            } icon: {
                                Image(systemName: t.isCompleted ? "checkmark.circle.fill" : "circle").foregroundStyle(Theme.todo)
                            }
                        }
                    }
                }
            }
            .navigationTitle("할일락")
            .toolbar {
                Button { state.showQuickAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                    .tint(Theme.event)
            }
            .sheet(isPresented: $state.showQuickAdd, onDismiss: { Task { await reload() } }) {
                QuickAddView()
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(28)
            }
            .alert("오류", isPresented: .constant(error != nil)) { Button("확인") { error = nil } } message: { Text(error ?? "") }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    private func requestAccess() async {
        do { try await EventStoreService.shared.requestAccess() } catch { self.error = error.localizedDescription }
        await reload()
    }

    private func reload() async {
        snapshot = await EventStoreService.shared.snapshot()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func toggle(_ t: TodoItem) {
        do { try EventStoreService.shared.toggleCompletion(id: t.id) } catch { self.error = error.localizedDescription }
        Task { await reload() }
    }
}
