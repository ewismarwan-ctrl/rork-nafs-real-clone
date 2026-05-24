import SwiftUI
import StoreKit

@Observable
@MainActor
class OnboardingViewModel {
    var currentScreen: OnboardingScreen = .splash
    var direction: Int = 1

    var selectedDeenAreas: Set<String> = []
    var selectedSalahRelationship: String = ""
    var selectedQuranRelationship: String = ""
    var selectedKnowledgeAreas: Set<String> = []
    var selectedPhoneEffect: String = ""
    var selectedSpiritualChallenge: String = ""
    var selectedExcitingFeatures: Set<String> = []
    var selectedStrictness: String = ""
    var userName: String = ""
    var locationGranted: Bool = false
    var locationSkipped: Bool = false
    var userLatitude: Double = 21.4225
    var userLongitude: Double = 39.8262
    var hasCompletedOnboarding: Bool = false
    var loadingProgress: Double = 0
    var loadingTextIndex: Int = 0

    // Premium Salah-discipline onboarding state
    var ageRange: String = ""
    var phoneHours: Double = 5
    var salahConsistency: String = ""
    var selectedGoals: Set<String> = []
    var selectedStruggles: Set<String> = []
    var deeperStruggle: String = ""
    var disciplineIdentity: String = ""
    var commitmentLevel: String = ""
    var signature: String = ""
    var catName: String = "Muezza"
    var sourcePlatform: String = ""
    var sourceDetail: String = ""
    var referralCode: String = ""
    var blockedDistractions: Set<String> = []

    var totalScreens: Int { OnboardingScreen.allCases.count }

    var progress: Double {
        Double(currentScreen.rawValue) / Double(totalScreens - 1)
    }

    var canProceed: Bool {
        switch currentScreen {
        case .name:
            return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .ageRange:
            return !ageRange.isEmpty
        case .salahConsistency:
            return !salahConsistency.isEmpty
        case .salahRelationship:
            return !selectedSalahRelationship.isEmpty
        case .mainStruggle:
            return !selectedStruggles.isEmpty
        case .deeperStruggle:
            return !deeperStruggle.isEmpty
        case .goals:
            return !selectedGoals.isEmpty
        case .identity:
            return !disciplineIdentity.isEmpty
        case .catName:
            return !catName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .commitmentLevel:
            return !commitmentLevel.isEmpty
        case .covenant:
            return !signature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .attribution:
            return !sourcePlatform.isEmpty
        case .appSelection, .appPreviewSelection:
            return !blockedDistractions.isEmpty
        default:
            return true
        }
    }

    var requiresAnswer: Bool {
        switch currentScreen {
        case .name, .ageRange, .salahConsistency, .salahRelationship, .mainStruggle, .deeperStruggle, .goals, .identity, .catName, .commitmentLevel, .covenant, .attribution, .appSelection, .appPreviewSelection:
            return !canProceed
        default:
            return false
        }
    }

    var showBackButton: Bool {
        currentScreen.rawValue > 0
    }

    var showProgressBar: Bool {
        currentScreen != .splash && currentScreen != .paywall && currentScreen != .completion
    }

    var nafsScore: Int {
        var score = 40

        if selectedSalahRelationship == "all_5" { score += 25 }
        else if selectedSalahRelationship == "most" { score += 15 }
        else if selectedSalahRelationship == "sometimes" { score += 8 }
        else if selectedSalahRelationship == "new" { score += 5 }

        if selectedQuranRelationship == "daily" { score += 15 }
        else if selectedQuranRelationship == "sometimes" { score += 8 }
        else if selectedQuranRelationship == "memorize" { score += 10 }

        if selectedDeenAreas.count <= 3 { score += 10 }

        if selectedPhoneEffect == "mostly_fine" || selectedPhoneEffect == "intentional" { score += 5 }

        if selectedSpiritualChallenge == "balance" { score += 5 }

        return min(score, 100)
    }

    var scoreMessage: String {
        if nafsScore >= 70 {
            return L10n.text(
                "MashaAllah \(displayName). You have a strong foundation. Nafs will help you take it to the next level.",
                "ما شاء الله \(displayName). لديك أساس قوي. نفس سيساعدك للوصول إلى المستوى التالي."
            )
        } else {
            return L10n.text(
                "Your deen has room to grow — and that is beautiful. Every journey starts with one step. You have already taken it.",
                "دينك فيه مجال للنمو — وهذا جميل. كل رحلة تبدأ بخطوة واحدة. وأنت قد خطوتها."
            )
        }
    }

    var personalizedInsights: [String] {
        var insights: [String] = []

        if selectedDeenAreas.contains("quran") || selectedDeenAreas.contains("all") {
            insights.append(L10n.text("Your Quran journey is ready to begin. Nafs will help you build a daily habit.", "رحلتك مع القرآن جاهزة للبدء. نفس سيساعدك في بناء عادة يومية."))
        }
        if selectedDeenAreas.contains("knowledge") || selectedDeenAreas.contains("all") {
            insights.append(L10n.text("Nafs AI is ready to answer any Islamic question you have, 24/7.", "نفس AI جاهز للإجابة على أي سؤال إسلامي لديك، على مدار الساعة."))
        }
        if selectedDeenAreas.contains("screentime") || selectedDeenAreas.contains("all") {
            insights.append(L10n.text("Your app blocker is configured and ready. Earn your screen time through ibadah.", "حاجب التطبيقات جاهز. اكسب وقت شاشتك من خلال العبادة."))
        }
        if selectedDeenAreas.contains("salah") || selectedDeenAreas.contains("all") {
            let salahText = L10n.text("Your Salah tracker is ready to help you build an unbreakable prayer habit.", "متتبع صلاتك جاهز لمساعدتك في بناء عادة صلاة لا تنقطع.")
            if !insights.contains(where: { $0 == salahText }) {
                insights.append(salahText)
            }
        }
        if selectedDeenAreas.contains("dhikr") || selectedDeenAreas.contains("all") {
            insights.append(L10n.text("Your dhikr counter and daily remembrance tools are set up.", "عدّاد الذكر وأدوات التذكير اليومي جاهزة."))
        }

        if insights.isEmpty {
            insights.append(L10n.text("Your complete Islamic companion is ready to strengthen every part of your deen.", "رفيقك الإسلامي الشامل جاهز لتقوية كل جزء من دينك."))
            insights.append(L10n.text("Nafs AI is ready to answer any Islamic question you have, 24/7.", "نفس AI جاهز للإجابة على أي سؤال إسلامي لديك، على مدار الساعة."))
            insights.append(L10n.text("Distracting apps will lock automatically at prayer time.", "ستُقفل التطبيقات المشتتة تلقائياً عند وقت الصلاة."))
        }

        return Array(insights.prefix(4))
    }

    var personalizedOutcomes: [String] {
        var outcomes: [String] = []

        if selectedSalahRelationship != "all_5" {
            outcomes.append(L10n.text("Build toward praying all 5 salah consistently", "ابنِ عادة صلاة الخمس بانتظام"))
        } else {
            outcomes.append(L10n.text("Protect and strengthen your 5-salah streak", "حافظ على سلسلة صلواتك الخمس وقوّها"))
        }

        if selectedDeenAreas.contains("quran") || selectedDeenAreas.contains("all") || selectedQuranRelationship != "daily" {
            outcomes.append(L10n.text("Build a daily Quran reading habit with the full reader", "ابنِ عادة قراءة القرآن اليومية مع القارئ الكامل"))
        }

        if selectedDeenAreas.contains("knowledge") || selectedDeenAreas.contains("all") {
            outcomes.append(L10n.text("Get 24/7 Islamic guidance from Nafs AI companion", "احصل على إرشاد إسلامي على مدار الساعة من رفيقك نفس AI"))
        } else {
            outcomes.append(L10n.text("Deepen your connection with Allah through daily ibadah", "عمّق صلتك بالله من خلال العبادة اليومية"))
        }

        return outcomes
    }

    func goNext() {
        guard let next = OnboardingScreen(rawValue: currentScreen.rawValue + 1) else { return }
        direction = 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentScreen = next
        }
    }

    func goBack() {
        guard let prev = OnboardingScreen(rawValue: currentScreen.rawValue - 1) else { return }
        direction = -1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentScreen = prev
        }
    }

    func toggleDeenArea(_ id: String) {
        if id == "all" {
            if selectedDeenAreas.contains("all") {
                selectedDeenAreas.removeAll()
            } else {
                selectedDeenAreas = Set(OnboardingOptions.deenAreas.map { $0.id })
            }
        } else {
            if selectedDeenAreas.contains(id) {
                selectedDeenAreas.remove(id)
                selectedDeenAreas.remove("all")
            } else {
                selectedDeenAreas.insert(id)
            }
        }
    }

    func toggleKnowledgeArea(_ id: String) {
        if id == "all" {
            if selectedKnowledgeAreas.contains("all") {
                selectedKnowledgeAreas.removeAll()
            } else {
                selectedKnowledgeAreas = Set(OnboardingOptions.knowledgeAreas.map { $0.id })
            }
        } else {
            if selectedKnowledgeAreas.contains(id) {
                selectedKnowledgeAreas.remove(id)
                selectedKnowledgeAreas.remove("all")
            } else {
                selectedKnowledgeAreas.insert(id)
            }
        }
    }

    func toggleExcitingFeature(_ id: String) {
        if selectedExcitingFeatures.contains(id) {
            selectedExcitingFeatures.remove(id)
        } else {
            selectedExcitingFeatures.insert(id)
        }
    }

    func toggleBlockedDistraction(_ id: String) {
        if blockedDistractions.contains(id) {
            blockedDistractions.remove(id)
        } else {
            blockedDistractions.insert(id)
        }
    }

    func toggleGoal(_ id: String) {
        if selectedGoals.contains(id) { selectedGoals.remove(id) } else { selectedGoals.insert(id) }
    }

    func toggleStruggle(_ id: String) {
        if selectedStruggles.contains(id) { selectedStruggles.remove(id) } else { selectedStruggles.insert(id) }
    }

    func yearlyHoursLost() -> Int {
        Int((phoneHours * 365).rounded())
    }

    func catLevel() -> Int {
        let streak = PrayerCompletionStore.currentStreakDays()
        if streak >= 30 { return 5 }
        if streak >= 14 { return 4 }
        if streak >= 7 { return 3 }
        if streak >= 3 { return 2 }
        return 1
    }

    func persistOnboardingData() {
        let defaults = UserDefaults.standard
        defaults.set(displayName, forKey: "nafs_userName")
        defaults.set(displayName, forKey: "nafs_firstName")
        defaults.set(ageRange, forKey: "nafs_ageRange")
        defaults.set(phoneHours, forKey: "nafs_phoneHours")
        defaults.set(salahConsistency, forKey: "nafs_salahConsistency")
        defaults.set(Array(selectedGoals), forKey: "nafs_selectedGoals")
        defaults.set(Array(selectedStruggles), forKey: "nafs_selectedStruggles")
        defaults.set(deeperStruggle, forKey: "nafs_deeperStruggle")
        defaults.set(disciplineIdentity, forKey: "nafs_disciplineIdentity")
        defaults.set(commitmentLevel, forKey: "nafs_commitmentLevel")
        defaults.set(signature, forKey: "nafs_signature")
        defaults.set(catName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "nafs_catName")
        defaults.set(catLevel(), forKey: "nafs_catLevel")
        defaults.set(sourcePlatform, forKey: "nafs_sourcePlatform")
        defaults.set(sourceDetail, forKey: "nafs_sourceDetail")
        defaults.set(referralCode, forKey: "nafs_referralCode")
        defaults.set(Array(blockedDistractions), forKey: "nafs_onboardingBlockedDistractions")
        defaults.set(true, forKey: "nafs_onboardingCompleted")
    }

    func startLoading() {
        loadingProgress = 0
        loadingTextIndex = 0
        Task {
            for i in 1...100 {
                try? await Task.sleep(for: .milliseconds(35))
                loadingProgress = Double(i) / 100.0
                if i == 25 { loadingTextIndex = 1 }
                if i == 50 { loadingTextIndex = 2 }
                if i == 75 { loadingTextIndex = 3 }
            }
            try? await Task.sleep(for: .milliseconds(300))
            goNext()
        }
    }

    func completeOnboarding() {
        persistOnboardingData()
        hasCompletedOnboarding = true
    }

    var displayName: String {
        userName.trimmingCharacters(in: .whitespaces).isEmpty ? "Friend" : userName.trimmingCharacters(in: .whitespaces)
    }
}
