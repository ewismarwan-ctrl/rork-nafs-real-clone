import SwiftUI
import UserNotifications

struct CirclesView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @Environment(LanguageManager.self) private var lang
    @State private var hasCircle: Bool = false
    @State private var circleName: String = ""
    @State private var circleID: String = ""
    @State private var showCreateSheet: Bool = false
    @State private var showShareSheet: Bool = false

    private var inviteURLString: String {
        NafsConstants.circleInviteURL(circleID: circleID, circleName: circleName)
    }

    private var inviteURL: URL {
        URL(string: inviteURLString) ?? URL(string: NafsConstants.appStoreURL)!
    }

    private var inviteMessage: String {
        let name = circleName.isEmpty ? "my Circle" : circleName
        return "Join \(name) on Nafs and let's hold each other accountable! Tap to join: \(inviteURLString)"
    }

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()

            if viewModel.isPremium {
                if hasCircle {
                    circleContent
                } else {
                    emptyState
                }
            } else {
                PremiumGateView(
                    icon: "person.3.fill",
                    title: "Circles",
                    subtitle: "Accountability with the people you love most. Circles are available on Nafs Premium. Build your accountability group today.",
                    storeViewModel: storeViewModel
                )
            }
        }
        .navigationTitle(L10n.text("Circles", "الحلقات"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateSheet) {
            createCircleSheet
                .presentationDetents([.medium])
        }
        .onAppear {
            loadCircleData()
        }
    }

    private func loadCircleData() {
        hasCircle = UserDefaults.standard.bool(forKey: "nafs_hasCircle")
        circleName = UserDefaults.standard.string(forKey: "nafs_circleName") ?? ""
        if let existing = UserDefaults.standard.string(forKey: "nafs_circleID"), !existing.isEmpty {
            circleID = existing
        } else if hasCircle {
            let newID = Self.makeCircleID()
            UserDefaults.standard.set(newID, forKey: "nafs_circleID")
            circleID = newID
        }
    }

    private static func makeCircleID() -> String {
        let chars = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.10))
                    .frame(width: 108, height: 108)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(spacing: 8) {
                Text(L10n.text("Your Circle Starts Here", "حلقتك تبدأ هنا"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("Invite friends and stay accountable together", "ادعُ أصدقاءك وتحاسبوا معاً"))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                NafsButton(title: L10n.text("Create Circle", "أنشئ حلقة")) {
                    showCreateSheet = true
                }

                ShareLink(
                    item: inviteURL,
                    subject: Text("Join me on Nafs"),
                    message: Text(inviteMessage)
                ) {
                    Text(L10n.text("Invite Friends", "ادعُ الأصدقاء"))
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(NafsTheme.gold.opacity(0.10))
                        .clipShape(.capsule)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Create Sheet

    private var createCircleSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(L10n.text("Create Your Circle", "أنشئ حلقتك"))
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)

                TextField(L10n.text("Circle name", "اسم الحلقة"), text: $circleName)
                    .font(.system(.body))
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 14))
                    .onSubmit {
                        if !circleName.isEmpty {
                            createCircle()
                        }
                    }

                Text(L10n.text("Share your invite link with friends and family", "شارك رابط الدعوة مع عائلتك وأصدقائك"))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)

                NafsButton(title: L10n.text("Create Circle", "إنشاء حلقة"), isEnabled: !circleName.isEmpty) {
                    createCircle()
                }

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("Cancel", "إلغاء")) {
                        showCreateSheet = false
                    }
                    .foregroundStyle(NafsTheme.gold)
                }
            }
        }
    }

    private func createCircle() {
        let trimmed = circleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        circleName = trimmed
        let newID = Self.makeCircleID()
        circleID = newID
        hasCircle = true
        UserDefaults.standard.set(true, forKey: "nafs_hasCircle")
        UserDefaults.standard.set(trimmed, forKey: "nafs_circleName")
        UserDefaults.standard.set(newID, forKey: "nafs_circleID")
        showCreateSheet = false
    }

    // MARK: - Circle Content (real data only)

    private var circleContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                circleHeader
                youCard
                membersWaitingState
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private var circleHeader: some View {
        VStack(spacing: 12) {
            Text(circleName)
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            Text(L10n.text("1 member", "عضو واحد"))
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)

            ShareLink(
                item: inviteURL,
                subject: Text("Join my Circle on Nafs"),
                message: Text(inviteMessage)
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text(L10n.text("Send Invite Link", "إرسال رابط الدعوة"))
                }
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(NafsTheme.gold.opacity(0.1))
                .clipShape(.capsule)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var youCard: some View {
        let userName = viewModel.userName.isEmpty ? L10n.text("You", "أنت") : viewModel.userName
        let consistency = viewModel.prayerConsistency
        let weekly = viewModel.weeklyEarned.reduce(0, +)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(NafsTheme.card, lineWidth: 4)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: max(0.02, min(consistency, 1.0)))
                    .stroke(NafsTheme.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text(String(userName.prefix(1)).uppercased())
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(userName)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Text("\(Int(consistency * 100))% " + L10n.text("prayer consistency", "انتظام الصلاة"))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(weekly)")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                Text(L10n.text("this week", "هذا الأسبوع"))
                    .font(.system(.caption2))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var membersWaitingState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(NafsTheme.gold.opacity(0.7))

            Text(L10n.text("Waiting for members", "بانتظار الأعضاء"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            Text(L10n.text("Share your invite link — members will appear here once they join.", "شارك رابط الدعوة — سيظهر الأعضاء هنا عند انضمامهم."))
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            ShareLink(
                item: inviteURL,
                subject: Text("Join my Circle on Nafs"),
                message: Text(inviteMessage)
            ) {
                Text(L10n.text("Invite Friends", "ادعُ الأصدقاء"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.capsule)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }
}
