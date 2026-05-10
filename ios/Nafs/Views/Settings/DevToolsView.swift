import SwiftUI

/// Internal developer/marketing tools. Reached from Settings → Developer
/// Tools, which is only visible in DEBUG and TestFlight builds.
struct DevToolsView: View {
    let viewModel: AppViewModel

    @State private var screenTimeService = ScreenTimeService()
    @State private var manualLocked: Bool = DevToolsService.isManualLockActive
    @State private var prayerProgress: Double = Double(PrayerCompletionStore.completedCount(on: .now))
    @State private var streakValue: Double = Double(PrayerCompletionStore.currentStreakDays())
    @State private var showSuccessDemo: Bool = false
    @State private var demoPrayer: PrayerName = .maghrib
    @State private var widgetStreak: Double = 4
    @State private var widgetCompleted: Double = 3
    @State private var lastAction: String? = nil

    var body: some View {
        List {
            headerSection
            lockSection
            successSection
            demoDataSection
            widgetSection
            resetsSection
            if let lastAction { statusSection(lastAction) }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle("Developer Tools")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showSuccessDemo) {
            PrayerSuccessView(
                prayer: demoPrayer,
                completedCount: max(1, Int(prayerProgress)),
                totalCount: PrayerName.allCases.count,
                streak: max(1, Int(streakValue)),
                onContinue: { showSuccessDemo = false }
            )
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "hammer.fill")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Internal tools")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text("For testing and marketing capture only · \(DevToolsService.buildKind) build")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var lockSection: some View {
        Section {
            Toggle(isOn: $manualLocked) {
                Label("Manual Prayer Lock", systemImage: "lock.fill")
                    .foregroundStyle(NafsTheme.text)
            }
            .tint(NafsTheme.gold)
            .onChange(of: manualLocked) { _, new in
                if new {
                    if !DevToolsService.manualLock(screenTimeService) {
                        manualLocked = false
                        flash("Authorize Screen Time and select apps first.")
                    } else {
                        flash("Apps locked manually")
                    }
                } else {
                    DevToolsService.manualUnlock(screenTimeService)
                    flash("Apps unlocked")
                }
            }

            HStack {
                Label("Force Active Prayer", systemImage: "moon.stars.fill")
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Picker("", selection: $demoPrayer) {
                    ForEach(PrayerName.allCases, id: \.rawValue) { p in
                        Text(NafsStrings.prayerName(p)).tag(p)
                    }
                }
                .labelsHidden()
                .tint(NafsTheme.gold)
            }

            Button {
                triggerPreset(demoPrayer)
            } label: {
                Label("Trigger Prayer Lock Demo", systemImage: "shield.lefthalf.filled")
                    .foregroundStyle(NafsTheme.gold)
            }

            HStack(spacing: 8) {
                presetButton(label: "Maghrib", prayer: .maghrib)
                presetButton(label: "Asr", prayer: .asr)
                presetButton(label: "Fajr", prayer: .fajr)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Lock Screen")
        } footer: {
            Text("Uses your real selected apps and the production shield UI. The OS shield reads from the shared prayer-times payload, so 'Force Active Prayer' will appear as the current prayer until the next refresh.")
        }
    }

    private var successSection: some View {
        Section {
            Button {
                showSuccessDemo = true
            } label: {
                Label("Show Prayer Complete Screen", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(NafsTheme.gold)
            }
        } header: {
            Text("Success Screen")
        } footer: {
            Text("Renders the real 'Alhamdulillah, you've prayed' screen using current demo values.")
        }
    }

    private var demoDataSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Prayers completed today")
                        .foregroundStyle(NafsTheme.text)
                    Spacer()
                    Text("\(Int(prayerProgress))/\(PrayerName.allCases.count)")
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
                Slider(
                    value: $prayerProgress,
                    in: 0...Double(PrayerName.allCases.count),
                    step: 1,
                    onEditingChanged: { editing in
                        if !editing {
                            DevToolsService.setPrayerProgressToday(count: Int(prayerProgress))
                            flash("Today set to \(Int(prayerProgress))/\(PrayerName.allCases.count)")
                        }
                    }
                )
                .tint(NafsTheme.gold)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Streak (days)")
                        .foregroundStyle(NafsTheme.text)
                    Spacer()
                    Text("\(Int(streakValue))")
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
                Slider(
                    value: $streakValue,
                    in: 0...365,
                    step: 1,
                    onEditingChanged: { editing in
                        if !editing {
                            DevToolsService.setStreakDays(Int(streakValue))
                            prayerProgress = Double(PrayerCompletionStore.completedCount(on: .now))
                            flash("Streak set to \(Int(streakValue)) days")
                        }
                    }
                )
                .tint(NafsTheme.gold)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Demo Data")
        } footer: {
            Text("Only affects local demo/testing state on this device.")
        }
    }

    private var widgetSection: some View {
        Section {
            Stepper(value: $widgetStreak, in: 0...999, step: 1) {
                HStack {
                    Text("Widget streak")
                        .foregroundStyle(NafsTheme.text)
                    Spacer()
                    Text("\(Int(widgetStreak))")
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
            }
            Stepper(value: $widgetCompleted, in: 0...Double(PrayerName.allCases.count), step: 1) {
                HStack {
                    Text("Widget completed today")
                        .foregroundStyle(NafsTheme.text)
                    Spacer()
                    Text("\(Int(widgetCompleted))/\(PrayerName.allCases.count)")
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
            }
            Button {
                DevToolsService.setWidgetDemo(streak: Int(widgetStreak), completed: Int(widgetCompleted))
                flash("Widgets updated with demo values")
            } label: {
                Label("Push Demo to Widgets", systemImage: "square.grid.2x2.fill")
                    .foregroundStyle(NafsTheme.gold)
            }
            Button {
                DevToolsService.refreshWidgets()
                flash("Widget timelines reloaded")
            } label: {
                Label("Refresh Widget Demo State", systemImage: "arrow.clockwise")
                    .foregroundStyle(NafsTheme.gold)
            }
        } header: {
            Text("Widget Testing")
        }
    }

    private var resetsSection: some View {
        Section {
            resetRow("Reset Onboarding", icon: "arrow.uturn.backward.circle") {
                DevToolsService.resetOnboarding()
                flash("Onboarding reset — relaunch flow on next view")
            }
            resetRow("Reset Paywall Seen State", icon: "crown") {
                DevToolsService.resetPaywallSeen()
                flash("Paywall flags reset")
            }
            resetRow("Reset Prayer Progress", icon: "checkmark.circle") {
                DevToolsService.resetPrayerProgress()
                prayerProgress = 0
                flash("Today's prayer progress reset")
            }
            resetRow("Reset Prayer Streak", icon: "flame") {
                DevToolsService.resetPrayerStreak()
                streakValue = 0
                prayerProgress = 0
                flash("Prayer streak reset")
            }
            resetRow("Reset Widget Demo Data", icon: "square.grid.2x2") {
                DevToolsService.resetWidgetDemoData()
                flash("Widget demo data reset")
            }
            resetRow("Reset App Selection", icon: "app.badge") {
                DevToolsService.resetAppSelection(screenTimeService)
                manualLocked = false
                flash("App selection cleared")
            }
            resetRow("Reset Review Prompt State", icon: "star") {
                DevToolsService.resetReviewPromptState()
                flash("Review prompt state reset")
            }
        } header: {
            Text("Resets")
        } footer: {
            Text("Use these to re-record videos or screenshots cleanly. None of these touch RevenueCat or premium entitlements.")
        }
    }

    private func statusSection(_ msg: String) -> some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(NafsTheme.gold)
                Text(msg)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Helpers

    private func presetButton(label: String, prayer: PrayerName) -> some View {
        Button {
            demoPrayer = prayer
            triggerPreset(prayer)
        } label: {
            Text(label)
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(NafsTheme.gold.opacity(0.1))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func triggerPreset(_ prayer: PrayerName) {
        DevToolsService.forceActivePrayer(prayer)
        guard DevToolsService.manualLock(screenTimeService) else {
            flash("Authorize Screen Time and select apps first.")
            return
        }
        manualLocked = true
        flash("Locked for \(NafsStrings.prayerName(prayer))")
    }

    private func resetRow(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
    }

    private func flash(_ msg: String) {
        lastAction = msg
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if lastAction == msg { lastAction = nil }
        }
    }
}
