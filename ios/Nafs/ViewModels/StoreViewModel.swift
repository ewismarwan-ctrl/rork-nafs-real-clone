import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
class StoreViewModel {
    var offerings: Offerings?
    var isPremium: Bool = false
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?
    var activePlan: ActivePlan?
    var activeProductId: String?
    var expirationDate: Date?
    var isInTrialPeriod: Bool = false
    var willRenew: Bool = false
    private var hasLoadedOfferings: Bool = false

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferingsWithRetry() }
        Task { await checkStatus() }
    }

    private static let entitlementID = "Nafs Premium Pro"

    private func hasPremiumAccess(_ info: CustomerInfo) -> Bool {
        info.entitlements[Self.entitlementID]?.isActive == true || !info.activeSubscriptions.isEmpty
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = hasPremiumAccess(info)
            self.updatePlanInfo(from: info)
        }
    }

    private func updatePlanInfo(from info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementID]
        let productId = entitlement?.productIdentifier ?? info.activeSubscriptions.first
        activeProductId = productId
        expirationDate = entitlement?.expirationDate
        willRenew = entitlement?.willRenew ?? false
        isInTrialPeriod = entitlement?.periodType == .trial
        activePlan = ActivePlan.detect(productId: productId, packages: offerings?.current?.availablePackages)
        NotificationService.shared.scheduleSubscriptionExpiryReminders(
            plan: activePlan,
            expirationDate: expirationDate,
            isInTrial: isInTrialPeriod,
            willRenew: willRenew
        )
    }

    private func fetchOfferingsWithRetry() async {
        for attempt in 1...3 {
            await fetchOfferings()
            if offerings?.current != nil {
                hasLoadedOfferings = true
                return
            }
            if attempt < 3 {
                print("[Nafs Store] Retry \(attempt)/3 — waiting before next attempt...")
                try? await Task.sleep(for: .seconds(Double(attempt) * 2))
            }
        }
    }

    func fetchOfferings() async {
        isLoading = true
        error = nil
        do {
            offerings = try await Purchases.shared.offerings()
            if let current = offerings?.current {
                hasLoadedOfferings = true
                print("[Nafs Store] Current offering: \(current.identifier)")
                print("[Nafs Store] Available packages: \(current.availablePackages.map { "\($0.identifier) -> \($0.storeProduct.productIdentifier)" })")
            } else {
                print("[Nafs Store] No current offering found.")
            }
        } catch {
            print("[Nafs Store] fetchOfferings error: \(error)")
        }
        isLoading = false
    }

    func purchase(package: Package) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        error = nil
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                return false
            }
            if hasPremiumAccess(result.customerInfo) {
                isPremium = true
                return true
            }
            let freshInfo = try await Purchases.shared.customerInfo()
            if hasPremiumAccess(freshInfo) {
                isPremium = true
                return true
            }
            return true
        } catch let error as ErrorCode {
            switch error {
            case .purchaseCancelledError:
                return false
            case .paymentPendingError:
                self.error = "Your purchase is pending approval. Premium will unlock once payment is confirmed."
                return false
            case .storeProblemError:
                let info = try? await Purchases.shared.customerInfo()
                if let info, hasPremiumAccess(info) {
                    isPremium = true
                    return true
                }
                self.error = "Purchase could not be completed. Please make sure you are signed into a Sandbox account in Settings \u{2192} App Store and try again."
                return false
            default:
                self.error = "Purchase could not be completed. Please make sure you are signed into a Sandbox account in Settings \u{2192} App Store and try again."
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == "SKErrorDomain" && nsError.code == 2 {
                return false
            }
            let info = try? await Purchases.shared.customerInfo()
            if let info, hasPremiumAccess(info) {
                isPremium = true
                return true
            }
            self.error = "Purchase could not be completed. Please make sure you are signed into a Sandbox account in Settings \u{2192} App Store and try again."
        }
        return false
    }

    func restore() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            let hasAccess = hasPremiumAccess(info)
            isPremium = hasAccess
            return hasAccess
        } catch {
            self.error = "Could not restore purchases. Please try again."
            return false
        }
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = hasPremiumAccess(info)
            updatePlanInfo(from: info)
        } catch {
            print("[Nafs Store] checkStatus error: \(error)")
        }
    }

    var weeklyPackage: Package? {
        if let pkg = offerings?.current?.package(identifier: "$rc_weekly") { return pkg }
        return offerings?.current?.availablePackages.first { $0.packageType == .weekly }
    }

    var monthlyPackage: Package? {
        if let pkg = offerings?.current?.package(identifier: "$rc_monthly") { return pkg }
        return offerings?.current?.availablePackages.first { $0.packageType == .monthly }
    }

    var yearlyPackage: Package? {
        if let pkg = offerings?.current?.package(identifier: "$rc_annual") { return pkg }
        return offerings?.current?.availablePackages.first { $0.packageType == .annual }
    }

    var discountedYearlyPackage: Package? {
        // TODO: Replace the identifier matching below with the exact RevenueCat
        // one-time-offer product/package ID once the discounted annual product exists.
        offerings?.current?.availablePackages.first {
            let identifier = "\($0.identifier) \($0.storeProduct.productIdentifier)".lowercased()
            return $0.packageType == .annual && (identifier.contains("discount") || identifier.contains("offer") || identifier.contains("70"))
        }
    }

    var hasPackages: Bool {
        weeklyPackage != nil || monthlyPackage != nil || yearlyPackage != nil
    }
}

nonisolated enum ActivePlan: String, Sendable {
    case weekly
    case monthly
    case yearly

    static func detect(productId: String?, packages: [Package]?) -> ActivePlan? {
        guard let productId else { return nil }
        if let packages {
            for pkg in packages where pkg.storeProduct.productIdentifier == productId {
                switch pkg.packageType {
                case .weekly: return .weekly
                case .monthly: return .monthly
                case .annual: return .yearly
                default: break
                }
            }
        }
        let lower = productId.lowercased()
        if lower.contains("year") || lower.contains("annual") { return .yearly }
        if lower.contains("month") { return .monthly }
        if lower.contains("week") { return .weekly }
        return nil
    }
}
