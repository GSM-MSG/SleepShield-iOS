import AlarmKit
import SwiftUI

extension HomeView {
  struct TimelineCard: View {
    private enum Event: Identifiable {
      case preSleep
      case alarm(UUID?)
      case postWake

      var id: String {
        switch self {
        case .preSleep:
          return "preSleep"
        case .alarm(let identifier):
          if let identifier {
            return "alarm-\(identifier.uuidString)"
          }
          return "alarm-placeholder"
        case .postWake:
          return "postWake"
        }
      }
    }

    private struct TimelineEventConfiguration: Identifiable {
      let event: Event
      let title: LocalizedStringKey
      let systemName: String
      let gradientColors: [Color]
      let timeText: String

      var id: String { event.id }
    }

    @Environment(\.calendar) private var calendar

    private static let containerIconID = "icon"
    private static let timeFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .short
      return formatter
    }()
    private var referenceDayStart: Date { calendar.startOfDay(for: Date()) }
    private var sleepDate: Date { referenceDayStart.addingTimeInterval(timeline.sleepTimeSecondsOffset) }
    private var timelineWakeDate: Date { referenceDayStart.addingTimeInterval(timeline.wakeTimeSecondsOffset) }
    private var alarmDates: [(alarm: Alarm, date: Date)] {
      alarms.compactMap { alarm in
        guard let date = alarmDate(for: alarm) else { return nil }
        return (alarm, date)
      }
      .sorted(by: { $0.date < $1.date })
    }
    private var wakeDate: Date { alarmDates.last?.date ?? timelineWakeDate }
    private var preSleepStartDate: Date { sleepDate.addingTimeInterval(-timeline.preSleepBlockDuration) }
    private var postWakeEndDate: Date { wakeDate.addingTimeInterval(timeline.postWakeBlockDuration) }
    private var multipleAlarms: Bool { alarmDates.count > 1 }

    private let iconSize: CGFloat = 52
    private let timeline: SleepTimeline
    private let alarms: [Alarm]
    private let onEdit: () -> Void

    @Namespace private var iconContainer

    init(
      timeline: SleepTimeline,
      alarms: [Alarm] = [],
      onEdit: @escaping () -> Void
    ) {
      self.timeline = timeline
      self.alarms = alarms
      self.onEdit = onEdit
    }

    var body: some View {
      ZStack(alignment: .leading) {
        GlassEffectContainer {
          VStack(alignment: .leading, spacing: 24) {
            HStack {
              Text("Timeline")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

              Spacer()

              Button(action: onEdit) {
                Image(systemName: "slider.horizontal.3")
                  .font(.headline)
                  .foregroundStyle(Color.textPrimary)
              }
              .buttonStyle(.plain)
            }
            .fontWeight(.semibold)
            .fontDesign(.rounded)

            sleepWindowSummary(
              sleepTime: formattedTime(for: sleepDate),
              wakeTime: formattedTime(for: wakeDate)
            )

            Divider()
              .overlay(Color.textPrimary.quaternary)

            ForEach(timelineEvents) { event in
              LabeledContent {
                timelineIcon(
                  colors: event.gradientColors,
                  systemName: event.systemName
                )
                .padding(8)
                .glassEffect(.regular.tint(.backgroundPrimary))
                .glassEffectUnion(id: Self.containerIconID, namespace: iconContainer)
              } label: {
                timelineLabel(title: event.title, time: event.timeText)
              }
              .labeledContentStyle(EventRowLabeledContentStyle())
            }
          }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
      }
    }

    private var timelineEvents: [TimelineEventConfiguration] {
      var events: [TimelineEventConfiguration] = [
        TimelineEventConfiguration(
          event: .preSleep,
          title: "Pre-Sleep Blocking",
          systemName: "moon.zzz.fill",
          gradientColors: [Color.blue.opacity(0.75), Color.indigo],
          timeText: formattedTime(for: preSleepStartDate)
        )
      ]

      let alarms = alarmEvents()
      if alarms.isEmpty == false {
        events.append(contentsOf: alarms)
      }

      events.append(
        TimelineEventConfiguration(
          event: .postWake,
          title: "Post-Wake Blocking",
          systemName: "sunrise.fill",
          gradientColors: [Color.yellow, Color.orange.opacity(0.8)],
          timeText: formattedTime(for: postWakeEndDate)
        )
      )

      return events
    }

    private func formattedTime(for date: Date) -> String {
      Self.timeFormatter.string(from: date)
    }

    private func alarmEvents() -> [TimelineEventConfiguration] {
      return alarmDates.enumerated().map { index, entry in
        let title: LocalizedStringKey = multipleAlarms ? LocalizedStringKey("Alarm \(index + 1)") : "Alarm"
        return TimelineEventConfiguration(
          event: .alarm(entry.alarm.id),
          title: title,
          systemName: "alarm.fill",
          gradientColors: [Color.blue, Color.purple],
          timeText: formattedTime(for: entry.date)
        )
      }
    }

    private func alarmDate(for alarm: Alarm) -> Date? {
      guard let schedule = alarm.schedule else { return nil }
      switch schedule {
      case .fixed(let date):
        return date
      case .relative(let relative):
        return calendar.date(
          bySettingHour: relative.time.hour,
          minute: relative.time.minute,
          second: 0,
          of: referenceDayStart
        ) ?? referenceDayStart.addingTimeInterval(
          TimeInterval(relative.time.hour * 3600 + relative.time.minute * 60)
        )
      @unknown default:
        return nil
      }
    }

    @ViewBuilder
    private func sleepWindowSummary(
      sleepTime: String,
      wakeTime: String
    ) -> some View {
      HStack(spacing: 32) {
        timelineSummaryColumn(
          title: "Sleep Time",
          value: sleepTime,
          systemName: "moon.zzz.fill"
        )

        Spacer(minLength: 0)

        timelineSummaryColumn(
          title: "Wake Time",
          value: wakeTime,
          systemName: "sunrise.fill"
        )
      }
      .padding(.vertical, 4)
    }

    @ViewBuilder
    private func timelineSummaryColumn(
      title: LocalizedStringKey,
      value: String,
      systemName: String
    ) -> some View {
      VStack(alignment: .leading, spacing: 4) {
        Label {
          Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(Color.textPrimary.secondary)
        } icon: {
          Image(systemName: systemName)
            .font(.footnote)
            .foregroundStyle(Color.textPrimary.secondary)
        }

        Text(value)
          .font(.title3)
          .fontWeight(.bold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)
      }
    }

    @ViewBuilder
    private func timelineIcon(
      colors: [Color],
      systemName: String
    ) -> some View {
      Circle()
        .fill(
          LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: iconSize, height: iconSize)
        .overlay {
          Image(systemName: systemName)
            .symbolVariant(.fill)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.white)
        }
    }

    @ViewBuilder
    private func timelineLabel(
      title: LocalizedStringKey,
      time: String
    ) -> some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.body)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)

        Text(time)
          .font(.footnote)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary.secondary)
      }
    }
  }
}
