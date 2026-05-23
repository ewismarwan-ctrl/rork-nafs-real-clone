import SwiftUI

struct GardenOfDeedsView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var selectedElement: GardenElement?
    @State private var showStreakPopup: Bool = false
    @State private var showUpgradeSheet: Bool = false
    @Environment(LanguageManager.self) private var lang

    private var elements: [GardenElement] {
        var result: [GardenElement] = []
        if viewModel.gardenTrees > 0 {
            result.append(GardenElement(id: "tree1", type: .tree, name: "Salah", streak: viewModel.gardenTrees, position: CGPoint(x: 0.2, y: 0.3)))
        }
        if viewModel.gardenTrees > 2 {
            result.append(GardenElement(id: "tree2", type: .tree, name: "Salah", streak: viewModel.gardenTrees, position: CGPoint(x: 0.7, y: 0.35)))
        }
        if viewModel.gardenFlowers > 0 {
            result.append(GardenElement(id: "flower1", type: .flower, name: "Quran", streak: viewModel.gardenFlowers, position: CGPoint(x: 0.15, y: 0.6)))
        }
        if viewModel.gardenFlowers > 2 {
            result.append(GardenElement(id: "flower2", type: .flower, name: "Quran", streak: viewModel.gardenFlowers, position: CGPoint(x: 0.65, y: 0.55)))
        }
        if viewModel.gardenOrbs > 0 {
            result.append(GardenElement(id: "orb1", type: .orb, name: "Dhikr", streak: viewModel.gardenOrbs, position: CGPoint(x: 0.4, y: 0.5)))
        }
        if viewModel.gardenOrbs > 2 {
            result.append(GardenElement(id: "orb2", type: .orb, name: "Dhikr", streak: viewModel.gardenOrbs, position: CGPoint(x: 0.8, y: 0.65)))
        }
        if viewModel.gardenBlooms > 0 {
            result.append(GardenElement(id: "bloom1", type: .bloom, name: "Fasting", streak: viewModel.gardenBlooms, position: CGPoint(x: 0.5, y: 0.75)))
        }
        return result
    }

    private var isEmpty: Bool { elements.isEmpty }

    var body: some View {
        ZStack {
                NafsTheme.background.ignoresSafeArea()

                if viewModel.isPremium {
                    if isEmpty {
                        emptyGarden
                    } else {
                        gardenContent
                    }
                } else {
                    lockedGarden
                }
            }
        .navigationTitle(L10n.text("Garden of Deeds", "حديقة الأعمال"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradePaywallSheet(
                storeViewModel: storeViewModel,
                feature: "Garden of Deeds",
                benefit: "Watch your garden grow with every deed. Unlock Premium to begin.",
                onDismiss: { showUpgradeSheet = false },
                onSuccess: { showUpgradeSheet = false }
            )
        }
    }

    private var emptyGarden: some View {
        ScrollView {
            VStack(spacing: 24) {
                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F0EDE6"), Color(hex: "E8E4D8"), Color(hex: "DDD8C8")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        groundPath(size: geo.size)

                        VStack(spacing: 16) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(NafsTheme.gold.opacity(0.4))
                            Text(L10n.text("Your garden begins with your first deed.", "تبدأ حديقتك بأول عمل صالح."))
                                .font(.system(.headline, weight: .semibold))
                                .foregroundStyle(NafsTheme.text)
                                .multilineTextAlignment(.center)
                            Text(L10n.text("Every act of worship plants something here.", "كل عبادة تزرع شيئاً هنا."))
                                .font(.system(.subheadline))
                                .foregroundStyle(NafsTheme.subtleText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .frame(height: 320)
                .padding(.horizontal, 20)

                legendRow

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("How your garden grows", "كيف تنمو حديقتك"))
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)

                    gardenExplainer(icon: "tree.fill", color: NafsTheme.gold, label: "Salah", desc: "Tall elegant palm trees")
                    gardenExplainer(icon: "leaf.fill", color: Color(hex: "8B9E6B"), label: "Quran", desc: "Golden flowers bloom")
                    gardenExplainer(icon: "sparkle", color: NafsTheme.gold.opacity(0.7), label: "Dhikr", desc: "Soft glowing light orbs")
                    gardenExplainer(icon: "moonphase.waxing.crescent", color: Color(hex: "A07BC5"), label: "Fasting", desc: "Rare night-blooming flowers")
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
            .padding(.top, 12)
        }
    }

    private func gardenExplainer(icon: String, color: Color, label: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(.caption))
                        .foregroundStyle(color)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                Text(desc)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var gardenContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                gardenVisualization
                legendRow
                elementsList
                Spacer(minLength: 100)
            }
            .padding(.top, 12)
        }
    }

    private var gardenVisualization: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F0EDE6"), Color(hex: "E8E4D8"), Color(hex: "DDD8C8")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                groundPath(size: geo.size)

                ForEach(elements) { element in
                    GardenElementView(element: element)
                        .position(
                            x: element.position.x * geo.size.width,
                            y: element.position.y * geo.size.height
                        )
                        .onTapGesture {
                            selectedElement = element
                            showStreakPopup = true
                        }
                }
            }
        }
        .frame(height: 320)
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) {
            if showStreakPopup, let el = selectedElement {
                streakPopup(el)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
                    .padding(.horizontal, 36)
                    .onTapGesture { showStreakPopup = false }
            }
        }
        .animation(.spring(response: 0.3), value: showStreakPopup)
    }

    private func groundPath(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: canvasSize.height * 0.85))
            path.addQuadCurve(
                to: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.8),
                control: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.75)
            )
            path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
            path.addLine(to: CGPoint(x: 0, y: canvasSize.height))
            path.closeSubpath()
            context.fill(path, with: .color(Color(hex: "D4CFC2").opacity(0.5)))
        }
    }

    private func streakPopup(_ element: GardenElement) -> some View {
        VStack(spacing: 4) {
            Text("You've kept \(element.name) for \(element.streak) days in a row.")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)
            Text("MashaAllah, \(viewModel.userName)!")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var legendRow: some View {
        HStack(spacing: 16) {
            GardenLegendItem(icon: "tree.fill", label: "Salah", color: NafsTheme.gold)
            GardenLegendItem(icon: "leaf.fill", label: "Quran", color: Color(hex: "8B9E6B"))
            GardenLegendItem(icon: "sparkle", label: "Dhikr", color: NafsTheme.gold.opacity(0.7))
            GardenLegendItem(icon: "moonphase.waxing.crescent", label: "Fasting", color: Color(hex: "A07BC5"))
        }
        .padding(.horizontal, 20)
    }

    private var elementsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("Your Deeds", "أعمالك"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            ForEach(elements) { element in
                HStack(spacing: 12) {
                    gardenIcon(for: element.type)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(element.name)
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(NafsTheme.text)
                        Text(L10n.text("\(element.streak) day streak", "سلسلة \(element.streak) يوم"))
                            .font(.system(.caption))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.gold)
                    Text("\(element.streak)")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                }
                .padding(12)
                .background(NafsTheme.card)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
    }

    private func gardenIcon(for type: GardenElementType) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .tree: return ("tree.fill", NafsTheme.gold)
            case .flower: return ("leaf.fill", Color(hex: "8B9E6B"))
            case .orb: return ("sparkle", NafsTheme.gold.opacity(0.7))
            case .bloom: return ("moonphase.waxing.crescent", Color(hex: "A07BC5"))
            }
        }()

        return Circle()
            .fill(color.opacity(0.15))
            .overlay {
                Image(systemName: icon)
                    .font(.system(.caption))
                    .foregroundStyle(color)
            }
    }

    private var lockedGarden: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "E8E4D8"))
                    ForEach(GardenElement.samples()) { element in
                        GardenElementView(element: element)
                            .position(
                                x: element.position.x * geo.size.width,
                                y: element.position.y * geo.size.height
                            )
                    }
                }
                .blur(radius: 8)
            }
            .frame(height: 300)
            .padding(.horizontal, 20)
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(NafsTheme.gold)
                    Text(L10n.text("Your garden is waiting to grow.", "حديقتك تنتظر أن تنمو."))
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(L10n.text("Every deed you make plants something here. Unlock Premium to begin.", "كل عمل تقوم به يزرع شيئاً هنا. افتح بريميوم للبدء."))
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    NafsButton(title: L10n.text("Unlock Premium →", "افتح بريميوم ←")) {
                        showUpgradeSheet = true
                    }
                    .padding(.horizontal, 48)
                }
            }

            Spacer()
        }
        .padding(.top, 20)
    }
}

struct GardenElementView: View {
    let element: GardenElement
    @State private var breathe: Bool = false

    var body: some View {
        ZStack {
            switch element.type {
            case .tree:
                VStack(spacing: 0) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(NafsTheme.gold)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "8B7355"))
                        .frame(width: 4, height: 8)
                }
            case .flower:
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "8B9E6B"))
            case .orb:
                Circle()
                    .fill(NafsTheme.gold.opacity(0.4))
                    .frame(width: 16, height: 16)
                    .scaleEffect(breathe ? 1.3 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            breathe = true
                        }
                    }
            case .bloom:
                Image(systemName: "sparkle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "A07BC5"))
                    .scaleEffect(breathe ? 1.1 : 0.9)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            breathe = true
                        }
                    }
            }
        }
    }
}

private struct GardenLegendItem: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}
