@preconcurrency import AlarmKit
import Foundation
import SwiftUI

@Observable
@MainActor
final class AlarmScheduler: Sendable {
  private(set) var alarms: [Alarm] = []

  @ObservationIgnored
  private var alarmObserver: Task<Void, Never>?

  private let alarmManager: AlarmManager

  public var authorizationStatus: AlarmManager.AuthorizationState {
    alarmManager.authorizationState
  }

  init() {
    self.alarmManager = AlarmManager.shared
    self.alarms = (try? alarmManager.alarms) ?? []
    observeAlarmUpdates()
  }

  public func alarms(weekday: Locale.Weekday) -> [Alarm] {
    return alarms.filter { alarm in
      if case .relative(let relative) = alarm.schedule,
         case .weekly(let weekdays) = relative.repeats {
        return weekdays.contains(weekday)
      } else {
        return false
      }
    }
  }

  public func alarms(containsWeekday weekday: RepeatWeekday) -> [Alarm] {
    let localeWeekday = weekday.localeWeekdays
    return alarms.filter { alarm in
      if case .relative(let relative) = alarm.schedule,
         case .weekly(let weekdays) = relative.repeats {
        return localeWeekday.allSatisfy(weekdays.contains(_:))
      } else {
        return false
      }
    }
  }

  public func alarms(equalWeekday weekday: RepeatWeekday) -> [Alarm] {
    let localeWeekday = weekday.localeWeekdays
    return alarms.filter { alarm in
      if case .relative(let relative) = alarm.schedule,
         case .weekly(let weekdays) = relative.repeats {
        return weekdays.contains(localeWeekday)
      } else {
        return false
      }
    }
  }

  @discardableResult
  public func schedule<Metadata: AlarmMetadata>(
    id: Alarm.ID,
    configuration: AlarmManager.AlarmConfiguration<Metadata>
  ) async throws -> Alarm {
    return try await alarmManager.schedule(
      id: id,
      configuration: configuration
    )
  }

  public func cancel(id: Alarm.ID) throws {
    try alarmManager.cancel(id: id)
  }

  private func observeAlarmUpdates() {
    self.alarmObserver?.cancel()
    self.alarmObserver = Task {
      for await newAlarms in alarmManager.alarmUpdates {
        self.alarms = newAlarms
      }
    }
  }
}

extension EnvironmentValues {
  @Entry var alarmScheduler: AlarmScheduler = .init()
}

