import AlarmKit

extension AlarmKit.Alarm.Schedule.Relative.Recurrence {
  init(repeatWeekDay: RepeatWeekday) {
    let locales: [Locale.Weekday] = RepeatWeekday.allOptions.compactMap { option in
      if repeatWeekDay.contains(option) {
        switch option {
        case .sunday: return Locale.Weekday.sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        default: return nil
        }
      } else {
        return nil
      }
    }
    self = .weekly(locales)
  }
}

extension RepeatWeekday {
  var localeWeekdays: [Locale.Weekday] {
    let weekdays: [Locale.Weekday] = [
      .sunday,
      .monday,
      .tuesday,
      .wednesday,
      .thursday,
      .friday,
      .saturday
    ]

    return weekdays.filter { self.contains(RepeatWeekday(localeWeekday: $0)) }
  }
}

extension RepeatWeekday {
  init(localeWeekday: Locale.Weekday) {
    switch localeWeekday {
    case .sunday: self = .sunday
    case .monday: self = .monday
    case .tuesday: self = .tuesday
    case .wednesday: self = .wednesday
    case .thursday: self = .thursday
    case .friday: self = .friday
    case .saturday: self = .saturday
    default: self = .sunday
    }
  }
}
