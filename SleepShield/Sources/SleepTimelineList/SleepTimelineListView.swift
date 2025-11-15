import SwiftData
import SwiftUI

struct SleepTimelineListView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.calendar) private var calendar

  @Query(sort: \SleepTimeline.sleepTimeSecondsOffset)
  private var timelines: [SleepTimeline]

  @State private var timelineToEdit: SleepTimeline?
  @State private var isPresentingAddTimeline = false

  private var remainingWeekdayDescription: String? {
    let weekdays = availableWeekdays()
    guard weekdays.isEmpty == false else { return nil }
    let weekdaySymbols = calendar.weekdaySymbols
    let selected = RepeatWeekday.allOptions.enumerated().compactMap { (index, option) -> String? in
      guard weekdays.contains(option) else { return nil }
      return weekdaySymbols.indices.contains(index) ? weekdaySymbols[index] : nil
    }
    guard selected.isEmpty == false else { return nil }
    return ListFormatter.localizedString(byJoining: selected)
  }

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      if timelines.isEmpty {
        emptyState()
      } else {
        ScrollView {
          LazyVStack(spacing: 16) {
            if canAddTimeline {
              Button {
                isPresentingAddTimeline = true
              } label: {
                AddSleepTimelineCard(
                  description: remainingWeekdayDescription
                )
                  .accessibilityLabel(
                    Text(
                      remainingWeekdayDescription.map {
                        "Add sleep routine for \($0)"
                      } ?? "Add sleep routine"
                    )
                  )
              }
              .glassEffect(
                .regular.interactive(),
                in: .rect(cornerRadius: 24)
              )
            }

            ForEach(timelines) { timeline in
              Button {
                timelineToEdit = timeline
              } label: {
                SleepTimelineCard(timeline: timeline)
                  .glassEffect(
                    .regular.interactive(),
                    in: .rect(cornerRadius: 24)
                  )
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 28)
        }
        .scrollIndicators(.hidden)
      }
    }
    .navigationTitle("Sleep Routines")
    .onAppear {
      AnalyticsClient.shared.track(event: .viewSleepRoutineList)
    }
    .sheet(isPresented: $isPresentingAddTimeline) {
      SleepTimelineEditorView(availableWeekday: availableWeekdays(), entry: .list)
    }
    .sheet(item: $timelineToEdit) {
      SleepTimelineEditorView(
        timeline: $0,
        availableWeekday: availableWeekdays(excluding: $0),
        entry: .list
      )
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(role: .cancel) {
          dismiss()
        }
      }
    }
  }

  @ViewBuilder
  private func emptyState() -> some View {
    VStack(spacing: 12) {
      Image(systemName: "bed.double.fill")
        .font(.largeTitle)
        .foregroundStyle(Color.textPrimary.secondary)
        .accessibilityHidden(true)

      Text("No sleep routines yet")
        .font(.headline)
        .fontDesign(.rounded)
        .foregroundStyle(Color.textPrimary)

      Text("Create a routine to see it appear here.")
        .font(.subheadline)
        .fontWeight(.medium)
        .fontDesign(.rounded)
        .foregroundStyle(Color.textPrimary.secondary)

      if canAddTimeline {
        Button {
          isPresentingAddTimeline = true
        } label: {
          Text("Add Sleep Routine")
            .font(.headline)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentColor)
        .padding(.top, 8)
      }
    }
    .multilineTextAlignment(.center)
    .padding(32)
  }

  private var canAddTimeline: Bool {
    availableWeekdays().isEmpty == false
  }

  private func availableWeekdays(excluding timeline: SleepTimeline? = nil) -> RepeatWeekday {
    let usedByOthers = timelines.reduce(into: RepeatWeekday()) { result, candidate in
      if let timeline, candidate === timeline { return }
      result.formUnion(candidate.repeatWeekday)
    }
    return RepeatWeekday.everyday.subtracting(usedByOthers)
  }

  private func availableWeekdays() -> RepeatWeekday {
    availableWeekdays(excluding: nil)
  }
}

private struct SleepTimelineCard: View {
  @Environment(\.calendar) private var calendar

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()

  private static let durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.hour, .minute]
    formatter.maximumUnitCount = 2
    return formatter
  }()

  private static let spokenDurationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.hour, .minute]
    formatter.maximumUnitCount = 2
    return formatter
  }()

  private let timeline: SleepTimeline

  private var referenceDayStart: Date { calendar.startOfDay(for: Date()) }
  private var sleepDate: Date { referenceDayStart.addingTimeInterval(timeline.sleepTimeSecondsOffset) }
  private var wakeDate: Date { referenceDayStart.addingTimeInterval(timeline.wakeTimeSecondsOffset) }
  private var preSleepStartDate: Date { referenceDayStart.addingTimeInterval(timeline.preSleepBlockingStartOffset) }
  private var postWakeEndDate: Date { referenceDayStart.addingTimeInterval(timeline.postWakeBlockingEndOffset) }

  private var sleepDuration: TimeInterval {
    normalizedDuration(
      from: timeline.sleepTimeSecondsOffset,
      to: timeline.wakeTimeSecondsOffset
    )
  }

  private var sleepDurationText: String {
    formattedDuration(sleepDuration) ?? "—"
  }

  private var sleepDurationVoiceText: String {
    spokenDurationText(for: sleepDuration) ?? sleepDurationText
  }

  private var activeWeekdaysDescription: String {
    let weekdaySymbols = calendar.weekdaySymbols
    let selected = RepeatWeekday.allOptions.enumerated().compactMap { (index, option) -> String? in
      guard timeline.repeatWeekday.contains(option) else { return nil }
      return weekdaySymbols.indices.contains(index) ? weekdaySymbols[index] : nil
    }
    return ListFormatter.localizedString(byJoining: selected)
  }

  init(timeline: SleepTimeline) {
    self.timeline = timeline
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      topRow()
      weekdayGrid()
      summaryRow()
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 18)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(cardAccessibilityLabel))
  }

  @ViewBuilder
  private func topRow() -> some View {
    HStack(alignment: .center, spacing: 16) {
      timelineIcon()

      VStack(alignment: .leading, spacing: 6) {
        Text("Sleep Routine")
          .font(.footnote)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary.secondary)

        Text("\(formattedTime(for: sleepDate)) – \(formattedTime(for: wakeDate))")
          .font(.title3)
          .fontWeight(.bold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)
          .accessibilityLabel(Text("Sleep routine from \(formattedTime(for: sleepDate)) to \(formattedTime(for: wakeDate))"))

        HStack(alignment: .center, spacing: 8) {
          Text("Total")
            .font(.caption)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(Color.textPrimary.secondary)

          Text(sleepDurationText)
            .font(.subheadline)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(Color.textPrimary)
            .accessibilityLabel(Text("Total duration \(sleepDurationVoiceText)"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  @ViewBuilder
  private func weekdayGrid() -> some View {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let options = RepeatWeekday.allOptions
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(Array(options.enumerated()), id: \.1.rawValue) { index, option in
        let symbol = symbols.indices.contains(index) ? symbols[index] : ""
        WeekdayBadge(
          text: symbol,
          isActive: timeline.repeatWeekday.contains(option)
        )
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(weekdayAccessibilityLabel))
  }

  @ViewBuilder
  private func summaryRow() -> some View {
    VStack(spacing: 12) {
      ForEach(summaryChips) { chip in
        blockChip(chip)
      }
    }
  }

  private var summaryChips: [BlockChipInfo] {
    [
      blockDetail(
        title: "Pre-block",
        systemName: "moon.zzz.fill",
        duration: timeline.preSleepBlockDuration,
        eventDate: preSleepStartDate,
        eventMoment: .starts
      ),
      blockDetail(
        title: "Post-block",
        systemName: "sunrise.fill",
        duration: timeline.postWakeBlockDuration,
        eventDate: postWakeEndDate,
        eventMoment: .ends
      ),
    ]
  }

  @ViewBuilder
  private func blockChip(_ chip: BlockChipInfo) -> some View {
    HStack(alignment: .center, spacing: 10) {
      Circle()
        .fill(Color.white.opacity(0.08))
        .frame(width: 28, height: 28)
        .overlay {
          Image(systemName: chip.systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.textPrimary)
        }
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(chip.title)
          .font(.caption)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary.secondary)

        blockDetailText(for: chip)
          .font(.footnote)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color.white.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: chip.accessibilityLabel))
  }

  @ViewBuilder
  private func blockDetailText(for chip: BlockChipInfo) -> some View {
    let eventString = String(localized: chip.eventDetail)
    if let duration = chip.durationText, duration.isEmpty == false {
      Text("\(duration) • \(chip.eventDetail)")
    } else if eventString.isEmpty {
      Text("—")
    } else {
      Text(chip.eventDetail)
    }
  }

  private func blockDetail(
    title: LocalizedStringResource,
    systemName: String,
    duration: TimeInterval,
    eventDate: Date,
    eventMoment: BlockEventMoment
  ) -> BlockChipInfo {
    let durationText = formattedDuration(duration)
    let voiceDuration = spokenDurationText(for: duration)
    let timeText = formattedTime(for: eventDate)

    let eventDetail = eventMoment.displayDetail(timeText: timeText)
    let titleString = String(localized: title)

    var accessibilityComponents: [String] = []
    if let voiceDuration, voiceDuration.isEmpty == false {
      accessibilityComponents.append("\(titleString) lasts \(voiceDuration)")
    } else if let durationText {
      accessibilityComponents.append("\(titleString) lasts \(durationText)")
    }
    accessibilityComponents.append(
      String(localized: eventMoment.accessibilityDetail(timeText: timeText))
    )

    return BlockChipInfo(
      id: systemName,
      title: title,
      systemName: systemName,
      durationText: durationText,
      eventDetail: eventDetail,
      accessibilityLabel: accessibilityComponents.joined(separator: ", ")
    )
  }

  private var weekdayAccessibilityLabel: String {
    guard activeWeekdaysDescription.isEmpty == false else {
      return "No active weekdays"
    }
    return "Active on \(activeWeekdaysDescription)"
  }

  private var cardAccessibilityLabel: String {
    var parts: [String] = []
    parts.append("Sleep routine from \(formattedTime(for: sleepDate)) to \(formattedTime(for: wakeDate))")
    parts.append("total duration \(sleepDurationVoiceText)")
    if activeWeekdaysDescription.isEmpty == false {
      parts.append("active on \(activeWeekdaysDescription)")
    }
    parts.append(contentsOf: summaryChips.map(\.accessibilityLabel))
    return parts.joined(separator: ", ")
  }

  private func normalizedDuration(from start: TimeInterval, to end: TimeInterval) -> TimeInterval {
    let nextDayStart = calendar.date(byAdding: .day, value: 1, to: referenceDayStart) ?? referenceDayStart.addingTimeInterval(24 * 60 * 60)
    let dayLength = nextDayStart.timeIntervalSince(referenceDayStart)
    let difference = end - start
    if difference >= 0 { return difference }
    return difference + dayLength
  }

  private func formattedTime(for date: Date) -> String {
    Self.timeFormatter.string(from: date)
  }

  private func formattedDuration(_ duration: TimeInterval) -> String? {
    Self.durationFormatter.string(from: duration)
  }

  private func spokenDurationText(for duration: TimeInterval) -> String? {
    Self.spokenDurationFormatter.string(from: duration)
  }

  @ViewBuilder
  private func timelineIcon() -> some View {
    Circle()
      .fill(
        LinearGradient(
          colors: [Color.blue.opacity(0.75), Color.indigo],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: 40, height: 40)
      .overlay {
        Image(systemName: "bed.double.fill")
          .symbolVariant(.fill)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color.white)
      }
      .accessibilityHidden(true)
  }
}

private struct WeekdayBadge: View {
  let text: String
  let isActive: Bool

  var body: some View {
    Text(text.uppercased())
      .font(.caption2)
      .underline(isActive, color: Color.primary)
      .fontWeight(isActive ? .semibold : .regular)
      .fontDesign(.rounded)
      .foregroundStyle(isActive ? Color.primary : Color.secondary)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .accessibilityHidden(true)
  }
}

private enum BlockEventMoment {
  case starts
  case ends

  func displayDetail(timeText: String) -> LocalizedStringResource {
    switch self {
    case .starts:
      "Starts at \(timeText)"
    case .ends:
      "Ends at \(timeText)"
    }
  }

  func accessibilityDetail(timeText: String) -> LocalizedStringResource {
    switch self {
    case .starts:
      "Starts at \(timeText)"
    case .ends:
      "Ends at \(timeText)"
    }
  }
}

private struct BlockChipInfo: Identifiable {
  let id: String
  let title: LocalizedStringResource
  let systemName: String
  let durationText: String?
  let eventDetail: LocalizedStringResource
  let accessibilityLabel: String
}

private struct AddSleepTimelineCard: View {
  let description: String?

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.accentColor.opacity(0.85), Color.indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 40, height: 40)
        .overlay {
          Image(systemName: "plus")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.white)
        }
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 6) {
        Text("Add Sleep Routine")
          .font(.title3)
          .fontWeight(.bold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)

        Text(description ?? "Assign a routine to remaining days.")
          .font(.subheadline)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary.secondary)
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 18)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  let schema = Schema([SleepTimeline.self])
  let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: schema, configurations: [configuration])
  let context = ModelContext(container)

//  if (try? context.fetch(FetchDescriptor<SleepTimeline>()))?.isEmpty ?? true {
    let weekdayTimeline = SleepTimeline(
      sleepTimeSecondsOffset: 22 * 60 * 60,
      wakeTimeSecondsOffset: 6 * 60 * 60,
      preSleepBlockDuration: 90 * 60,
      postWakeBlockDuration: 45 * 60,
      repeatWeekdayRawValue: RepeatWeekday.weekdays.rawValue
    )

    let weekendTimeline = SleepTimeline(
      sleepTimeSecondsOffset: 24 * 60 * 60,
      wakeTimeSecondsOffset: 8 * 60 * 60,
      preSleepBlockDuration: 60 * 60,
      postWakeBlockDuration: 60 * 60,
      repeatWeekdayRawValue: (RepeatWeekday.saturday.union(.sunday)).rawValue
    )

  try? context.transaction {
    context.insert(weekdayTimeline)
    context.insert(weekendTimeline)
    try? context.save()
  }
//  }

  return NavigationStack {
    SleepTimelineListView()
      .modelContainer(container)
  }
}
