#if os(iOS)
import GridWalkKit
import SwiftUI

struct PhoneRootView: View {
    @Bindable var model: AppModel
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                ScrollView {
                    content(now: context.date)
                        .padding()
                }
            }
            .background(GridTheme.asphalt.ignoresSafeArea())
            .navigationTitle("Grid Walk")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showSettings = true
                    }
                    .tint(GridTheme.pitWhite)
                }
            }
            .toolbarBackground(GridTheme.asphalt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(model: model)
                        .navigationTitle("Settings")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
            .task { await model.run() }
        }
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            if let next = model.nextSession(at: now) {
                VStack(alignment: .leading, spacing: 10) {
                    SessionTagChip(kind: next.session.kind)
                    Text(next.session.kind.displayName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(GridTheme.pitWhite)
                    CountdownText(date: next.session.dateUTC, now: now, size: 64)
                    Text(next.weekend.name)
                        .foregroundStyle(GridTheme.muted)
                    Text(LocalTimeFormat.sessionDateTime(next.session.dateUTC))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(GridTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(GridTheme.graphite, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text("No upcoming sessions")
                    .foregroundStyle(GridTheme.muted)
            }

            if let weekend = model.currentWeekend(at: now) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Weekend")
                            .font(.headline)
                            .foregroundStyle(GridTheme.pitWhite)
                        if weekend.isSprintWeekend {
                            Text("Sprint")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(GridTheme.sprint.opacity(0.2), in: Capsule())
                                .foregroundStyle(GridTheme.sprint)
                        }
                    }
                    Text("\(weekend.circuitName) · \(weekend.locality)")
                        .font(.caption)
                        .foregroundStyle(GridTheme.muted)

                    SessionList(weekend: weekend, nextSessionID: model.nextSession(at: now)?.session.id, now: now)
                }

                Button("Add weekend to Calendar") {
                    Task { await model.addToCalendar(weekend) }
                }
                .buttonStyle(.borderedProminent)
                .tint(GridTheme.startRed)
            }

            if let result = model.calendarResult {
                CalendarResultText(result: result)
            }
        }
    }
}
#endif
