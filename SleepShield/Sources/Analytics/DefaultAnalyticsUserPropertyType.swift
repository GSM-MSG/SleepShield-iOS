import Foundation

extension AnalyticsClient {
  func sendUserProperty(property: DefaultAnalyticsUserProperty) {
    self.sendUserProperty(propertyType: property)
  }
}

enum DefaultAnalyticsUserProperty: AnalyticsUserPropertyType {
  // Sleep Timeline
  case totalSleepRoutines(Int)
  case hasWeekdayRoutine(Bool)
  case hasWeekendRoutine(Bool)
  case activeWeekdays([String]) // ["MON", "TUE", ...]
  case averageSleepTime(String) // HH:mm
  case averageWakeTime(String) // HH:mm
  case preSleepBlockDuration(Int) // minutes
  case postWakeBlockDuration(Int) // minutes

  // Alarms
  case totalAlarms(Int)
  case hasSnoozeEnabled(Bool)

  // App Blocking
  case blockedAppsCount(Int)
  case blockedCategoriesCount(Int)
  case blockedWebDomainsCount(Int)
  case totalBlockedItemsCount(Int)

  var name: String {
    switch self {
    default: String(describing: self)
        .components(separatedBy: "(")
        .first?
        .snakeCased() ?? {
          assertionFailure("Invalid event name")
          return ""
        }()
    }
  }

  var value: Any {
    switch self {
    case .totalSleepRoutines(let count):
      return count
    case .hasWeekdayRoutine(let hasRoutine):
      return hasRoutine
    case .hasWeekendRoutine(let hasRoutine):
      return hasRoutine
    case .activeWeekdays(let weekdays):
      return weekdays
    case .averageSleepTime(let time):
      return time
    case .averageWakeTime(let time):
      return time
    case .preSleepBlockDuration(let minutes):
      return minutes
    case .postWakeBlockDuration(let minutes):
      return minutes
    case .totalAlarms(let count):
      return count
    case .hasSnoozeEnabled(let enabled):
      return enabled
    case .blockedAppsCount(let count):
      return count
    case .blockedCategoriesCount(let count):
      return count
    case .blockedWebDomainsCount(let count):
      return count
    case .totalBlockedItemsCount(let count):
      return count
    }
  }
}

private extension String {
  func snakeCased() -> String {
    let regex = try? NSRegularExpression(pattern: "([a-z]*)([A-Z])")
    return regex?.stringByReplacingMatches(
      in: self,
      range: NSRange(0..<utf16.count),
      withTemplate: "$1 $2"
    )
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .components(separatedBy: " ")
    .joined(separator: "_")
    .lowercased() ?? ""
  }
}
