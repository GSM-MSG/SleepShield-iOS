import StoreKit
import SwiftUI

struct SettingsView: View {
  @AppStorage("hasRatedApp") private var hasRatedApp = false

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Environment(\.requestReview) private var requestReview

  private let supportEmail = "support@sleepshield.app"

  private var appName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? "SleepShield"
  }

  private var appVersion: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    switch (version, build) {
    case let (.some(version), .some(build)):
      return "Version \(version) (\(build))"
    case let (.some(version), .none):
      return "Version \(version)"
    default:
      return "Version unavailable"
    }
  }

  private var appStoreURL: URL? {
    URL(string: "https://apps.apple.com/app/id0000000000")
  }

  private var shareURL: URL? {
    URL(string: "https://msg.dev/sleepshield")
  }

  var body: some View {
    Form {
      actionSection()
      alarmSection()
      infoSection()
    }
    .formStyle(.grouped)
    .navigationTitle("Settings")
    .onAppear {
      AnalyticsClient.shared.track(event: .viewSettings)
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(role: .close) {
          dismiss()
        }
      }
    }
  }

  @ViewBuilder
  private func actionSection() -> some View {
    Section("Stay Connected") {
      Button(action: contactSupport) {
        SettingsRow(
          title: String(localized: "Contact Us"),
          accent: .init(primary: Color.cyan, secondary: Color.blue)
        ) {
          Image(systemName: "envelope.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color.white)
        }
      }
      .buttonStyle(.plain)

      Button(action: rateApp) {
        SettingsRow(
          title: String(localized: "Write a Review"),
          accent: .init(primary: Color.yellow, secondary: Color.orange)
        ) {
          Image(systemName: "star.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color.white)
        }
      }
      .buttonStyle(.plain)

      if let shareURL {
        ShareLink(item: shareURL) {
          SettingsRow(
            title: String(localized: "Share with Friends"),
            accent: .init(primary: Color.green, secondary: Color.teal)
          ) {
            Image(systemName: "square.and.arrow.up.fill")
              .font(.system(size: 16))
              .foregroundStyle(Color.white)
          }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
          AnalyticsClient.shared.track(event: .clickShareApp)
        })
      }
    }
  }

  @ViewBuilder
  private func alarmSection() -> some View {
    Section("Alarm") {
      NavigationLink(destination: AlarmListView()) {
        SettingsRow(
          title: String(localized: "Scheduled Alarms"),
          accent: .init(primary: Color.purple, secondary: Color.pink)
        ) {
          Image(systemName: "alarm.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color.white)
        }
      }
    }
  }

  @ViewBuilder
  private func infoSection() -> some View {
    Section("About") {
      SettingsRow(
        title: appName,
        subtitle: appVersion,
        accent: .init(primary: Color.clear, secondary: Color.clear)
      ) {
        Image(.appIconSymbol)
          .resizable()
          .frame(width: 32, height: 32)
          .clipShape(.rect(cornerRadius: 4))
      }
    }
  }

  private func contactSupport() {
    guard let url = URL(string: "mailto:\(supportEmail)") else { return }
    openURL(url)
  }

  private func rateApp() {
    AnalyticsClient.shared.track(event: .clickRateApp)
    if hasRatedApp, let appStoreURL {
      openURL(appStoreURL)
      return
    }

    hasRatedApp = true
    requestReview()
  }
}

private struct SettingsRow<Icon: View>: View {
  struct Accent {
    let primary: Color
    let secondary: Color
  }

  let title: String
  let subtitle: String?
  let accent: Accent
  private let icon: Icon

  private var hasSubtitle: Bool {
    subtitle?.isEmpty == false
  }

  init(
    title: String,
    subtitle: String? = nil,
    accent: Accent,
    @ViewBuilder icon: () -> Icon
  ) {
    self.title = title
    self.subtitle = subtitle
    self.accent = accent
    self.icon = icon()
  }

  var body: some View {
    HStack(spacing: 12) {
      ZStack {
        AngularGradient(
          gradient: Gradient(colors: [accent.primary, accent.secondary]),
          center: .center
        )
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )

        icon
      }

      VStack(alignment: .leading, spacing: hasSubtitle ? 4 : 0) {
        Text(title)
          .font(.headline)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)

        if let subtitle, hasSubtitle {
          Text(subtitle)
            .font(.subheadline)
            .fontDesign(.rounded)
            .foregroundStyle(Color.textPrimary.secondary)
        }
      }

      Spacer(minLength: 0)
    }
    .contentShape(.rect)
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
}

