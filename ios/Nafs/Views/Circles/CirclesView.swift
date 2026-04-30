import SwiftUI
import UserNotifications

nonisolated struct UserCircle: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
}

@MainActor
enum CirclesStore {
    private static let key = "nafs_circles"
    private static let activeKey = "nafs_activeCircleID"
    private static let registryKey = "nafs_knownCircles"

    static func load() -> [UserCircle] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key),
           let circles = try? JSONDecoder().decode([UserCircle].self, from: data) {
            return circles
        }
        if defaults.bool(forKey: "nafs_hasCircle"),
           let name = defaults.string(forKey: "nafs_circleName"),
           let id = defaults.string(forKey: "nafs_circleID"),
           !name.isEmpty, !id.isEmpty {
            let migrated = [UserCircle(id: id, name: name)]
            save(migrated)
            registerKnown(migrated)
            return migrated
        }
        return []
    }

    static func save(_ circles: [UserCircle]) {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(circles) {
            defaults.set(data, forKey: key)
        }
        defaults.set(!circles.isEmpty, forKey: "nafs_hasCircle")
    }

    static func activeID() -> String? {
        UserDefaults.standard.string(forKey: activeKey)
    }

    static func setActiveID(_ id: String?) {
        if let id {
            UserDefaults.standard.set(id, forKey: activeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
    }

    static func addOrUpdate(_ circle: UserCircle) -> [UserCircle] {
        var circles = load()
        if let idx = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[idx] = circle
        } else {
            circles.append(circle)
        }
        save(circles)
        return circles
    }

    static func remove(id: String) -> [UserCircle] {
        var circles = load()
        circles.removeAll { $0.id == id }
        save(circles)
        if activeID() == id {
            setActiveID(circles.first?.id)
        }
        return circles
    }

    static func loadKnown() -> [UserCircle] {
        guard let data = UserDefaults.standard.data(forKey: registryKey),
              let known = try? JSONDecoder().decode([UserCircle].self, from: data) else {
            return []
        }
        return known
    }

    static func registerKnown(_ circle: UserCircle) {
        var known = loadKnown()
        if let idx = known.firstIndex(where: { $0.id == circle.id }) {
            known[idx] = circle
        } else {
            known.append(circle)
        }
        if let data = try? JSONEncoder().encode(known) {
            UserDefaults.standard.set(data, forKey: registryKey)
        }
    }

    static func registerKnown(_ circles: [UserCircle]) {
        for c in circles { registerKnown(c) }
    }

    static func findKnown(id: String) -> UserCircle? {
        loadKnown().first(where: { $0.id == id })
    }

    static func makeCircleID() -> String {
        let chars = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}

struct CirclesView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @Environment(LanguageManager.self) private var lang
    @State private var circles: [UserCircle] = []
    @State private var activeCircleID: String = ""
    @State private var showCreateSheet: Bool = false
    @State private var showJoinSheet: Bool = false
    @State private var newCircleName: String = ""
    @State private var joinCode: String = ""
    @State private var showCopiedToast: Bool = false
    @State private var joinErrorMessage: String?
    @State private var showLeaveConfirm: Bool = false

    private var activeCircle: UserCircle? {
        circles.first(where: { $0.id == activeCircleID }) ?? circles.first
    }

    private var inviteURLString: String {
        guard let circle = activeCircle else { return NafsConstants.appStoreURL }
        return NafsConstants.circleInviteURL(circleID: circle.id, circleName: circle.name)
    }

    private var inviteURL: URL {
        URL(string: inviteURLString) ?? URL(string: NafsConstants.appStoreURL)!
    }

    private var inviteMessage: String {
        let name = activeCircle?.name ?? "my Circle"
        return "Join \(name) on Nafs and let's hold each other accountable! Tap to join: \(inviteURLString)"
    }

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()

            if viewModel.isPremium {
                if circles.isEmpty {
                    emptyState
                } else {
                    circleContent
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
        .sheet(isPresented: $showJoinSheet) {
            joinCircleSheet
                .presentationDetents([.medium])
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                Text(L10n.text("Code copied", "تم نسخ الرمز"))
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.85))
                    .clipShape(.capsule)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            loadCircleData()
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .alert(L10n.text("Leave Circle?", "مغادرة الحلقة؟"), isPresented: $showLeaveConfirm) {
            Button(L10n.text("Cancel", "إلغاء"), role: .cancel) { }
            Button(L10n.text("Leave", "مغادرة"), role: .destructive) {
                leaveActiveCircle()
            }
        } message: {
            Text(L10n.text("Are you sure you want to leave this circle?", "هل أنت متأكد أنك تريد مغادرة هذه الحلقة؟"))
        }
    }

    private var leaveCircleButton: some View {
        Button {
            showLeaveConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(L10n.text("Leave Circle", "مغادرة الحلقة"))
            }
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.1))
            .clipShape(.capsule)
        }
    }

    private func loadCircleData() {
        circles = CirclesStore.load()
        if let stored = CirclesStore.activeID(), circles.contains(where: { $0.id == stored }) {
            activeCircleID = stored
        } else if let first = circles.first {
            activeCircleID = first.id
            CirclesStore.setActiveID(first.id)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems,
              let rawID = items.first(where: { $0.name == "circle" })?.value,
              !rawID.isEmpty else { return }
        let id = Self.normalizeCode(rawID)
        guard !id.isEmpty else { return }
        let name = items.first(where: { $0.name == "name" })?.value?
            .removingPercentEncoding ?? "Invited Circle"
        let circle = UserCircle(id: id, name: name)
        CirclesStore.registerKnown(circle)
        if !circles.contains(where: { $0.id == id }) {
            circles = CirclesStore.addOrUpdate(circle)
        }
        activeCircleID = id
        CirclesStore.setActiveID(id)
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

                Button {
                    showJoinSheet = true
                } label: {
                    Text(L10n.text("Join with Code", "الانضمام برمز"))
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

                TextField(L10n.text("Circle name", "اسم الحلقة"), text: $newCircleName)
                    .font(.system(.body))
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 14))
                    .onSubmit {
                        if !newCircleName.isEmpty {
                            createCircle()
                        }
                    }

                Text(L10n.text("Share your invite link with friends and family", "شارك رابط الدعوة مع عائلتك وأصدقائك"))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)

                NafsButton(title: L10n.text("Create Circle", "إنشاء حلقة"), isEnabled: !newCircleName.isEmpty) {
                    createCircle()
                }

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("Cancel", "إلغاء")) {
                        showCreateSheet = false
                        newCircleName = ""
                    }
                    .foregroundStyle(NafsTheme.gold)
                }
            }
        }
    }

    private var joinCircleSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(L10n.text("Join a Circle", "انضم إلى حلقة"))
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)

                TextField(L10n.text("Enter invite code", "أدخل رمز الدعوة"), text: $joinCode)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .padding(16)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: joinCode) { _, _ in
                        if joinErrorMessage != nil { joinErrorMessage = nil }
                    }

                if let err = joinErrorMessage {
                    Text(err)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Text(L10n.text("Enter the 8-character code from your friend's invite", "أدخل الرمز المكوّن من ٨ أحرف من دعوة صديقك"))
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                }

                NafsButton(
                    title: L10n.text("Join Circle", "انضمام"),
                    isEnabled: joinCode.trimmingCharacters(in: .whitespaces).count >= 6
                ) {
                    joinWithCode()
                }

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("Cancel", "إلغاء")) {
                        showJoinSheet = false
                        joinCode = ""
                    }
                    .foregroundStyle(NafsTheme.gold)
                }
            }
        }
    }

    private func createCircle() {
        let trimmed = newCircleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let circle = UserCircle(id: CirclesStore.makeCircleID(), name: trimmed)
        CirclesStore.registerKnown(circle)
        circles = CirclesStore.addOrUpdate(circle)
        activeCircleID = circle.id
        CirclesStore.setActiveID(circle.id)
        newCircleName = ""
        showCreateSheet = false
    }

    private func leaveActiveCircle() {
        guard let id = activeCircle?.id else { return }
        circles = CirclesStore.remove(id: id)
        if let stored = CirclesStore.activeID(), circles.contains(where: { $0.id == stored }) {
            activeCircleID = stored
        } else {
            activeCircleID = circles.first?.id ?? ""
        }
    }

    private static func normalizeCode(_ raw: String) -> String {
        let stripped = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "L", with: "1")
        return stripped
    }

    private func joinWithCode() {
        let code = Self.normalizeCode(joinCode)

        let allowed = Set("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        let formatValid = code.count >= 6 && code.count <= 12 && code.allSatisfy { allowed.contains($0) }

        guard formatValid else {
            joinErrorMessage = L10n.text("Invalid circle code", "رمز الحلقة غير صالح")
            return
        }

        if let existing = circles.first(where: { $0.id == code }) {
            activeCircleID = existing.id
            CirclesStore.setActiveID(existing.id)
            joinCode = ""
            joinErrorMessage = L10n.text("You're already in this Circle.", "أنت بالفعل في هذه الحلقة.")
            return
        }

        let known = CirclesStore.findKnown(id: code)
        let resolvedName = known?.name ?? L10n.text("Circle \(code.prefix(4))", "حلقة \(code.prefix(4))")
        let circle = UserCircle(id: code, name: resolvedName)

        CirclesStore.registerKnown(circle)
        circles = CirclesStore.addOrUpdate(circle)
        activeCircleID = circle.id
        CirclesStore.setActiveID(circle.id)
        joinCode = ""
        joinErrorMessage = nil
        showJoinSheet = false
    }

    private func copyActiveCode() {
        guard let code = activeCircle?.id else { return }
        UIPasteboard.general.string = code
        withAnimation(.spring(response: 0.35)) { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut) { showCopiedToast = false }
        }
    }

    // MARK: - Circle Content

    private var circleContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if circles.count > 1 {
                    circleSwitcher
                }
                circleHeader
                circleCodeCard
                youCard
                membersWaitingState
                additionalActions
                leaveCircleButton
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private var circleCodeCard: some View {
        let code = activeCircle?.id ?? ""
        let formatted = formatCode(code)
        return VStack(spacing: 14) {
            HStack {
                Label {
                    Text(L10n.text("Circle Code", "رمز الحلقة"))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                } icon: {
                    Image(systemName: "number")
                        .foregroundStyle(NafsTheme.gold)
                }
                Spacer()
                Text(L10n.text("Share to invite", "شارك للدعوة"))
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Text(formatted)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .tracking(4)
                .foregroundStyle(NafsTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(NafsTheme.gold.opacity(0.08))
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(NafsTheme.gold.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
                .contextMenu {
                    Button {
                        copyActiveCode()
                    } label: {
                        Label(L10n.text("Copy Code", "نسخ الرمز"), systemImage: "doc.on.doc")
                    }
                }

            HStack(spacing: 10) {
                Button {
                    copyActiveCode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text(L10n.text("Copy Code", "نسخ الرمز"))
                    }
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(NafsTheme.gold.opacity(0.1))
                    .clipShape(.capsule)
                }

                ShareLink(
                    item: code,
                    subject: Text("Join my Circle on Nafs"),
                    message: Text("Join my Nafs Circle with code \(code). Download Nafs: \(NafsConstants.appStoreURL)")
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.text("Share Code", "شارك الرمز"))
                    }
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.capsule)
                }
            }
        }
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private func formatCode(_ code: String) -> String {
        guard code.count > 4 else { return code }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<mid]) + "-" + String(code[mid...])
    }

    private var circleSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(circles) { circle in
                    let isActive = circle.id == activeCircleID
                    Button {
                        activeCircleID = circle.id
                        CirclesStore.setActiveID(circle.id)
                    } label: {
                        Text(circle.name)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(isActive ? .white : NafsTheme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if isActive {
                                        AnyView(NafsTheme.goldGradient)
                                    } else {
                                        AnyView(NafsTheme.gold.opacity(0.12))
                                    }
                                }
                            )
                            .clipShape(.capsule)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private var circleHeader: some View {
        VStack(spacing: 12) {
            Text(activeCircle?.name ?? "")
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

    private var additionalActions: some View {
        VStack(spacing: 10) {
            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.text("Create Another Circle", "إنشاء حلقة أخرى"))
                }
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NafsTheme.gold.opacity(0.1))
                .clipShape(.capsule)
            }

            Button {
                showJoinSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text(L10n.text("Join with Code", "الانضمام برمز"))
                }
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NafsTheme.gold.opacity(0.1))
                .clipShape(.capsule)
            }
        }
    }
}
