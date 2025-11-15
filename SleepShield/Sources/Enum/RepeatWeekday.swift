import Foundation

struct RepeatWeekday: OptionSet, Hashable {
  let rawValue: Int16
  
  static let sunday = RepeatWeekday(rawValue: 1 << 0)
  static let monday = RepeatWeekday(rawValue: 1 << 1)
  static let tuesday = RepeatWeekday(rawValue: 1 << 2)
  static let wednesday = RepeatWeekday(rawValue: 1 << 3)
  static let thursday = RepeatWeekday(rawValue: 1 << 4)
  static let friday = RepeatWeekday(rawValue: 1 << 5)
  static let saturday = RepeatWeekday(rawValue: 1 << 6)
  
  static let everyday: RepeatWeekday = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
  static let weekdays: RepeatWeekday = [.monday, .tuesday, .wednesday, .thursday, .friday]
  static let weekend: RepeatWeekday = [.saturday, .sunday]
  
  static let allOptions: [RepeatWeekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
}
