import SwiftUI

struct GuidedPlansView: View {
    let appViewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @Environment(LanguageManager.self) private var lang
    @State private var activePlanId: String? = nil
    @State private var activePlanDay: Int = 1
    @State private var completedSteps: Set<String> = []
    @State private var selectedPlan: NafsPlan?
    @State private var showSwitchAlert: Bool = false
    @State private var pendingPlan: NafsPlan?
    @State private var hapticTrigger: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !appViewModel.isPremium {
                    premiumBanner
                }

                if let active = NafsPlan.all.first(where: { $0.id == activePlanId }), appViewModel.isPremium {
                    activePlanCard(active)
                }

                planGrid
            }
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.text("Guided Plans", "الخطط الإرشادية"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedPlan) { plan in
                PlanDetailSheet(
                    plan: plan,
                    isActive: activePlanId == plan.id,
                    activePlanDay: activePlanDay,
                    completedSteps: completedSteps,
                    isPremium: appViewModel.isPremium,
                    onStart: {
                        if activePlanId != nil && activePlanId != plan.id {
                            pendingPlan = plan
                            showSwitchAlert = true
                        } else {
                            startPlan(plan)
                        }
                    },
                    onCompleteStep: { stepId in completeStep(stepId) }
                )
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
            }
            .alert("Switch Plan?", isPresented: $showSwitchAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Switch") {
                    if let plan = pendingPlan {
                        startPlan(plan)
                    }
                }
            } message: {
                Text("Are you sure? Your current progress will be saved.")
            }
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradePaywallSheet(
                storeViewModel: storeViewModel,
                feature: "Guided Plans",
                benefit: "Structured spiritual growth plans to strengthen your deen. Unlock with Nafs Premium.",
                onDismiss: { showUpgradeSheet = false },
                onSuccess: { showUpgradeSheet = false }
            )
        }
    }

    @State private var showUpgradeSheet: Bool = false

    private var premiumBanner: some View {
        Button {
            showUpgradeSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(NafsTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Guided Plans are available on Nafs Premium.")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                    Text("Start your free trial →")
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(NafsTheme.gold)
                }
                Spacer()
            }
            .padding(14)
            .background(NafsTheme.gold.opacity(0.08))
            .clipShape(.rect(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }

    private func activePlanCard(_ plan: NafsPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plan.icon)
                    .foregroundStyle(NafsTheme.gold)
                Text(L10n.text("Active Plan", "الخطة النشطة"))
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("Day \(activePlanDay) of \(plan.durationDays)")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Text(plan.title)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            NafsProgressBar(progress: Double(activePlanDay) / Double(plan.durationDays))

            Text("\(Int(Double(activePlanDay) / Double(plan.durationDays) * 100))% complete")
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(NafsTheme.gold)

            Button {
                selectedPlan = plan
            } label: {
                Text(L10n.text("Continue today's step →", "تابع خطوة اليوم ←"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(NafsTheme.gold.opacity(0.06))
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }

    private var planGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("All Plans", "جميع الخطط"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(NafsPlan.all) { plan in
                    PlanCard(plan: plan, isActive: activePlanId == plan.id) {
                        selectedPlan = plan
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func startPlan(_ plan: NafsPlan) {
        activePlanId = plan.id
        activePlanDay = 1
        completedSteps = []
        hapticTrigger += 1
    }

    private func completeStep(_ stepId: String) {
        guard !completedSteps.contains(stepId) else { return }
        completedSteps.insert(stepId)
        if appViewModel.isPremium {
            appViewModel.hasanatBalance += 35
            appViewModel.transactions.insert(
                Transaction(title: "Guided Plan step completed", tokens: 35, isEarned: true, icon: "map.fill"),
                at: 0
            )
        }

        if let plan = NafsPlan.all.first(where: { $0.id == activePlanId }) {
            let completedToday = plan.steps.first(where: { $0.id == stepId })
            if completedToday?.day == activePlanDay && activePlanDay < plan.durationDays {
                activePlanDay += 1
            }
        }
        hapticTrigger += 1
    }
}

private struct PlanCard: View {
    let plan: NafsPlan
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: plan.icon)
                    .font(.system(.title2))
                    .foregroundStyle(NafsTheme.gold)

                Text(plan.title)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(plan.subtitle)
                    .font(.system(.caption2))
                    .foregroundStyle(NafsTheme.subtleText)
                    .lineLimit(2)

                Text("\(plan.durationDays) days")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(NafsTheme.gold)

                if isActive {
                    Text("ACTIVE")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(NafsTheme.gold.opacity(0.12))
                        .clipShape(.capsule)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isActive ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isActive ? NafsTheme.gold.opacity(0.3) : NafsTheme.cardBorder, lineWidth: 1)
            )
        }
    }
}

private struct PlanDetailSheet: View {
    let plan: NafsPlan
    let isActive: Bool
    let activePlanDay: Int
    let completedSteps: Set<String>
    let isPremium: Bool
    let onStart: () -> Void
    let onCompleteStep: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: plan.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(NafsTheme.gold)
                        Text(plan.title)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        Text(plan.subtitle)
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                        Text("\(plan.durationDays) days · 35 Hasanat per step")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    .padding(.top, 8)

                    if !isPremium {
                        VStack(spacing: 8) {
                            Text("Guided Plans are available on Nafs Premium.")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(NafsTheme.text)
                            Text("Start your free trial →")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(NafsTheme.gold)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(NafsTheme.gold.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 14))
                    } else if !isActive {
                        Button {
                            onStart()
                            dismiss()
                        } label: {
                            Text("Start This Plan")
                                .font(.system(.headline, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(NafsTheme.goldGradient)
                                .clipShape(.rect(cornerRadius: 14))
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Steps")
                            .font(.system(.subheadline, weight: .bold))
                            .foregroundStyle(NafsTheme.subtleText)
                            .textCase(.uppercase)
                            .tracking(1)

                        ForEach(plan.steps) { step in
                            DayStepCard(
                                step: step,
                                isCompleted: completedSteps.contains(step.id),
                                isCurrent: isActive && step.day == activePlanDay,
                                isLocked: !isActive || step.day > activePlanDay,
                                onComplete: { onCompleteStep(step.id) }
                            )
                        }


                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NafsTheme.gold)
                }
            }
        }
    }
}

private struct DayStepCard: View {
    let step: PlanDayStep
    let isCompleted: Bool
    let isCurrent: Bool
    let isLocked: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Day \(step.day)")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(isCurrent ? NafsTheme.gold : NafsTheme.subtleText)
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(NafsTheme.gold)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }

            if !isLocked || isCompleted {
                VStack(alignment: .leading, spacing: 10) {
                    Text(step.reflection)
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.text)
                        .lineSpacing(3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("📖 \(step.ayah)")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(NafsTheme.text)
                            .italic()
                        Text("— \(step.ayahReference)")
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.gold)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "hands.sparkles.fill")
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.gold)
                        Text(step.dhikr)
                            .font(.system(.caption))
                            .foregroundStyle(NafsTheme.subtleText)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.gold)
                        Text(step.action)
                            .font(.system(.caption))
                            .foregroundStyle(NafsTheme.subtleText)
                    }

                    if isCurrent && !isCompleted {
                        Button {
                            onComplete()
                        } label: {
                            Text("Complete Step · +35 Hasanat")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(NafsTheme.goldGradient)
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(14)
        .background(isCurrent ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isCurrent ? NafsTheme.gold.opacity(0.3) : NafsTheme.cardBorder, lineWidth: 1)
        )
        .opacity(isLocked && !isCompleted ? 0.5 : 1)
    }
}
