import SwiftUI

struct NafsButton: View {
    let title: String
    var arabicSubtitle: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var style: NafsButtonStyle = .primary
    let action: () -> Void

    enum NafsButtonStyle {
        case primary, secondary, text
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let arabic = arabicSubtitle {
                    Text(title)
                        .font(.system(.headline, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(arabic)
                        .font(.system(.subheadline, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text(title)
                        .font(.system(.headline, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
            .background(isEnabled ? AnyShapeStyle(backgroundShapeStyle) : AnyShapeStyle(disabledBackground))
            .foregroundStyle(isEnabled ? foregroundColor : disabledForeground)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: style == .primary && isEnabled ? NafsTheme.goldShadow : .clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .allowsHitTesting(isEnabled && !isLoading)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isEnabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: isEnabled)
    }

    private var backgroundShapeStyle: LinearGradient {
        switch style {
        case .primary:
            return NafsTheme.goldGradient
        case .secondary:
            return LinearGradient(colors: [NafsTheme.card], startPoint: .leading, endPoint: .trailing)
        case .text:
            return LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var disabledBackground: Color {
        Color(hex: "D5D2CC")
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            .white
        case .secondary:
            NafsTheme.text
        case .text:
            NafsTheme.gold
        }
    }

    private var disabledForeground: Color {
        .white.opacity(0.7)
    }
}

struct NafsProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(NafsTheme.card)
                    .frame(height: 4)
                Capsule()
                    .fill(NafsTheme.goldGradient)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 4)
    }
}

struct NafsBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
                .frame(width: 44, height: 44)
                .background(NafsTheme.card)
                .clipShape(Circle())
        }
        .sensoryFeedback(.impact(weight: .light), trigger: UUID())
    }
}
