import ManagedSettings
import ManagedSettingsUI
import UIKit

nonisolated final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    nonisolated override func configuration(shielding application: Application) -> ShieldConfiguration {
        nafsShieldConfiguration()
    }

    nonisolated override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        nafsShieldConfiguration()
    }

    nonisolated override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        nafsShieldConfiguration()
    }

    nonisolated override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        nafsShieldConfiguration()
    }

    private nonisolated func nafsShieldConfiguration() -> ShieldConfiguration {
        let background = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1.0)
        let gold = UIColor(red: 0.82, green: 0.66, blue: 0.38, alpha: 1.0)
        let softGold = UIColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 1.0)
        let white = UIColor.white
        let muted = UIColor(red: 0.78, green: 0.72, blue: 0.60, alpha: 1.0)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: background,
            icon: UIImage(systemName: "moon.stars.fill")?.withTintColor(gold, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "Access denied", color: white),
            subtitle: ShieldConfiguration.Label(text: "Complete your discipline to continue.", color: muted),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open Nafs", color: .black),
            primaryButtonBackgroundColor: softGold
        )
    }
}
