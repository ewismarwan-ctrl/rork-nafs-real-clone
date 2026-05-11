import SwiftUI

/// Internal tools for screenshot / video capture in TestFlight and debug
/// builds. Hidden in production via `DevToolsService.isAvailable`.
struct DeveloperToolsView: View {
    let viewModel: AppViewModel

    @State private var screenTimeService = ScreenTimeService()
    @State private var dev = DevToolsService.shared
    @State private var showSuccess: Bool = false
    @State private var showResetSelectionConfirm: Bool = false
    @State private var lastSuccessCount: Int = 3
    @State private var lastSuccessStreak: Int = 4

    @Environment(LanguageManager.self) private var lang

    var body: some View {
        List {
            buildBadgeSection
            manualLockSection
            demoPresetsSection
            successScreenSection
            demoDataSection
            widgetSection
            resetsSection
            toastSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle("Developer Tools")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showSuccess) {
            PrayerSuccessView(
                prayer: .maghrib,
                completedCount: lastSuccessCount,
                totalCount: PrayerName.allCases.count,
                streak: lastSuccessStreak,
                onContinue: { showSuccess = false }
            )
        }
        .alert("Clear App Selection?", isPresented: $showResetSelectionConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                dev.resetAppSelection(using: screenTimeService)
            }
        } message: {
            Text("This removes all blocked apps and disables active shields.")
        }
    }

    // MARK: - Sections

    private var buildBadgeSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(NafsTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("For testing and marketing capture only")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                    Text("Hidden from production App Store builds")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
                Text(DevToolsService.buildLabel)
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.capsule)
            }
            .padding(.vertical, 4)
        }
    }

    private var manualLockSection: some View {
        Section {
            actionRow(icon: "lock.fill", title: "Manually Lock Selected Apps") {
                dev.manualLockNow(using: screenTimeService)
            }
            actionRow(icon: "lock.open.fill", title: "Manually Unlock Apps") {
                dev.manualUnlockNow(using: screenTimeService)
            }
        } header: {
            Text("Manual App Locking")
        } footer: {
            Text("Uses the apps you selected in Focus and the real Family Controls shield.")
        }
    }

    private var demoPresetsSection: some View {
        Section {
            actionRow(icon: "moon.stars.fill", title: "Trigger Maghrib • TikTok Lock") {
                dev.triggerLockDemo(.maghribTikTok, using: screenTimeService)
            }
            actionRow(icon: "sun.max.fill", title: "Trigger Asr • Instagram Lock") {
                dev.triggerLockDemo(.asrInstagram, using: screenTimeService)
            }
        } header: {
            Text("Demo Lock Screen Presets")
        } footer: {
            Text("Opens the chosen app to see the real shield. Adjust the selected apps in Focus to match the preset name.")
        }
    }

    private var successScreenSection: some View {
        Section {
            Stepper(value: $lastSuccessCount, in: 0...PrayerName.allCases.count) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(NafsTheme.gold)
                    Text("Completed today: \(lastSuccessCount)/\(PrayerName.allCases.count)")
                        .foregroundStyle(NafsTheme.text)
                }
            }
            Stepper(value: $lastSuccessStreak, in: 0...365) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(NafsTheme.gold)
                    Text("Streak preview: \(lastSuccessStreak)")
                        .foregroundStyle(NafsTheme.text)
                }
            }
            actionRow(icon: "sparkles", title: "Show Prayer Complete Screen") {
                showSuccess = true
            }
        } header: {
            Text("Demo Success Screen")
        }
    }

    private var demoDataSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Set today's progress")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                HStack(spacing: 8) {
                    ForEach(0...PrayerName.allCases.count, id: \.self) { n in
                        Button {
                            dev.setTodayProgress(n)
                        } label: {
                            Text("\(n)")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(NafsTheme.text)
                                .frame(width: 38, height: 38)
                                .background(NafsTheme.card)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(NafsTheme.cardBorder)
                                }
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("Set streak")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                HStack(spacing: 8) {
                    ForEach([1, 4, 7, 30, 100, 365], id: \.self) { n in
                        Button {
                            dev.setStreakDays(n)
                        } label: {
                            Text("\(n)d")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(NafsTheme.text)
                                .frame(minWidth: 44, minHeight: 38)
                                .padding(.horizontal, 6)
                                .background(NafsTheme.card)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(NafsTheme.cardBorder)
                                }
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Demo Data Controls")
        } footer: {
            Text("Writes real local data so widgets, Home, and Focus all reflect the value.")
        }
    }

    private var widgetSection: some View {
        Section {
            actionRow(icon: "arrow.clockwise.circle.fill", title: "Refresh Widget Demo State") {
                dev.refreshWidgetDemoState()
            }
        } header: {
            Text("Widget Testing")
        }
    }

    private var resetsSection: some View {
        Section {
            actionRow(icon: "arrow.uturn.backward", title: "Reset Onboarding") {
                dev.resetOnboarding()
            }
            actionRow(icon: "creditcard", title: "Reset Paywall Seen State") {
                dev.resetPaywallSeenState()
            }
            actionRow(icon: "list.bullet.rectangle", title: "Reset Prayer Progress") {
                dev.resetPrayerProgress()
            }
            actionRow(icon: "flame.circle", title: "Reset Prayer Streak") {
                dev.resetPrayerStreak()
            }
            actionRow(icon: "rectangle.on.rectangle.slash", title: "Reset Widget Demo Data") {
                dev.resetWidgetDemoData()
            }
            actionRow(icon: "app.badge", title: "Reset App Selection") {
                showResetSelectionConfirm = true
            }
            actionRow(icon: "star.slash", title: "Reset Review Prompt State") {
                dev.resetReviewPromptState()
            }
        } header: {
            Text("Reset Marketing States")
        }
    }

    @ViewBuilder
    private var toastSection: some View {
        if !dev.lastActionMessage.isEmpty {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(NafsTheme.gold)
                    Text(dev.lastActionMessage)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                    Spacer()
                }
                .padding(.vertical, 4)
                .sensoryFeedback(.success, trigger: dev.didFlash)
            }
        }
    }

    // MARK: - Helpers

    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body))
                    .foregroundStyle(NafsTheme.gold)
                    .frame(width: 26)
                Text(title)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
    }
}
