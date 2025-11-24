//
//  ShieldConfigurationExtension.swift
//  SleepShieldShieldConfiguration
//
//  Created by baegteun on 10/15/25.
//

import ManagedSettings
import ManagedSettingsUI
import SwiftUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
final class SleepShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    ShieldConfiguration(
      backgroundBlurStyle: .systemThickMaterial,
      backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95),
      icon: UIImage(resource: .appIconSymbol),
      title: ShieldConfiguration.Label(
        text: String(localized: "Sleep Well, Wake Refreshed"),
        color: .label
      ),
      subtitle: ShieldConfiguration.Label(
        text: String(localized: "\(application.localizedDisplayName ?? "This app") is blocked to help you\nrest now and wake up energized"),
        color: .secondaryLabel
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: String(localized: "OK"),
        color: .white
      ),
      primaryButtonBackgroundColor: UIColor(red: 114.0 / 255.0, green: 106.0 / 255.0, blue: 212.0 / 255.0, alpha: 1.0)
    )
  }

  override func configuration(shielding application: Application, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    return ShieldConfiguration(
      backgroundBlurStyle: .systemThickMaterial,
      backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95),
      icon: UIImage(resource: .appIconSymbol),
      title: ShieldConfiguration.Label(
        text: String(localized: "Sleep Well, Wake Refreshed"),
        color: .label
      ),
      subtitle: ShieldConfiguration.Label(
        text: String(localized: "\(application.localizedDisplayName ?? "This app") is blocked to help you\nrest now and wake up energized"),
        color: .secondaryLabel
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: String(localized: "OK"),
        color: .white
      ),
      primaryButtonBackgroundColor: UIColor(red: 114.0 / 255.0, green: 106.0 / 255.0, blue: 212.0 / 255.0, alpha: 1.0)
    )
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    ShieldConfiguration(
      backgroundBlurStyle: .systemThickMaterial,
      backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95),
      icon: UIImage(resource: .appIconSymbol),
      title: ShieldConfiguration.Label(
        text: String(localized: "Sleep Well, Wake Refreshed"),
        color: .label
      ),
      subtitle: ShieldConfiguration.Label(
        text: String(localized: "\(webDomain.domain ?? "This website") is blocked to help you\nrest now and wake up energized"),
        color: .secondaryLabel
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: String(localized: "OK"),
        color: .white
      ),
      primaryButtonBackgroundColor: UIColor(red: 114.0 / 255.0, green: 106.0 / 255.0, blue: 212.0 / 255.0, alpha: 1.0)
    )
  }

  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    ShieldConfiguration(
      backgroundBlurStyle: .systemThickMaterial,
      backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95),
      icon: UIImage(resource: .appIconSymbol),
      title: ShieldConfiguration.Label(
        text: String(localized: "Sleep Well, Wake Refreshed"),
        color: .label
      ),
      subtitle: ShieldConfiguration.Label(
        text: String(localized: "\(webDomain.domain ?? "This website") is blocked to help you\nrest now and wake up energized"),
        color: .secondaryLabel
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: String(localized: "OK"),
        color: .white
      ),
      primaryButtonBackgroundColor: UIColor(red: 114.0 / 255.0, green: 106.0 / 255.0, blue: 212.0 / 255.0, alpha: 1.0)
    )
  }
}
