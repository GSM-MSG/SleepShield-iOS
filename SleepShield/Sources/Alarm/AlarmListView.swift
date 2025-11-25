import AlarmKit
import SwiftUI

struct AlarmListView: View {
  @Environment(\.alarmScheduler) private var alarmScheduler

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      if alarmScheduler.alarms.isEmpty {
        ContentUnavailableView(
          "No alarms yet",
          systemImage: "alarm",
          description: Text("Create an alarm to build your sleep routine at Home Screen.")
        )
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
      } else {
        List {
          Section {
            ForEach(alarmScheduler.alarms) { alarm in
              AlarmCardView(alarm: alarm)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            }
          }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .accessibilityIdentifier("scheduledAlarmsList")
      }
    }
    .navigationTitle("Scheduled Alarms")
    .onAppear {
      AnalyticsClient.shared.track(event: .viewAlarmList)
    }
  }
}

private struct AlarmCardView: View {
  @Environment(\.calendar) private var calendar
  @Environment(\.colorScheme) private var colorScheme
  let alarm: Alarm

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 4) {
          Text(formattedTime)
            .font(.system(size: 44, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)

          if let summary = scheduleSummary {
            Text(summary)
              .font(.callout)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        Image(systemName: scheduleIconName)
          .font(.system(size: 28, weight: .semibold))
          .symbolVariant(.fill)
          .foregroundStyle(.white.opacity(0.88))
          .padding(12)
          .accessibilityHidden(true)
      }

      if let recurrenceText = recurrenceDescription {
        Label(recurrenceText, systemImage: recurrenceIconName)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      if !weekdayChips.isEmpty {
        HStack(spacing: 8) {
          ForEach(weekdayChips, id: \.self) { abbreviation in
            Text(abbreviation)
              .font(.caption.weight(.semibold))
              .textCase(.uppercase)
              .padding(.vertical, 4)
              .padding(.horizontal, 10)
              .background(
                Capsule(style: .circular)
                  .fill(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.24))
              )
              .accessibilityHidden(true)
          }
        }
        .accessibilityElement(children: .ignore)
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
    )
    .glassEffect(.regular, in: .rect(cornerRadius: 24))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabelText)
    .accessibilityAddTraits(.isButton)
  }

  private func weekdayIndex(weekday: Locale.Weekday) -> Int {
    switch weekday {
    case .sunday: return 1
    case .monday: return 2
    case .tuesday: return 3
    case .wednesday: return 4
    case .thursday: return 5
    case .friday: return 6
    case .saturday: return 7
    default: return 1
    }
  }

  private func localizedWeekdayString(weekday: Locale.Weekday) -> String {
    let index = weekdayIndex(weekday: weekday) - 1
    return calendar.weekdaySymbols[index]
  }

  private func localizedShortWeekdayString(weekday: Locale.Weekday) -> String {
    let index = weekdayIndex(weekday: weekday) - 1
    return calendar.shortWeekdaySymbols[index]
  }

  private var formattedTime: String {
    switch alarm.schedule {
    case .relative(let relative):
      let hour = relative.time.hour
      let minute = relative.time.minute
      return String(format: "%02d:%02d", hour, minute)
    case .fixed(let date):
      return date.formatted(date: .omitted, time: .shortened)
    default:
      return "--:--"
    }
  }

  private var scheduleSummary: String? {
    switch alarm.schedule {
    case .relative(let relative):
      switch relative.repeats {
      case let .weekly(weekdays):
        if weekdays.count == 7 {
          return String(localized: "Every day")
        } else if weekdays.isEmpty {
          return nil
        } else {
          return String(localized: "Repeats weekly")
        }
      case .never:
        return String(localized: "One-time reminder")
      @unknown default:
        return nil
      }
    case .fixed(let date):
      return date.formatted(date: .abbreviated, time: .omitted)
    default:
      return nil
    }
  }

  private var recurrenceDescription: String? {
    switch alarm.schedule {
    case .relative(let relative):
      switch relative.repeats {
      case let .weekly(weekdays):
        if weekdays.count == 7 {
          return String(localized: "Every day")
        } else if weekdays.isEmpty {
          return nil
        } else {
          let names = weekdays
            .sorted { weekdayIndex(weekday: $0) < weekdayIndex(weekday: $1) }
            .map { localizedWeekdayString(weekday: $0) }
          return names.formatted(.list(type: .and))
        }
      case .never:
        return String(localized: "Runs once")
      @unknown default:
        return nil
      }
    case .fixed(let date):
      return date.formatted(date: .complete, time: .shortened)
    default:
      return nil
    }
  }

  private var recurrenceIconName: String {
    switch alarm.schedule {
    case .relative(let relative):
      switch relative.repeats {
      case .weekly:
        return "repeat"
      case .never:
        return "bell"
      @unknown default:
        return "questionmark"
      }
    case .fixed:
      return "calendar"
    default:
      return "questionmark"
    }
  }

  private var scheduleIconName: String {
    switch alarm.schedule {
    case .relative(let relative):
      switch relative.repeats {
      case .weekly:
        return "alarm.waves.left.and.right"
      case .never:
        return "alarm"
      @unknown default:
        return "questionmark.circle"
      }
    case .fixed:
      return "calendar.badge.clock"
    default:
      return "questionmark.circle"
    }
  }

  private var weekdayChips: [String] {
    guard case .relative(let relative) = alarm.schedule else { return [] }
    guard case let .weekly(weekdays) = relative.repeats else { return [] }
    return weekdays
      .sorted { weekdayIndex(weekday: $0) < weekdayIndex(weekday: $1) }
      .map { localizedShortWeekdayString(weekday: $0) }
  }

  private var gradientColors: [Color] {
    switch alarm.schedule {
    case .relative(let relative):
      switch relative.repeats {
      case .weekly:
        return [Color.indigo.opacity(0.9), Color.blue.opacity(0.6)]
      case .never:
        return [Color.teal.opacity(0.7), Color.cyan.opacity(0.5)]
      @unknown default:
        return defaultGradient
      }
    case .fixed:
      return [Color.orange.opacity(0.8), Color.pink.opacity(0.6)]
    default:
      return defaultGradient
    }
  }

  private var defaultGradient: [Color] {
    [Color.gray.opacity(0.45), Color.gray.opacity(0.25)]
  }

  private var spokenTime: String {
    switch alarm.schedule {
    case .relative(let relative):
      var components = DateComponents()
      components.hour = relative.time.hour
      components.minute = relative.time.minute
      guard let date = calendar.date(from: components) else {
        return formattedTime
      }
      return date.formatted(date: .omitted, time: .shortened)
    case .fixed(let date):
      return date.formatted(date: .omitted, time: .shortened)
    default:
      return formattedTime
    }
  }

  private var accessibilityLabelText: Text {
    if let recurrence = recurrenceDescription {
      return Text("Alarm at \(spokenTime), \(recurrence)")
    }
    if let summary = scheduleSummary {
      return Text("Alarm at \(spokenTime), \(summary)")
    }
    return Text("Alarm at \(spokenTime)")
  }

}
