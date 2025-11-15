import Foundation

extension AnalyticsClient {
  func track(event: DefaultAnalyticsEvent) {
    self.track(eventType: event)
  }
}

enum DefaultAnalyticsEvent: AnalyticsEventType {
  private static let timeOnlyFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  // Onboarding
  case viewOnboarding
  case viewOnboardingScrollBlock
  case viewOnboardingSleep
  case setupOnboardingSleeptime(preSleepBlock: Int, sleepTime: Date)
  case viewOnboardingWake
  case setupOnboardingWaketime(postWakeBlock: Int, wakeTime: Date)
  case viewOnboardingAlarmSetup
  case setupOnboardingAlarm(alarmTime: Date)
  case skipOnboardingAlarm
  case viewOnboardingSummary
  case viewScreenTimePermission
  case completeOnboarding(alarmTime: Date?, postWakeBlock: Int, preSleepBlock: Int, sleepTime: Date, wakeTime: Date, weekday: [String])

  // Home
  case viewHome
  case clickFamilyPicker
  case clickDisableBlocking

  // SleepTimelineEditor
  case viewSleepRoutineEditor(isEdit: Bool, entry: ViewSleepRoutineEditorEntry)
  case saveSleepRoutine(isEdit: Bool, entry: ViewSleepRoutineEditorEntry, postWakeBlock: Int, preSleepBlock: Int, sleepTime: Date, wakeTime: Date, weekday: [String])
  case deleteSleepRoutine
  case addAlarmToTimeline(alarmTime: Date)
  case removeAlarmFromTimeline

  // SleepTimelineList
  case viewSleepRoutineList

  // Settings
  case viewSettings
  case clickRateApp
  case clickShareApp

  // AlarmList
  case viewAlarmList

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

  var properties: [String: Any]? {
    switch self {
    case .setupOnboardingSleeptime(let preSleepBlock, let sleepTime):
      return [
        "pre_sleep_block_min": preSleepBlock,
        "sleep_time": Self.timeOnlyFormatter.string(from: sleepTime)
      ]
    case .setupOnboardingWaketime(let postWakeBlock, let wakeTime):
      return [
        "post_wake_block_min": postWakeBlock,
        "wake_time": Self.timeOnlyFormatter.string(from: wakeTime)
      ]
    case .setupOnboardingAlarm(let alarmTime):
      return [
        "alarm_time": Self.timeOnlyFormatter.string(from: alarmTime)
      ]
    case .completeOnboarding(let alarmTime, let postWakeBlock, let preSleepBlock, let sleepTime, let wakeTime, let weekday):
      var props: [String: Any] = [
        "post_wake_block_min": postWakeBlock,
        "pre_sleep_block_min": preSleepBlock,
        "sleep_time": Self.timeOnlyFormatter.string(from: sleepTime),
        "wake_time": Self.timeOnlyFormatter.string(from: wakeTime),
        "weekday": weekday
      ]
      if let alarmTime = alarmTime {
        props["alarm_time"] = Self.timeOnlyFormatter.string(from: alarmTime)
      }
      return props
    case .viewSleepRoutineEditor(let isEdit, let entry):
      return [
        "is_edit": isEdit,
        "entry": entry.analyticsName
      ]
    case .saveSleepRoutine(let isEdit, let entry, let postWakeBlock, let preSleepBlock, let sleepTime, let wakeTime, let weekday):
      return [
        "is_edit": isEdit,
        "entry": entry.analyticsName,
        "post_wake_block_min": postWakeBlock,
        "pre_sleep_block_min": preSleepBlock,
        "sleep_time": Self.timeOnlyFormatter.string(from: sleepTime),
        "wake_time": Self.timeOnlyFormatter.string(from: wakeTime),
        "weekday": weekday
      ]
    case .addAlarmToTimeline(let alarmTime):
      return [
        "alarm_time": Self.timeOnlyFormatter.string(from: alarmTime)
      ]
    default:
      return nil
    }
  }
}

extension DefaultAnalyticsEvent {
  enum ViewSleepRoutineEditorEntry: Sendable {
    case home
    case list

    var analyticsName: String {
      switch self {
      case .home: return "home"
      case .list: return "list"
      }
    }
  }
}

extension DefaultAnalyticsEvent {
  static func weekdayStrings(from repeatWeekday: RepeatWeekday) -> [String] {
    var result: [String] = []

    if repeatWeekday.contains(.sunday) { result.append("SUN") }
    if repeatWeekday.contains(.monday) { result.append("MON") }
    if repeatWeekday.contains(.tuesday) { result.append("TUE") }
    if repeatWeekday.contains(.wednesday) { result.append("WED") }
    if repeatWeekday.contains(.thursday) { result.append("THU") }
    if repeatWeekday.contains(.friday) { result.append("FRI") }
    if repeatWeekday.contains(.saturday) { result.append("SAT") }

    return result
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
