import SwiftUI
import FamilyControls
import UserNotifications

nonisolated enum OBData {
    static let ageRanges = ["13–17", "18–24", "25–34", "35–44", "45+"]
    static let salahConsistency = ["All 5 on time", "Most prayers", "Some prayers", "I’m rebuilding"]
    static let salahRelationship = ["Strong but distracted", "Inconsistent", "Often delayed", "Trying to return"]
    static let mainStruggles = ["Phone distraction", "Laziness", "Sleep", "Work/school", "Low energy", "No routine"]
    static let deeperStruggles = ["Weak discipline", "Spiritual emptiness", "Too much scrolling", "No accountability"]
    static let goals = ["Pray on time", "Reduce scrolling", "Build discipline", "Strengthen iman"]
    static let identities = ["I stop when Salah enters", "I don’t negotiate with prayer", "I protect my worship", "I lead my nafs"]
    static let commitments = ["Gentle reset", "Balanced", "Strict", "No excuses"]
    static let attribution = ["TikTok", "YouTube", "Instagram", "Snapchat", "Reddit", "Friend", "Influencer", "Apple Search Ads", "Other"]
}

struct OBAnimatedStoryView: View {
    let vm: OnboardingViewModel
    let icon: String
    let black: String
    let gold: String
    let lines: [String]
    let button: String
    var floatingApps: Bool = false
    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                if floatingApps { FloatingAppCloud(active: appeared) }
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                    .frame(width: 124, height: 124)
                    .background(Circle().fill(NafsTheme.gold.opacity(0.12)))
                    .shadow(color: NafsTheme.goldShadow, radius: pulse ? 26 : 12)
                    .scaleEffect(appeared ? (pulse ? 1.04 : 1) : 0.72)
            }
            .frame(height: 210)

            VStack(spacing: 16) {
                OnboardingHeadline(black: black, gold: gold)
                OnboardingSubtext(lines: lines)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            Spacer()
            NafsButton(title: button) { vm.goNext() }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

private struct FloatingAppCloud: View {
    let active: Bool
    private let icons = ["play.rectangle.fill", "camera.fill", "message.fill", "music.note", "bubble.left.fill"]
    var body: some View {
        ZStack {
            ForEach(Array(icons.enumerated()), id: \.offset) { idx, icon in
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(NafsTheme.text.opacity(0.82))
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 15).fill(NafsTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(NafsTheme.cardBorder))
                    .offset(x: [ -112, 94, -78, 114, 0 ][idx], y: [ -58, -48, 72, 62, -104 ][idx])
                    .opacity(active ? 1 : 0)
                    .scaleEffect(active ? 1 : 0.5)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75).delay(Double(idx) * 0.08), value: active)
            }
        }
    }
}

struct OBChoiceScreen: View {
    let vm: OnboardingViewModel
    let title: String
    let gold: String
    let options: [String]
    @Binding var selection: String

    var body: some View { OBOptionsLayout(title: title, gold: gold, options: options, selected: [selection]) { selection = $0 } footer: { NafsButton(title: "Continue", isEnabled: vm.canProceed) { vm.goNext() } } }
}

struct OBMultiChoiceScreen: View {
    let vm: OnboardingViewModel
    let title: String
    let gold: String
    let options: [String]
    @Binding var selected: Set<String>

    var body: some View { OBOptionsLayout(title: title, gold: gold, options: options, selected: selected) { item in if selected.contains(item) { selected.remove(item) } else { selected.insert(item) } } footer: { NafsButton(title: "Continue", isEnabled: vm.canProceed) { vm.goNext() } } }
}

private struct OBOptionsLayout<Footer: View>: View {
    let title: String
    let gold: String
    let options: [String]
    let selected: Set<String>
    let tap: (String) -> Void
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Spacer().frame(height: 24)
                    OnboardingHeadline(black: title, gold: gold)
                    VStack(spacing: 10) {
                        ForEach(options, id: \.self) { option in
                            OBOptionCard(title: option, isSelected: selected.contains(option)) {
                                tap(option)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            footer()
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}

private struct OBOptionCard: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { HStack { Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(NafsTheme.text); Spacer(); Image(systemName: isSelected ? "checkmark.circle.fill" : "circle").foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.subtleText) }.padding(18).background(NafsTheme.card).clipShape(.rect(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isSelected ? NafsTheme.gold.opacity(0.7) : NafsTheme.cardBorder)) .scaleEffect(isSelected ? 1.015 : 1) }.buttonStyle(.plain).sensoryFeedback(.selection, trigger: isSelected) }
}

struct OBSliderScreen: View {
    let vm: OnboardingViewModel
    var body: some View { VStack(spacing: 30) { Spacer(); OnboardingHeadline(black: "How much do you", gold: "scroll daily?"); Text("\(vm.phoneHours, specifier: "%.1f") hours").font(.system(size: 56, weight: .bold, design: .rounded)).foregroundStyle(NafsTheme.gold); Slider(value: Bindable(vm).phoneHours, in: 1...10, step: 0.5).tint(NafsTheme.gold).padding(.horizontal, 36); OnboardingSubtext(lines: ["Be honest. This helps personalize your reset."]); Spacer(); NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) } }
}

struct OBTimeLossView: View {
    let vm: OnboardingViewModel
    @State private var value = 0
    var body: some View { VStack(spacing: 24) { Spacer(); OnboardingHeadline(black: "That can become", gold: "time lost"); Text("\(value)").font(.system(size: 72, weight: .black, design: .rounded)).foregroundStyle(NafsTheme.gold); Text("hours per year").font(.system(.title3, weight: .semibold)).foregroundStyle(NafsTheme.text); OnboardingSubtext(lines: ["Not all screen time is bad.", "But useless scrolling steals the easiest moments to protect."]); Spacer(); NafsButton(title: "Take it back") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) }.onAppear { let target = vm.yearlyHoursLost(); value = 0; withAnimation(.easeOut(duration: 1.0)) { value = target } } }
}

struct OBLockExplainerView: View {
    let vm: OnboardingViewModel
    @State private var phase = 0
    private let apps = ["play.fill", "camera.fill", "message.fill", "music.note", "globe"]
    var body: some View { VStack(spacing: 0) { Spacer(); OnboardingHeadline(black: "Prayer Lock", gold: "in action"); ZStack { RoundedRectangle(cornerRadius: 34).fill(NafsTheme.card).frame(width: 210, height: 330).overlay(RoundedRectangle(cornerRadius: 34).strokeBorder(NafsTheme.cardBorder)); VStack(spacing: 18) { Text(phase < 2 ? "Distractions" : phase == 2 ? "Salah time" : "Unlocked").font(.system(.headline, weight: .bold)).foregroundStyle(NafsTheme.text); LazyVGrid(columns: Array(repeating: GridItem(.fixed(54)), count: 3), spacing: 14) { ForEach(Array(apps.enumerated()), id: \.offset) { idx, icon in ZStack { RoundedRectangle(cornerRadius: 16).fill(NafsTheme.background).frame(width: 54, height: 54); Image(systemName: phase >= 2 ? "lock.fill" : icon).foregroundStyle(phase >= 2 && phase < 4 ? NafsTheme.gold : NafsTheme.text) }.opacity(phase >= 1 ? 1 : 0).scaleEffect(phase >= 1 ? 1 : 0.3).rotationEffect(.degrees(phase == 2 ? (idx.isMultiple(of: 2) ? -3 : 3) : 0)).animation(.spring(response: 0.35).delay(Double(idx) * 0.08), value: phase) } }; if phase >= 3 { Text("You pray").font(.system(.title2, weight: .bold)).foregroundStyle(NafsTheme.gold).transition(.scale.combined(with: .opacity)) }; if phase >= 4 { Image(systemName: "lock.open.fill").font(.system(size: 34, weight: .bold)).foregroundStyle(NafsTheme.gold).transition(.scale.combined(with: .opacity)) } } } .frame(height: 380); OnboardingSubtext(lines: ["Apps appear → lock → you pray → unlock."]); Spacer(); NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) }.task { for i in 1...4 { try? await Task.sleep(for: .milliseconds(700)); withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { phase = i } } } }
}

struct OBUnlockDemoView: View { let vm: OnboardingViewModel; @State private var unlocked = false; var body: some View { VStack(spacing: 28) { Spacer(); OnboardingHeadline(black: "Then apps", gold: "unlock"); Image(systemName: unlocked ? "lock.open.fill" : "lock.fill").font(.system(size: 86, weight: .bold)).foregroundStyle(NafsTheme.gold).scaleEffect(unlocked ? 1.15 : 0.9).animation(.spring(response: 0.45, dampingFraction: 0.58), value: unlocked); OnboardingSubtext(lines: ["You don’t earn dopamine.", "You simply protect Salah first."]); Spacer(); NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) }.onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { unlocked = true } } } }

struct OBTestimonialsView: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 20)
                    OnboardingHeadline(black: "Built for Muslims", gold: "fighting distraction")
                    ForEach(["I needed something that made prayer the priority again.", "The lock moment helps me stop negotiating with myself.", "It feels like discipline without shame."], id: \.self) { quote in
                        Text("“\(quote)”")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NafsTheme.card)
                            .clipShape(.rect(cornerRadius: 18))
                    }
                    Text("Representative user-style feedback placeholders — no rankings or fake review counts.")
                        .font(.caption)
                        .foregroundStyle(NafsTheme.subtleText)
                }
                .padding(.horizontal, 24)
            }

            NafsButton(title: "Continue") { vm.goNext() }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}

struct OBHowItWorksView: View { let vm: OnboardingViewModel; var body: some View { VStack(spacing: 0) { Spacer(); OnboardingHeadline(black: "How Nafs", gold: "works"); VStack(spacing: 12) { ForEach(["1. Choose distracting apps", "2. Apps lock when Salah begins", "3. Pray, then tap I prayed", "4. Build consistency over time"], id: \.self) { row in Text(row).font(.system(size: 18, weight: .bold)).foregroundStyle(NafsTheme.text).frame(maxWidth: .infinity, alignment: .leading).padding(18).background(NafsTheme.card).clipShape(.rect(cornerRadius: 16)) } }.padding(24); Spacer(); NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) } } }

struct OBCatIntroView: View { let vm: OnboardingViewModel; @State private var breathe = false; var body: some View { VStack(spacing: 24) { Spacer(); OnboardingHeadline(black: "Meet your", gold: "companion"); Text("🐈").font(.system(size: 96)).scaleEffect(breathe ? 1.04 : 0.96).animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: breathe); OnboardingSubtext(lines: ["Inspired by the Prophet Muhammad’s ﷺ love for cats.", "A calm companion that reflects your consistency — premium, not childish."]); Spacer(); NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) }.onAppear { breathe = true } } }

struct OBCatNameView: View { let vm: OnboardingViewModel; @FocusState private var focused: Bool; private let names = ["Muezza", "Noor", "Sabr", "Barakah"]; var body: some View { VStack(spacing: 20) { Spacer().frame(height: 24); OnboardingHeadline(black: "Name your", gold: "cat"); TextField("Cat name", text: Bindable(vm).catName).focused($focused).font(.system(.title2, weight: .bold)).multilineTextAlignment(.center).padding(18).background(NafsTheme.card).clipShape(.rect(cornerRadius: 16)).padding(.horizontal, 24); HStack { ForEach(names, id: \.self) { name in Button(name) { vm.catName = name } .font(.system(.caption, weight: .bold)).foregroundStyle(vm.catName == name ? .white : NafsTheme.text).padding(.horizontal, 12).padding(.vertical, 9).background(vm.catName == name ? AnyShapeStyle(NafsTheme.goldGradient) : AnyShapeStyle(NafsTheme.card)).clipShape(.capsule) } }; Spacer(); NafsButton(title: "Continue", isEnabled: vm.canProceed) { focused = false; vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) }.onAppear { focused = true } } }

struct OBCatProgressionView: View { let vm: OnboardingViewModel; var body: some View { VStack(spacing: 22) { Spacer(); OnboardingHeadline(black: "Consistency changes", gold: vm.catName); VStack(spacing: 10) { ForEach(Array(["Distracted", "Calmer", "Focused", "Disciplined", "Consistent"].enumerated()), id: \.offset) { idx, label in HStack { Text("Level \(idx + 1)").foregroundStyle(NafsTheme.gold).font(.system(.caption, weight: .bold)); Text(label).font(.system(.body, weight: .semibold)).foregroundStyle(NafsTheme.text); Spacer(); Text(idx < vm.catLevel() ? "🐈" : "○") }.padding(14).background(NafsTheme.card).clipShape(.rect(cornerRadius: 14)) } }.padding(.horizontal, 24); OnboardingSubtext(lines: ["Progress is tied to prayer streaks."]); Spacer(); NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) } } }

struct OBCovenantView: View { let vm: OnboardingViewModel; var body: some View { VStack(spacing: 18) { Spacer().frame(height: 24); OnboardingHeadline(black: "Sign your", gold: "covenant"); VStack(alignment: .leading, spacing: 12) { ForEach(["Protect my Salah", "Pray before scrolling", "Reduce useless screen time", "Build discipline through worship"], id: \.self) { Text("• \($0)").foregroundStyle(NafsTheme.text).font(.system(size: 17, weight: .semibold)) } }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(NafsTheme.card).clipShape(.rect(cornerRadius: 18)).padding(.horizontal, 24); TextField("Type your name to sign", text: Bindable(vm).signature).font(.system(.title3, weight: .bold)).padding(18).background(NafsTheme.card).clipShape(.rect(cornerRadius: 16)).padding(.horizontal, 24); Spacer(); NafsButton(title: "I commit", isEnabled: vm.canProceed) { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) } } }

struct OBAttributionView: View { let vm: OnboardingViewModel; var body: some View { OBChoiceScreen(vm: vm, title: "How did you hear", gold: "about Nafs?", options: OBData.attribution, selection: Bindable(vm).sourcePlatform) } }

struct OBScreenTimePermissionView: View { let vm: OnboardingViewModel; @State private var service = ScreenTimeService(); var body: some View { VStack(spacing: 24) { Spacer(); OnboardingHeadline(black: "Enable", gold: "Screen Time"); OnboardingSubtext(lines: ["Required for system-level app blocking.", "You choose the apps. Nafs protects the prayer window."]); NafsButton(title: service.isAuthorized ? "Access enabled" : "Enable Screen Time", isLoading: service.isRequestingAuth) { Task { await service.requestAuthorization() } }; Button("Continue") { vm.goNext() }.foregroundStyle(NafsTheme.gold).font(.system(.headline, weight: .bold)); Spacer() }.padding(24) } }

struct OBNotificationPermissionView: View { let vm: OnboardingViewModel; @State private var asked = false; var body: some View { VStack(spacing: 24) { Spacer(); OnboardingHeadline(black: "Prayer alerts", gold: "before scrolls"); OnboardingSubtext(lines: ["We’ll notify you at prayer time and remind you before your free trial ends."]); NafsButton(title: asked ? "Notifications enabled" : "Enable Notifications") { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }; asked = true }; Button("Continue") { vm.goNext() }.foregroundStyle(NafsTheme.gold).font(.headline); Spacer() }.padding(24) } }

struct OBRoadmapView: View { let vm: OnboardingViewModel; private let days = ["Resistance", "First win", "Momentum", "Fewer delays", "Discipline", "Consistency", "Protected Salah"]; var body: some View { VStack(spacing: 0) { ScrollView { VStack(spacing: 14) { Spacer().frame(height: 18); OnboardingHeadline(black: "Your 7-day", gold: "reset"); ForEach(Array(days.enumerated()), id: \.offset) { idx, day in HStack { Text("Day \(idx + 1)").font(.caption.bold()).foregroundStyle(NafsTheme.gold); Text(day).font(.body.bold()).foregroundStyle(NafsTheme.text); Spacer() }.padding(16).background(NafsTheme.card).clipShape(.rect(cornerRadius: 14)) } }.padding(.horizontal, 24) }; NafsButton(title: "Continue") { vm.goNext() }.padding(.horizontal, 24).padding(.bottom, 32) } } }

struct OBTrialReassuranceView: View { let vm: OnboardingViewModel; var body: some View { OBAnimatedStoryView(vm: vm, icon: "bell.badge.fill", black: "We’ll remind you", gold: "before trial ends", lines: ["No surprise. No pressure.", "Cancel anytime from your Apple subscriptions."], button: "Continue") } }
struct OBCompletionView: View {
    let vm: OnboardingViewModel
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 84, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
                .shadow(color: NafsTheme.goldShadow, radius: 22)
            OnboardingHeadline(black: "Your Prayer Lock", gold: "is ready")
            OnboardingSubtext(lines: ["Pray before you scroll.", "Nafs is set up."])
            Spacer()
            NafsButton(title: "Enter Nafs") { vm.completeOnboarding() }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}
