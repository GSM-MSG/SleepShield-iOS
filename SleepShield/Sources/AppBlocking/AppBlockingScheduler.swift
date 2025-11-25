import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

@MainActor
final class AppBlockingScheduler: Sendable {
  public enum Error: Swift.Error {
    case unexceptedNil
  }

  static let shared = AppBlockingScheduler()

  private let activityCenter: DeviceActivityCenter
  private let settingsStore: ManagedSettingsStore
  private let defaults: UserDefaults

  private struct ScheduleRequest: Sendable {
    let name: DeviceActivityName
    let schedule: DeviceActivitySchedule
  }

  var blockingIsActivated: Bool {
    let applicationIsEmpty = settingsStore.shield.applications?.isEmpty ?? true
    let applicationCategoriesIsEmpty = settingsStore.shield.applicationCategories == nil
    let webIsEmpty = settingsStore.shield.webDomains?.isEmpty ?? true
    let webCategoriesIsEmpty = settingsStore.shield.webDomainCategories == nil
    
    return !applicationIsEmpty || !applicationCategoriesIsEmpty || !webIsEmpty || !webCategoriesIsEmpty
  }

  init(
    activityCenter: DeviceActivityCenter = DeviceActivityCenter(),
    settingsStore: ManagedSettingsStore = ManagedSettingsStore(named: .sleepShieldMonitor),
    defaults: UserDefaults = .standard
  ) {
    self.activityCenter = activityCenter
    self.settingsStore = settingsStore
    self.defaults = defaults
  }

  @discardableResult
  func scheduleBlocking(
    for timeline: SleepTimeline,
    selection: FamilyActivitySelection
  ) throws -> [DeviceActivityName] {
    guard let identifier = timeline.appBlockingIdentifier else {
      throw Error.unexceptedNil
    }
    removePersistedSchedules(for: identifier)

    let requests = makeScheduleRequests(for: timeline, identifier: identifier)
    var startedNames: [DeviceActivityName] = []

    do {
      for request in requests {
        try activityCenter.startMonitoring(request.name, during: request.schedule)
        startedNames.append(request.name)
      }
      persist(startedNames, for: identifier)
      return startedNames
    } catch {
      activityCenter.stopMonitoring(startedNames)
      throw error
    }
  }

  func updateBlockingSelection(
    for timeline: SleepTimeline,
    selection: FamilyActivitySelection
  ) throws {
    guard let identifier = timeline.appBlockingIdentifier else {
      throw Error.unexceptedNil
    }
    settingsStore.clearAllSettings()

    let requests = makeScheduleRequests(for: timeline, identifier: identifier)
    var startedNames: [DeviceActivityName] = []

    do {
      removePersistedSchedules(for: identifier)

      for request in requests {
        try activityCenter.startMonitoring(request.name, during: request.schedule)
        startedNames.append(request.name)
      }
      persist(startedNames, for: identifier)
    } catch {
      activityCenter.stopMonitoring(startedNames)
      throw error
    }
  }

  func stopBlocking(for timeline: SleepTimeline) throws {
    guard let identifier = timeline.appBlockingIdentifier else {
      throw Error.unexceptedNil
    }
    removePersistedSchedules(for: identifier)
  }

  func stopBlocking(names: [DeviceActivityName]) {
    activityCenter.stopMonitoring(names)
  }

  func pauseBlocking() {
    settingsStore.shield.applications = nil
    settingsStore.shield.applicationCategories = nil
    settingsStore.shield.webDomains = nil
    settingsStore.shield.webDomainCategories = nil
  }

  func stopAllBlocking() {
    let prefix = "sleepShield.appBlocking.names."
    let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }

    activityCenter.stopMonitoring(activityCenter.activities)
    for key in keys {
      defaults.removeObject(forKey: key)
    }
  }

  private func makeScheduleRequests(
    for timeline: SleepTimeline,
    identifier: String
  ) -> [ScheduleRequest] {
    let startOffset = timeline.preSleepBlockingStartOffset
    let endOffset = timeline.postWakeBlockingEndOffset
    let activeWeekdays = timeline.repeatWeekday.deviceActivityWeekdays

    guard activeWeekdays.isEmpty == false else { return [] }

    var requests: [ScheduleRequest] = []

    for weekday in activeWeekdays {
      if startOffset <= endOffset {
        let startComponents = timeComponents(from: startOffset, weekday: weekday)
        let endComponents = timeComponents(from: endOffset, weekday: weekday)
        let name = activityName(for: identifier, weekday: weekday, segment: 0)
        let schedule = DeviceActivitySchedule(
          intervalStart: startComponents,
          intervalEnd: endComponents,
          repeats: true
        )
        requests.append(ScheduleRequest(name: name, schedule: schedule))
      } else {
        // Segment 1: from pre-sleep start until the end of the current weekday.
        let startComponents = timeComponents(from: startOffset, weekday: weekday)
        let endOfDayComponents = DateComponents(hour: 23, minute: 59, second: 59, weekday: weekday)
        let firstName = activityName(for: identifier, weekday: weekday, segment: 0)
        let firstSchedule = DeviceActivitySchedule(
          intervalStart: startComponents,
          intervalEnd: endOfDayComponents,
          repeats: true
        )
        requests.append(ScheduleRequest(name: firstName, schedule: firstSchedule))

        // Segment 2: from midnight of the next day through the post-wake buffer.
        let nextWeekday = weekday == 7 ? 1 : weekday + 1
        let midnight = DateComponents(hour: 0, minute: 0, second: 0, weekday: nextWeekday)
        let endComponents = timeComponents(from: endOffset, weekday: nextWeekday)
        let secondName = activityName(for: identifier, weekday: nextWeekday, segment: 1)
        let secondSchedule = DeviceActivitySchedule(
          intervalStart: midnight,
          intervalEnd: endComponents,
          repeats: true
        )
        requests.append(ScheduleRequest(name: secondName, schedule: secondSchedule))
      }
    }

    return requests
  }

  private func timeComponents(from offset: TimeInterval, weekday: Int) -> DateComponents {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())

    let referenceStart: Date
    if let nextMatch = calendar.nextDate(
      after: startOfToday,
      matching: DateComponents(weekday: weekday),
      matchingPolicy: .nextTimePreservingSmallerComponents,
      direction: .forward
    ) {
      referenceStart = calendar.startOfDay(for: nextMatch)
    } else {
      referenceStart = startOfToday
    }

    guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: referenceStart) else {
      return DateComponents(weekday: weekday)
    }

    let dayLength = nextDayStart.timeIntervalSince(referenceStart)
    let normalizedOffset = offset.truncatingRemainder(dividingBy: dayLength)
    let positiveOffset = normalizedOffset >= 0 ? normalizedOffset : normalizedOffset + dayLength
    let targetDate = referenceStart.addingTimeInterval(positiveOffset)
    var components = calendar.dateComponents([.hour, .minute, .second], from: targetDate)
    components.weekday = weekday
    return components
  }

  private func activityName(for identifier: String, weekday: Int, segment: Int) -> DeviceActivityName {
    let rawValue = "sleepShield.blocking.\(identifier).d\(weekday).s\(segment)"
    return DeviceActivityName(rawValue)
  }

  private func persist(_ names: [DeviceActivityName], for identifier: String) {
    let rawNames = names.map(\.rawValue)
    defaults.set(rawNames, forKey: storageKey(for: identifier))
  }

  private func removePersistedSchedules(for identifier: String) {
    let key = storageKey(for: identifier)
    if let stored = defaults.array(forKey: key) as? [String] {
      let names = stored.map { DeviceActivityName($0) }
      activityCenter.stopMonitoring(names)
    }
    defaults.removeObject(forKey: key)
  }

  private func storageKey(for identifier: String) -> String {
    "sleepShield.appBlocking.names.\(identifier)"
  }
}

private extension RepeatWeekday {
  var deviceActivityWeekdays: [Int] {
    var days: [Int] = []
    if contains(.sunday) { days.append(1) }
    if contains(.monday) { days.append(2) }
    if contains(.tuesday) { days.append(3) }
    if contains(.wednesday) { days.append(4) }
    if contains(.thursday) { days.append(5) }
    if contains(.friday) { days.append(6) }
    if contains(.saturday) { days.append(7) }
    return days
  }
}

private extension SleepTimeline {
  var appBlockingIdentifier: String? {
    if let modelID = self.persistentModelID.storeIdentifier {
      return modelID
    }
    return nil
  }
}


private extension String {
  nonisolated var removingInvalidIdentifierCharacters: String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
    var sanitized = ""
    sanitized.reserveCapacity(count)

    for scalar in unicodeScalars {
      if allowed.contains(scalar) {
        sanitized.unicodeScalars.append(scalar)
      } else {
        sanitized.append("-")
      }
    }

    return sanitized
  }
}
