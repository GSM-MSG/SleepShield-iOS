import AlarmKit
import FamilyControls
import Foundation
import SwiftData

@MainActor
struct UserPropertyUpdater {
  static func updateAllProperties(
    modelContext: ModelContext,
    alarmScheduler: AlarmScheduler,
    familyActivitySelection: FamilyActivitySelection,
    onboardingCompleted: Bool
  ) {
    updateSleepTimelineProperties(modelContext: modelContext)

    updateAlarmProperties(alarmScheduler: alarmScheduler)

    updateAppBlockingProperties(familyActivitySelection: familyActivitySelection)
  }

  static func updateSleepTimelineProperties(modelContext: ModelContext) {
    let timelines = (try? modelContext.fetch(FetchDescriptor<SleepTimeline>())) ?? []

    AnalyticsClient.shared.sendUserProperty(property: .totalSleepRoutines(timelines.count))

    let weekdays = RepeatWeekday.weekdays
    let weekend = RepeatWeekday.weekend

    let hasWeekdayRoutine = timelines.contains { timeline in
      !timeline.repeatWeekday.intersection(weekdays).isEmpty
    }
    let hasWeekendRoutine = timelines.contains { timeline in
      !timeline.repeatWeekday.intersection(weekend).isEmpty
    }

    AnalyticsClient.shared.sendUserProperty(property: .hasWeekdayRoutine(hasWeekdayRoutine))
    AnalyticsClient.shared.sendUserProperty(property: .hasWeekendRoutine(hasWeekendRoutine))

    let allActiveWeekdays = timelines.reduce(into: RepeatWeekday()) { result, timeline in
      result.formUnion(timeline.repeatWeekday)
    }
    let activeWeekdaysArray = DefaultAnalyticsEvent.weekdayStrings(from: allActiveWeekdays)
    AnalyticsClient.shared.sendUserProperty(property: .activeWeekdays(activeWeekdaysArray))

    if !timelines.isEmpty {
      let totalSleepSeconds = timelines.reduce(0.0) { $0 + $1.sleepTimeSecondsOffset }
      let totalWakeSeconds = timelines.reduce(0.0) { $0 + $1.wakeTimeSecondsOffset }
      let totalPreSleepDuration = timelines.reduce(0.0) { $0 + $1.preSleepBlockDuration }
      let totalPostWakeDuration = timelines.reduce(0.0) { $0 + $1.postWakeBlockDuration }

      let avgSleepSeconds = totalSleepSeconds / Double(timelines.count)
      let avgWakeSeconds = totalWakeSeconds / Double(timelines.count)
      let avgPreSleepMinutes = Int(totalPreSleepDuration / Double(timelines.count) / 60)
      let avgPostWakeMinutes = Int(totalPostWakeDuration / Double(timelines.count) / 60)

      let avgSleepTime = formatTime(seconds: avgSleepSeconds)
      let avgWakeTime = formatTime(seconds: avgWakeSeconds)

      AnalyticsClient.shared.sendUserProperty(property: .averageSleepTime(avgSleepTime))
      AnalyticsClient.shared.sendUserProperty(property: .averageWakeTime(avgWakeTime))
      AnalyticsClient.shared.sendUserProperty(property: .preSleepBlockDuration(avgPreSleepMinutes))
      AnalyticsClient.shared.sendUserProperty(property: .postWakeBlockDuration(avgPostWakeMinutes))
    }
  }

  static func updateAlarmProperties(alarmScheduler: AlarmScheduler) {
    let alarms = alarmScheduler.alarms

    AnalyticsClient.shared.sendUserProperty(property: .totalAlarms(alarms.count))

    let hasSnooze = alarms.contains { alarm in
      alarm.countdownDuration?.postAlert != nil
    }
    AnalyticsClient.shared.sendUserProperty(property: .hasSnoozeEnabled(hasSnooze))
  }

  static func updateAppBlockingProperties(familyActivitySelection: FamilyActivitySelection) {
    let appsCount = familyActivitySelection.applications.count
    let categoriesCount = familyActivitySelection.categories.count
    let webDomainsCount = familyActivitySelection.webDomains.count
    let totalCount = appsCount + categoriesCount + webDomainsCount

    AnalyticsClient.shared.sendUserProperty(property: .blockedAppsCount(appsCount))
    AnalyticsClient.shared.sendUserProperty(property: .blockedCategoriesCount(categoriesCount))
    AnalyticsClient.shared.sendUserProperty(property: .blockedWebDomainsCount(webDomainsCount))
    AnalyticsClient.shared.sendUserProperty(property: .totalBlockedItemsCount(totalCount))
  }

  private static func formatTime(seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let hours = (totalSeconds / 3600) % 24
    let minutes = (totalSeconds % 3600) / 60
    return String(format: "%02d:%02d", hours, minutes)
  }
}
