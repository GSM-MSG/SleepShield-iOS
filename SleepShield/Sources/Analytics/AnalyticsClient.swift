@preconcurrency import AmplitudeSwift
import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation
import OSLog

public final class AnalyticsClient: Sendable {
  private let amplitude: Amplitude

  public static let shared = AnalyticsClient()

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "AnalyticsClient")

  private init() {
    let amplitudeAPIKey = Bundle.main.infoDictionary?["AMPLITUDE_API_KEY"] as? String
    assert(amplitudeAPIKey != nil)

#if DEBUG
    let amplitudeConfiguration = AmplitudeSwift.Configuration(
      apiKey: amplitudeAPIKey!,
      logLevel: .DEBUG
    )
#else
    let amplitudeConfiguration = AmplitudeSwift.Configuration(
      apiKey: amplitudeAPIKey!
    )
#endif
    self.amplitude = Amplitude(
      configuration: amplitudeConfiguration
    )
  }

  public func track(eventType: any AnalyticsEventType) {
    let logMessage = "📈 ANALYTICS EVENT logged : \(eventType.name) | \(eventType.properties)"
    logger.log("\(logMessage)")

    amplitude.track(
      eventType: eventType.name,
      eventProperties: eventType.properties
    )

    FirebaseAnalytics.Analytics.logEvent(eventType.name, parameters: eventType.properties)
  }

  public func sendUserProperty(propertyType property: any AnalyticsUserPropertyType) {
    let logMessage = "📈 ANALYTICS PROPERTY logged : \(property.name) | \(property.value)"
    logger.log("\(logMessage)")

    let identify = AmplitudeSwift.Identify()
    identify.set(property: property.name, value: property.value)
    amplitude.identify(identify: identify)

    if case Optional<Any>.none = property.value {
      FirebaseAnalytics.Analytics.setUserProperty(nil, forName: property.name)
    } else {
      FirebaseAnalytics.Analytics.setUserProperty("\(property.value)", forName: property.name)
    }
  }

  public func setUserID(userID: String) {
    amplitude.setUserId(userId: userID)
    FirebaseAnalytics.Analytics.setUserID(userID)
    Crashlytics.crashlytics().setUserID(userID)
  }

  public func getUserID() -> String? {
    return amplitude.getUserId()
  }

  public func getDeviceID() -> String? {
    return amplitude.getDeviceId()
  }
}
