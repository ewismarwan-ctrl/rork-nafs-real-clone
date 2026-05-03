import Foundation

nonisolated enum SubscriptionPlan: String, CaseIterable, Sendable, Identifiable {
    case weekly, monthly, yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return NafsStrings.weeklyTitle.localized
        case .monthly: return NafsStrings.monthlyTitle.localized
        case .yearly: return NafsStrings.yearlyTitle.localized
        }
    }

    var price: String {
        switch self {
        case .weekly: return "$1.99"
        case .monthly: return "$7.99"
        case .yearly: return "$39.99"
        }
    }

    var period: String {
        switch self {
        case .weekly: return NafsStrings.perWeek.localized
        case .monthly: return NafsStrings.perMonth.localized
        case .yearly: return NafsStrings.perYear.localized
        }
    }

    var badge: String? {
        switch self {
        case .weekly: return NafsStrings.tryItOut.localized
        case .monthly: return nil
        case .yearly: return NafsStrings.mostPopular.localized
        }
    }

    var hasTrial: Bool { self == .yearly }

    var subtitle: String? {
        switch self {
        case .yearly: return NafsStrings.lessThanWeek.localized
        default: return nil
        }
    }
}
