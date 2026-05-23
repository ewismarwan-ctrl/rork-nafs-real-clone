import SwiftUI

struct DeenAreasScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Text(NafsStrings.deenAreasTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(NafsStrings.selectAllApply.localized)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                MultiSelectGrid(
                    options: OnboardingOptions.deenAreas,
                    selected: vm.selectedDeenAreas,
                    onToggle: { vm.toggleDeenArea($0) }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct SalahRelationshipScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(NafsTheme.gold)
                Text(NafsStrings.salahTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                SingleSelectList(
                    options: OnboardingOptions.salahRelationship,
                    selected: vm.selectedSalahRelationship,
                    onSelect: { vm.selectedSalahRelationship = $0 }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct QuranRelationshipScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(NafsTheme.gold)
                Text(NafsStrings.quranTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                SingleSelectList(
                    options: OnboardingOptions.quranRelationship,
                    selected: vm.selectedQuranRelationship,
                    onSelect: { vm.selectedQuranRelationship = $0 }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct KnowledgeAreasScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Text(NafsStrings.knowledgeTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(NafsStrings.selectAllApply.localized)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                MultiSelectGrid(
                    options: OnboardingOptions.knowledgeAreas,
                    selected: vm.selectedKnowledgeAreas,
                    onToggle: { vm.toggleKnowledgeArea($0) }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct PhoneEffectScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 36))
                    .foregroundStyle(NafsTheme.gold)
                Text(NafsStrings.phoneTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                SingleSelectList(
                    options: OnboardingOptions.phoneEffect,
                    selected: vm.selectedPhoneEffect,
                    onSelect: { vm.selectedPhoneEffect = $0 }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct SpiritualChallengeScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(NafsTheme.gold)
                Text(NafsStrings.challengeTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                SingleSelectList(
                    options: OnboardingOptions.spiritualChallenge,
                    selected: vm.selectedSpiritualChallenge,
                    onSelect: { vm.selectedSpiritualChallenge = $0 }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct ExcitingFeaturesScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Text(NafsStrings.featuresTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(NafsStrings.selectAllApply.localized)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                MultiSelectGrid(
                    options: OnboardingOptions.excitingFeatures,
                    selected: vm.selectedExcitingFeatures,
                    onToggle: { vm.toggleExcitingFeature($0) }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct StrictnessScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 36))
                    .foregroundStyle(NafsTheme.gold)
                Text(NafsStrings.strictnessTitle.localized)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                SingleSelectList(
                    options: OnboardingOptions.strictnessLevels,
                    selected: vm.selectedStrictness,
                    onSelect: { vm.selectedStrictness = $0 }
                )
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer(minLength: 12)

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}
