import SwiftUI

struct MultiSelectGrid: View {
    let options: [SelectionOption]
    let selected: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(options) { option in
                MultiSelectCell(
                    option: option,
                    isSelected: selected.contains(option.id),
                    onTap: { onToggle(option.id) }
                )
            }
        }
    }
}

struct MultiSelectCell: View {
    let option: SelectionOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if !option.icon.isEmpty {
                    Image(systemName: option.icon)
                        .font(.system(.title2))
                        .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.subtleText)
                }
                Text(option.title)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(isSelected ? NafsTheme.text : NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 90)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(isSelected ? NafsTheme.gold.opacity(0.12) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct SingleSelectList: View {
    let options: [SelectionOption]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                SingleSelectRow(
                    option: option,
                    isSelected: selected == option.id,
                    onTap: { onSelect(option.id) }
                )
            }
        }
    }
}

struct SingleSelectRow: View {
    let option: SelectionOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                if !option.icon.isEmpty {
                    Image(systemName: option.icon)
                        .font(.system(.body))
                        .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.subtleText)
                        .frame(width: 28)
                }
                Text(option.title)
                    .font(.system(.body, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(NafsTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                Circle()
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(NafsTheme.gold)
                                .frame(width: 12, height: 12)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3), value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
