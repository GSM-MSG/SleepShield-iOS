import AlarmKit
import AppIntents

struct StopIntent: LiveActivityIntent {
  func perform() throws -> some IntentResult {
    if let id = UUID(uuidString: alarmID) {
      try AlarmManager.shared.stop(id: id)
    }
    return .result()
  }

  static var title: LocalizedStringResource { "Stop" }
  static var description: IntentDescription { IntentDescription("Stop an alert") }

  static var isDiscoverable: Bool { false }

  @Parameter(title: "alarmID")
  var alarmID: String

  init(alarmID: String) {
    self.alarmID = alarmID
  }

  init() {
    self.alarmID = ""
  }
}

struct RepeatIntent: LiveActivityIntent {
  func perform() throws -> some IntentResult {
    if let id = UUID(uuidString: alarmID) {
      try AlarmManager.shared.countdown(id: id)
    }
    return .result()
  }

  static var title: LocalizedStringResource { "Repeat" }
  static var description: IntentDescription { IntentDescription("Repeat a countdown") }

  static var isDiscoverable: Bool { false }

  @Parameter(title: "alarmID")
  var alarmID: String

  init(alarmID: String) {
    self.alarmID = alarmID
  }

  init() {
    self.alarmID = ""
  }
}
