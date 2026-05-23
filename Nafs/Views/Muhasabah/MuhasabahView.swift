import SwiftUI

struct MuhasabahView: View {
    let appViewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var viewModel = MuhasabahViewModel()
    @FocusState private var focusedField: MuhasabahField?
    @Environment(LanguageManager.self) private var lang

    private enum MuhasabahField: Hashable {
        case gratitude, struggle, tomorrow
    }

    var body: some View {
        Group {
            if appViewModel.isPremium {
                muhasabahContent
            } else {
                PremiumGateView(
                    icon: "moon.stars.fill",
                    title: "Muhasabah",
                    subtitle: "Daily self-accountability is available on Nafs Premium.",
                    storeViewModel: storeViewModel
                )
            }
        }
        .navigationTitle(L10n.text("Muhasabah", "المحاسبة"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var muhasabahContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                todayCheckIn
                pastEntriesSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(NafsTheme.background.ignoresSafeArea())
        .onTapGesture { focusedField = nil }
        .overlay {
            if viewModel.showCompletion {
                completionOverlay
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("مُحَاسَبَة")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(NafsTheme.gold)

            Text(L10n.text("Muhasabah", "المحاسبة"))
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.text)

            Text(L10n.text("The Prophet ﷺ said: 'Take account of yourselves before you are taken to account.'", "قال النبي ﷺ: 'حاسبوا أنفسكم قبل أن تُحاسبوا.'"))
                .font(.system(.caption, weight: .medium).italic())
                .foregroundStyle(NafsTheme.gold.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    private var todayCheckIn: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(L10n.text("Today's Check-In", "تسجيل اليوم"))
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Text(Date().formatted(.dateTime.month(.wide).day().year()))
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.gold)
            }

            if viewModel.hasCompletedToday {
                completedTodayBanner
            } else {
                promptField(
                    title: L10n.text("What am I grateful to Allah for today?", "ما الذي أشكر الله عليه اليوم؟"),
                    placeholder: L10n.text("Alhamdulillah for...", "الحمد لله على..."),
                    text: $viewModel.gratitudeText,
                    field: .gratitude
                )

                promptField(
                    title: L10n.text("Where did my nafs win today?", "أين غلبتني نفسي اليوم؟"),
                    placeholder: L10n.text("I struggled with...", "عانيت مع..."),
                    text: $viewModel.struggleText,
                    field: .struggle
                )

                promptField(
                    title: L10n.text("What will I do differently tomorrow?", "ما الذي سأفعله بشكل مختلف غداً؟"),
                    placeholder: L10n.text("Tomorrow I will...", "غداً سوف..."),
                    text: $viewModel.tomorrowText,
                    field: .tomorrow
                )

                moodSelector

                NafsButton(
                    title: L10n.text("Complete Muhasabah", "أكمل المحاسبة"),
                    isEnabled: viewModel.canComplete
                ) {
                    viewModel.completeMuhasabah(userName: appViewModel.userName, appViewModel: appViewModel)
                }
                .sensoryFeedback(.success, trigger: viewModel.showCompletion)
            }
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var completedTodayBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(NafsTheme.gold)
            Text(L10n.text("Today's Muhasabah is complete", "محاسبة اليوم اكتملت"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
            Text(L10n.text("Come back tomorrow night after Isha", "عد غداً ليلاً بعد العشاء"))
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func promptField(title: String, placeholder: String, text: Binding<String>, field: MuhasabahField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(2...4)
                .font(.system(.body))
                .foregroundStyle(NafsTheme.text)
                .padding(12)
                .background(NafsTheme.background)
                .clipShape(.rect(cornerRadius: 14))
                .focused($focusedField, equals: field)
        }
    }

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("How is your heart today?", "كيف حال قلبك اليوم؟"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            FlowLayout(spacing: 8) {
                ForEach(MuhasabahMood.allCases, id: \.rawValue) { mood in
                    Button {
                        viewModel.selectedMood = mood
                    } label: {
                        VStack(spacing: 2) {
                            Text(mood.rawValue)
                                .font(.system(.caption, weight: .semibold))
                            Text(mood.arabic)
                                .font(.system(.caption2))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedMood == mood ? AnyShapeStyle(NafsTheme.goldGradient) : AnyShapeStyle(NafsTheme.background))
                        .foregroundStyle(viewModel.selectedMood == mood ? .white : NafsTheme.text)
                        .clipShape(.capsule)
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.selectedMood)
                }
            }
        }
    }

    private var pastEntriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("Previous Reflections", "تأملات سابقة"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            if viewModel.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 28))
                        .foregroundStyle(NafsTheme.gold.opacity(0.5))
                    Text(L10n.text("Your reflections will appear here.\nStart tonight after Isha.", "تأملاتك ستظهر هنا.\nابدأ الليلة بعد العشاء."))
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.entries) { entry in
                    pastEntryCard(entry)
                }
            }
        }
        .padding(.top, 8)
    }

    private func pastEntryCard(_ entry: MuhasabahEntry) -> some View {
        let isExpanded = viewModel.expandedEntryID == entry.id
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.expandedEntryID = isExpanded ? nil : entry.id
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                        Text("\(entry.mood.rawValue) (\(entry.mood.arabic))")
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }

            if !isExpanded {
                Text(entry.gratitude)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.text)
                    .lineLimit(1)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    expandedSection(title: "Grateful for", text: entry.gratitude)
                    expandedSection(title: "Struggled with", text: entry.struggle)
                    expandedSection(title: "Tomorrow", text: entry.tomorrow)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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

    private func expandedSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
            Text(text)
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showCompletion = false
                }

            VStack(spacing: 20) {
                CrescentStarMark(size: 56, color: NafsTheme.gold)

                Text(L10n.text("Alhamdulillah", "الحمد لله"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)

                Text(viewModel.completionMessage)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Button {
                    viewModel.showCompletion = false
                } label: {
                    Text("Alhamdulillah")
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(NafsTheme.goldGradient)
                        .clipShape(.rect(cornerRadius: 14))
                }
            }
            .padding(28)
            .background(NafsTheme.background)
            .clipShape(.rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
        .animation(.spring(response: 0.35), value: viewModel.showCompletion)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
