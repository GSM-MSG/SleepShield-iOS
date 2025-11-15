import Foundation
import SwiftData

@Model
final class SleepTimeline {
  var sleepTimeSecondsOffset: TimeInterval
  var wakeTimeSecondsOffset: TimeInterval
  var preSleepBlockDuration: TimeInterval
  var postWakeBlockDuration: TimeInterval
  var repeatWeekdayRawValue: Int16

  var repeatWeekday: RepeatWeekday {
    RepeatWeekday(rawValue: self.repeatWeekdayRawValue)
  }

  init(
    sleepTimeSecondsOffset: TimeInterval,
    wakeTimeSecondsOffset: TimeInterval,
    preSleepBlockDuration: TimeInterval,
    postWakeBlockDuration: TimeInterval,
    repeatWeekdayRawValue: Int16
  ) {
    self.sleepTimeSecondsOffset = sleepTimeSecondsOffset
    self.wakeTimeSecondsOffset = wakeTimeSecondsOffset
    self.preSleepBlockDuration = preSleepBlockDuration
    self.postWakeBlockDuration = postWakeBlockDuration
    self.repeatWeekdayRawValue = repeatWeekdayRawValue
  }
}

extension SleepTimeline {
  private func normalizedOffset(_ value: TimeInterval) -> TimeInterval {
    let calendar = Calendar.current
    let referenceDayStart = calendar.startOfDay(for: Date())
    let candidate = referenceDayStart.addingTimeInterval(value)
    let candidateDayStart = calendar.startOfDay(for: candidate)
    guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: candidateDayStart) else {
      return value
    }
    let dayLength = nextDayStart.timeIntervalSince(candidateDayStart)
    let remainder = candidate.timeIntervalSince(candidateDayStart)
      .truncatingRemainder(dividingBy: dayLength)
    return remainder >= 0 ? remainder : remainder + dayLength
  }

  var preSleepBlockingStartOffset: TimeInterval {
    normalizedOffset(sleepTimeSecondsOffset - preSleepBlockDuration)
  }

  var postWakeBlockingEndOffset: TimeInterval {
    normalizedOffset(wakeTimeSecondsOffset + postWakeBlockDuration)
  }

  func isBlockingActive(at date: Date, calendar: Calendar) -> Bool {
    guard preSleepBlockDuration > 0 || postWakeBlockDuration > 0 else {
      return false
    }

    let startOffset = preSleepBlockingStartOffset
    let endOffset = postWakeBlockingEndOffset

    guard startOffset != endOffset else {
      return false
    }

    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    let hour: TimeInterval = TimeInterval(components.hour ?? 0) * 3600.0
    let minute: TimeInterval = TimeInterval(components.minute ?? 0) * 60
    let second: TimeInterval = TimeInterval(components.second ?? 0)
    let currentOffset = TimeInterval(
      hour + minute + second
    )

    if startOffset < endOffset {
      return currentOffset >= startOffset && currentOffset < endOffset
    }

    return currentOffset >= startOffset || currentOffset < endOffset
  }
}
