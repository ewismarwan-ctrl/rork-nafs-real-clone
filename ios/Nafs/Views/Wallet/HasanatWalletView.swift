import SwiftUI

struct HasanatWalletView: View {
    let viewModel: AppViewModel
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                balanceHeader
                weeklyChart
                weeklySummary
                transactionList
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.text("Hasanat Wallet", "محفظة الحسنات"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var balanceHeader: some View {
        VStack(spacing: 8) {
            Text(L10n.text("TOTAL BALANCE", "الرصيد الإجمالي"))
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)
                .tracking(1.5)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.hasanatBalance)")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                    .contentTransition(.numericText())
                Image(systemName: "sparkle")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
            Text(viewModel.balanceMessage)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("This Week", "هذا الأسبوع"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    WeeklyBar(
                        earned: viewModel.weeklyEarned[day],
                        spent: viewModel.weeklySpent[day],
                        maxVal: viewModel.weeklyEarned.max() ?? 1,
                        dayLabel: dayLabel(day)
                    )
                }
            }
            .frame(height: 140)

            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(NafsTheme.gold).frame(width: 8, height: 8)
                    Text("Earned")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                HStack(spacing: 6) {
                    Circle().fill(NafsTheme.text.opacity(0.25)).frame(width: 8, height: 8)
                    Text("Spent")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
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

    private var weeklySummary: some View {
        let totalEarned = viewModel.weeklyEarned.reduce(0, +)
        let totalSpent = viewModel.weeklySpent.reduce(0, +)
        return HStack(spacing: 12) {
            WeeklySummaryPill(label: "Earned", value: "+\(totalEarned)", color: NafsTheme.gold)
            WeeklySummaryPill(label: "Spent", value: "-\(totalSpent)", color: NafsTheme.text.opacity(0.5))
            WeeklySummaryPill(label: "Net", value: "+\(totalEarned - totalSpent)", color: NafsTheme.gold)
        }
    }

    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("Transaction History", "سجل المعاملات"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            ForEach(viewModel.transactions) { tx in
                TransactionRow(transaction: tx)
            }
        }
    }

    private func dayLabel(_ index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[index]
    }
}

private struct WeeklyBar: View {
    let earned: Int
    let spent: Int
    let maxVal: Int
    let dayLabel: String

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            HStack(alignment: .bottom, spacing: 2) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(NafsTheme.gold)
                    .frame(width: 14, height: max(4, CGFloat(earned) / CGFloat(maxVal) * 100))
                RoundedRectangle(cornerRadius: 3)
                    .fill(NafsTheme.text.opacity(0.2))
                    .frame(width: 14, height: max(4, CGFloat(spent) / CGFloat(max(maxVal, 1)) * 100))
            }
            Text(dayLabel)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeeklySummaryPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transaction.isEarned ? NafsTheme.gold.opacity(0.12) : NafsTheme.text.opacity(0.08))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: transaction.icon)
                        .font(.system(.caption))
                        .foregroundStyle(transaction.isEarned ? NafsTheme.gold : NafsTheme.subtleText)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                    .lineLimit(1)
                Text(transaction.date.formatted(.relative(presentation: .named)))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Spacer()

            Text(transaction.isEarned ? "+\(transaction.tokens)" : "-\(transaction.tokens)")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(transaction.isEarned ? NafsTheme.gold : NafsTheme.text.opacity(0.5))
        }
        .padding(.vertical, 6)
    }
}
