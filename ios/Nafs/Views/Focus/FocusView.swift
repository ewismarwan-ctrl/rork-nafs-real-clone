import SwiftUI
import FamilyControls

struct FocusView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel

    @State private var screenTimeService: ScreenTimeService = ScreenTimeService()
    @State private var showActivityPicker: Bool = false
    @State private var showResetConfirm: Bool = false
    @State private var prayerLockEnabled: Bool = true
    @State private var unlockMinutes: Int = 15
    @State private var insufficientBalance: Bool = false

    private let prayerLockKey: String = "nafs_prayerLockEnabled_v1"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    lockStatus
                    unlockRequirement
                    controls
                    selectedApps
                    hardReset
                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle("Lock")
            .navigationBarTitleDisplayMode(.large)
            .familyActivityPicker(isPresented: $showActivityPicker, selection: Binding(
                get: { screenTimeService.activitySelection },
                set: { selection in
                    screenTimeService.activitySelection = selection
                    screenTimeService.onSelectionChanged()
                    PrayerActivityScheduler.shared.updateSchedule(prayerTimes: viewModel.prayerTimes)
                }
            ))
            .alert("Not enough earned time", isPresented: $insufficientBalance) {
                Button("Earn first", role: .cancel) {}
            } message: {
                Text("Complete Salah, Quran, Dhikr, Reflection, or a Focus Session before unlocking distractions.")
            }
            .alert("Hard Reset", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { screenTimeService.clearAll() }
            } message: {
                Text("This removes blocked apps and turns off active shields.")
            }
        }
        .task { loadPrayerLockEnabled() }
        .onChange(of: prayerLockEnabled) { _, enabled in
            UserDefaults.standard.set(enabled, forKey: prayerLockKey)
            screenTimeService.setPrayerLockEnabled(enabled)
            if enabled { PrayerActivityScheduler.shared.updateSchedule(prayerTimes: viewModel.prayerTimes) }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earn your freedom.")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(NafsTheme.text)
            Text("Your apps unlock when you earn dopamine intentionally.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
            Text("Worship first. Dopamine later.")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
        }
        .padding(24)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 26))
        .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(NafsTheme.gold.opacity(0.25), lineWidth: 1) }
    }

    private var lockStatus: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $prayerLockEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prayer Blocking")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(prayerLockEnabled ? "Discipline earns freedom." : "Blocking is fully disabled.")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            .tint(NafsTheme.gold)

            HStack(spacing: 12) {
                statusPill("Available", "\(viewModel.earnedScreenTime.availableMinutes)m")
                statusPill("Locked Apps", "\(screenTimeService.selectedAppCount + screenTimeService.selectedCategoryCount)")
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }

    private func statusPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(.title3, weight: .bold)).foregroundStyle(NafsTheme.gold)
            Text(title).font(.system(.caption, weight: .semibold)).foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(NafsTheme.background)
        .clipShape(.rect(cornerRadius: 14))
    }

    private var unlockRequirement: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Unlock Requirement")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text(viewModel.earnedScreenTime.availableMinutes >= unlockMinutes ? "Spend \(unlockMinutes) earned minutes intentionally." : "Complete Salah to unlock. Control your nafs before it controls you.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("Minutes", selection: $unlockMinutes) {
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("60 min").tag(60)
            }
            .pickerStyle(.segmented)

            Button {
                if viewModel.spendEarnedMinutes(unlockMinutes) {
                    screenTimeService.temporaryUnlock(minutes: unlockMinutes)
                } else {
                    insufficientBalance = true
                }
            } label: {
                Text("Unlock with Earned Time")
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.rect(cornerRadius: 16))
            }

            Button { viewModel.recordFocusCompleted(minutes: 25) } label: {
                Text("Lock In / Focus Session (+15 min)")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(NafsTheme.gold.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    private var selectedApps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Blocked Apps")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text(screenTimeService.hasSelection ? "\(screenTimeService.selectedAppCount) apps · \(screenTimeService.selectedCategoryCount) categories" : "No apps selected yet.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
            Button("Choose Apps to Block") { showActivityPicker = true }
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var hardReset: some View {
        Button { showResetConfirm = true } label: {
            Text("Hard Reset")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(.red.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.red.opacity(0.07))
                .clipShape(.rect(cornerRadius: 14))
        }
    }

    private func loadPrayerLockEnabled() {
        if UserDefaults.standard.object(forKey: prayerLockKey) == nil {
            prayerLockEnabled = true
            UserDefaults.standard.set(true, forKey: prayerLockKey)
        } else {
            prayerLockEnabled = UserDefaults.standard.bool(forKey: prayerLockKey)
        }
        screenTimeService.setPrayerLockEnabled(prayerLockEnabled)
    }
}

nonisolated enum FocusMode: String, Sendable {
    case auto
    case earn
}
