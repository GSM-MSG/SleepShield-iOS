//
//  SleepTimelineEditorView.swift
//  SleepShield
//
//  Created by baegteun on 9/21/25.
//

import AlarmKit
import DeviceActivity
import FamilyControls
import SwiftData
import SwiftUI
internal import ActivityKit

struct SleepTimelineEditorView: View {
  private struct AlarmEditorState: Identifiable, Equatable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var allowsSnooze: Bool
  }

  private let timeline: SleepTimeline?
  private let availableWeekday: RepeatWeekday
  private let entry: DefaultAnalyticsEvent.ViewSleepRoutineEditorEntry

  private static let durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = [.dropAll]
    return formatter
  }()

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()

  private static let durationOptions: [TimeInterval] = Array(
    stride(from: 0, through: 3 * 60 * 60, by: 15 * 60)
  )

  private static let weekdayBaseOrder: [RepeatWeekday] = [
    .sunday,
    .monday,
    .tuesday,
    .wednesday,
    .thursday,
    .friday,
    .saturday,
  ]

  private var canSave: Bool {
    repeatWeekday.isEmpty == false
  }

  private var preSleepBlockingStartDescription: LocalizedStringKey {
    let blockingStartDate = sleepTime.addingTimeInterval(-preSleepDuration)
    let timeString = Self.timeFormatter.string(from: blockingStartDate)
    return "Blocking starts at \(timeString)"
  }

  private var postWakeBlockingEndDescription: LocalizedStringKey {
    let blockingEndDate = wakeTime.addingTimeInterval(postWakeDuration)
    let timeString = Self.timeFormatter.string(from: blockingEndDate)
    return "Blocking ends at \(timeString)"
  }

  private var unavailableWeekdayMessage: String? {
    let unavailableDays = RepeatWeekday.everyday
      .subtracting(availableWeekday.union(repeatWeekday))
    guard unavailableDays.isEmpty == false else { return nil }

    let symbols = unavailableWeekdaySymbols(from: unavailableDays)
    guard symbols.isEmpty == false else { return nil }

    let joinedSymbols = symbols.joined(separator: ", ")
    return String(
      format: String(localized: "Already scheduled on %@."),
      joinedSymbols
    )
  }

  private var weekdaySymbols: [(day: RepeatWeekday, symbol: String)] {
    let baseCount = Self.weekdayBaseOrder.count
    let rawSymbols = calendar.veryShortStandaloneWeekdaySymbols
    let fallbackSymbols = ["S", "M", "T", "W", "T", "F", "S"]
    let activeSymbols = rawSymbols.count == baseCount ? rawSymbols : fallbackSymbols

    return (0..<baseCount).map { index in
      let symbolIndex = (index + calendar.firstWeekday - 1) % baseCount
      return (Self.weekdayBaseOrder[symbolIndex], activeSymbols[symbolIndex])
    }
  }

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(\.calendar) private var calendar
  @Environment(\.familyActivitySelectionStore) private var familyActivitySelectionStore
  @Environment(\.alarmScheduler) private var alarmScheduler

  @State private var sleepTime: Date
  @State private var wakeTime: Date
  @State private var preSleepDuration: TimeInterval
  @State private var postWakeDuration: TimeInterval
  @State private var repeatWeekday: RepeatWeekday
  @State private var alarms: [AlarmEditorState]
  @State private var removedAlarmIDs: Set<UUID> = []
  @State private var existingScheduledAlarmIDs: Set<UUID> = []
  @State private var showingSaveError = false
  @State private var isSaving: Bool = false
  @State private var showingDeleteConfirmation = false
  @State private var showingDeleteError = false
  @State private var isDeleting: Bool = false

  init(
    timeline: SleepTimeline? = nil,
    availableWeekday: RepeatWeekday = .everyday,
    entry: DefaultAnalyticsEvent.ViewSleepRoutineEditorEntry
  ) {
    self.timeline = timeline
    self.availableWeekday = availableWeekday
    self.entry = entry
    let calendar = Calendar.current

    if let timeline {
      let dayStart = calendar.startOfDay(for: Date())
      let sleepDate = dayStart.addingTimeInterval(max(0, timeline.sleepTimeSecondsOffset))
      let wakeDate = dayStart.addingTimeInterval(max(0, timeline.wakeTimeSecondsOffset))

      _sleepTime = State(initialValue: sleepDate)
      _wakeTime = State(initialValue: wakeDate)
      _preSleepDuration = State(initialValue: timeline.preSleepBlockDuration)
      _postWakeDuration = State(initialValue: timeline.postWakeBlockDuration)

      let allowedDays = availableWeekday.union(timeline.repeatWeekday)
      let repeatSelection = timeline.repeatWeekday.intersection(allowedDays)
      _repeatWeekday = State(initialValue: repeatSelection)
      _alarms = State(initialValue: [])
    } else {
      let defaultSleep =
        calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
      let defaultWake = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
      let oneHour: TimeInterval = 60 * 60

      _sleepTime = State(initialValue: defaultSleep)
      _wakeTime = State(initialValue: defaultWake)
      _preSleepDuration = State(initialValue: oneHour)
      _postWakeDuration = State(initialValue: oneHour)

      _repeatWeekday = State(initialValue: availableWeekday)
      _alarms = State(initialValue: [])
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          weekdaySelector

          if let unavailableMessage = unavailableWeekdayMessage {
            Text(unavailableMessage)
              .font(.footnote)
              .foregroundStyle(Color(.systemGray))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        } header: {
          sectionHeader(title: "Repeat", systemImage: "calendar")
        }

        Section {
          DatePicker(
            selection: $sleepTime,
            displayedComponents: .hourAndMinute
          ) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Sleep Time")
              Text(preSleepBlockingStartDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }

          DatePicker(
            selection: $wakeTime,
            displayedComponents: .hourAndMinute
          ) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Wake Time")
              Text(postWakeBlockingEndDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
        } header: {
          sectionHeader(title: "Sleep Routine", systemImage: "bed.double.fill")
        }

        Section {
          Picker(selection: $preSleepDuration) {
            ForEach(Self.durationOptions, id: \.self) { value in
              Text(Self.sleepDurationLabel(for: value))
                .tag(value)
            }
          } label: {
            Label("Pre-Sleep Duration", systemImage: "moon.zzz.fill")
          }
          .pickerStyle(.navigationLink)

          Picker(selection: $postWakeDuration) {
            ForEach(Self.durationOptions, id: \.self) { value in
              Text(Self.wakeUpDurationLabel(for: value))
                .tag(value)
            }
          } label: {
            Label("Post-Wake Duration", systemImage: "sunrise.fill")
          }
          .pickerStyle(.navigationLink)
        } header: {
          sectionHeader(title: "App Blocking", systemImage: "lock.iphone")
        }

        Section {
          alarmsContent
        } header: {
          sectionHeader(title: "Alarms", systemImage: "alarm.fill")
        }

        Section {
          if timeline != nil {
            Button(role: .destructive) {
              showingDeleteConfirmation = true
            } label: {
              Label("Delete", systemImage: "trash")
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .confirmationDialog(
              "Delete Sleep Routine?",
              isPresented: $showingDeleteConfirmation,
              titleVisibility: .visible
            ) {
              Button("Delete Sleep Routine", role: .destructive) {
                performDelete()
              }
              .disabled(isDeleting)

              Button("Cancel", role: .cancel) {}
            } message: {
              Text("This will remove the Routine and any associated alarms.")
            }
          }
        }

      }
      .onAppear {
        AnalyticsClient.shared.track(event: .viewSleepRoutineEditor(isEdit: timeline != nil, entry: entry))
        let scheduledAlarms = alarmScheduler.alarms(equalWeekday: repeatWeekday)
          .compactMap {
            if case .relative(let relative) = $0.schedule {
              return AlarmEditorState(
                id: $0.id,
                hour: relative.time.hour,
                minute: relative.time.minute,
                allowsSnooze: $0.countdownDuration?.postAlert != nil
              )
            } else {
              return nil
            }
          }
        self.alarms = scheduledAlarms
        self.existingScheduledAlarmIDs = Set(scheduledAlarms.map(\.id))
        self.removedAlarmIDs.removeAll()
      }
      .navigationTitle(timeline == nil ? "Add Sleep Routine" : "Edit Sleep Routine")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(role: .confirm) {
            guard isSaving == false else { return }
            Task {
              isSaving = true

              do {
                try await save()
              } catch {
                #warning("Failed to save")
              }

              isSaving = false
            }
          }
          .disabled(!canSave)
          .alert("Unable to Save", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) {}
          } message: {
            Text("Please try again.")
          }
        }
      }
      .alert("Unable to Delete", isPresented: $showingDeleteError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Please try again.")
      }
    }
  }

  @ViewBuilder
  private var weekdaySelector: some View {
    HStack(spacing: 8) {
      ForEach(Array(weekdaySymbols.enumerated()), id: \.0) { _, item in
        Button {
          toggleWeekday(item.day)
        } label: {
          Text(item.symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundColor(for: item.day))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1.0, contentMode: .fill)
            .background(circleBackground(for: item.day))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isSelectable(day: item.day))
      }
    }
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity, alignment: .center)
    .animation(.default, value: repeatWeekday)
  }

  @ViewBuilder
  private var alarmsContent: some View {
    if alarms.isEmpty {
      Text("No alarms added")
        .foregroundStyle(Color(.systemGray))
        .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      ForEach(alarms.indices, id: \.self) { index in
        alarmEditorRow(
          index: index,
          alarm: Binding(
            get: {
              guard index < alarms.count else {
                return AlarmEditorState.init(hour: 0, minute: 0, allowsSnooze: false)
              }
              return alarms[index]
            },
            set: {
              guard index < alarms.count else {
                return
              }
              alarms[index] = $0
            }
          )
        )
      }
    }

    Button {
      withAnimation {
        addAlarm()
      }
    } label: {
      Label("Add Alarm", systemImage: "plus.circle.fill")
        .frame(alignment: .leading)
    }
    .containerRelativeFrame(.horizontal) { origin, _ in
      origin
    }
  }

  @ViewBuilder
  private func alarmEditorRow(index: Int, alarm: Binding<AlarmEditorState>) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center) {
        Label {
          Text("Alarm")
        } icon: {
          Image(systemName: "alarm")
        }
        .labelIconToTitleSpacing(4)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(Color.primary)
        .accessibilityLabel("Alarm \(index + 1)")

        Spacer(minLength: 0)

        Button(role: .destructive) {
          withAnimation {
            removeAlarm(alarm.id)
          }
        } label: {
          Image(systemName: "trash")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .accessibilityLabel("Remove alarm \(index + 1)")
      }

      DatePicker(
        "Time",
        selection: alarmTimeBinding(for: alarm),
        displayedComponents: .hourAndMinute
      )

      Toggle("Snooze", isOn: alarm.allowsSnooze)
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private func sectionHeader(
    title: LocalizedStringKey,
    systemImage: String
  ) -> some View {
    Label(title, systemImage: systemImage)
      .font(.subheadline)
      .fontWeight(.semibold)
  }
}

private extension SleepTimelineEditorView {
  func save() async throws {
    if AuthorizationCenter.shared.authorizationStatus == .notDetermined {
      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      #warning("TODO: Show alert for family control status")
      return
    }

    if alarms.count > 0 {
      if AlarmManager.shared.authorizationState == .notDetermined {
        try await AlarmManager.shared.requestAuthorization()
      }

      guard AlarmManager.shared.authorizationState == .authorized else {
        #warning("TODO: Show alert for alarm status")
        return
      }
    }

    let sleepOffset = secondsOffset(from: sleepTime)
    let wakeOffset = secondsOffset(from: wakeTime)

    var isInsert: Bool
    let targetTimeline: SleepTimeline

    if let timeline {
      timeline.sleepTimeSecondsOffset = sleepOffset
      timeline.wakeTimeSecondsOffset = wakeOffset
      timeline.preSleepBlockDuration = preSleepDuration
      timeline.postWakeBlockDuration = postWakeDuration
      timeline.repeatWeekdayRawValue = repeatWeekday.rawValue
      targetTimeline = timeline
      isInsert = false
    } else {
      let newTimeline = SleepTimeline(
        sleepTimeSecondsOffset: sleepOffset,
        wakeTimeSecondsOffset: wakeOffset,
        preSleepBlockDuration: preSleepDuration,
        postWakeBlockDuration: postWakeDuration,
        repeatWeekdayRawValue: repeatWeekday.rawValue
      )
      modelContext.insert(newTimeline)
      targetTimeline = newTimeline
      isInsert = true
    }

    let alarmsDraft = alarms
    let removedIdentifiers = removedAlarmIDs

    var names: [DeviceActivityName] = []
    do {
      try modelContext.save()
      if let existingTimeline = timeline {
        try? AppBlockingScheduler.shared.stopBlocking(for: existingTimeline)
      }
      let startedNames = try AppBlockingScheduler.shared.scheduleBlocking(
        for: targetTimeline,
        selection: familyActivitySelectionStore.selection
      )
      names = startedNames
      for identifier in removedIdentifiers {
        do {
          try alarmScheduler.cancel(id: identifier)
        } catch {
          print(error)
        }
      }
      if alarmsDraft.count > 0 {
        try await scheduleAlarms(alarmDrafts: alarmsDraft)
      }
      existingScheduledAlarmIDs = Set(alarmsDraft.map(\.id))
      removedAlarmIDs.removeAll()

      let postWakeBlockMinutes = Int(postWakeDuration / 60)
      let preSleepBlockMinutes = Int(preSleepDuration / 60)
      let weekdayStrings = DefaultAnalyticsEvent.weekdayStrings(from: repeatWeekday)

      AnalyticsClient.shared.track(
        event: .saveSleepRoutine(
          isEdit: !isInsert,
          entry: entry,
          postWakeBlock: postWakeBlockMinutes,
          preSleepBlock: preSleepBlockMinutes,
          sleepTime: sleepTime,
          wakeTime: wakeTime,
          weekday: weekdayStrings
        )
      )

      UserPropertyUpdater.updateSleepTimelineProperties(modelContext: modelContext)
      UserPropertyUpdater.updateAlarmProperties(alarmScheduler: alarmScheduler)

      dismiss()
    } catch {
      if isInsert == true {
        modelContext.delete(targetTimeline)
        AppBlockingScheduler.shared.stopBlocking(names: names)
      }
      print(error)
      showingSaveError = true
    }
  }

  func performDelete() {
    guard timeline != nil else { return }
    guard isDeleting == false else { return }

    showingDeleteConfirmation = false
    isDeleting = true
    defer { isDeleting = false }

    do {
      try deleteExistingTimeline()
      AnalyticsClient.shared.track(event: .deleteSleepRoutine)

      UserPropertyUpdater.updateSleepTimelineProperties(modelContext: modelContext)
      UserPropertyUpdater.updateAlarmProperties(alarmScheduler: alarmScheduler)

      dismiss()
    } catch {
      print(error)
      showingDeleteError = true
    }
  }

  func deleteExistingTimeline() throws {
    guard let timeline else { return }

    try AppBlockingScheduler.shared.stopBlocking(for: timeline)

    for identifier in alarms.map(\.id) {
      do {
        try alarmScheduler.cancel(id: identifier)
      } catch {
        print(error)
      }
    }

    modelContext.delete(timeline)
    try modelContext.save()
  }

  private func scheduleAlarms(
    alarmDrafts: [AlarmEditorState]
  ) async throws {
    for draft in alarmDrafts {
      do {
        try alarmScheduler.cancel(id: draft.id)
      } catch {
        
      }
      let countdownDuration: AlarmKit.Alarm.CountdownDuration? = if draft.allowsSnooze {
        .init(preAlert: nil, postAlert: 60 * 9)
      } else {
        nil
      }

      let alert = AlarmPresentation.Alert(
        title: "Wake up",
        stopButton: .init(
          text: "Wake up",
          textColor: .white,
          systemImageName: "sun.horizon"
        ),
        secondaryButton: draft.allowsSnooze ? AlarmButton(
          text: "Snooze",
          textColor: .white,
          systemImageName: "repeat.circle"
        ) : nil ,
        secondaryButtonBehavior: draft.allowsSnooze ? .countdown : nil
      )

      let countdownPresentation: AlarmPresentation.Countdown? = if draft.allowsSnooze {
        AlarmPresentation.Countdown(
          title: "Wake Up Snoozed",
          pauseButton: .init(
            text: "Pause",
            textColor: .black,
            systemImageName: "pause.fill"
          )
        )
      } else {
        nil
      }

      let pausedPresentation: AlarmPresentation.Paused? = if draft.allowsSnooze {
        .init(
          title: .init(stringLiteral: "Wake up"),
          resumeButton: .init(text: "Resume", textColor: .black, systemImageName: "play.fill")
        )
      } else {
        nil
      }

      let configuration =  AlarmManager.AlarmConfiguration<SleepTimelineAlarmMetadata>(
        countdownDuration: countdownDuration,
        schedule: .relative(
          .init(
            time: .init(hour: draft.hour, minute: draft.minute),
            repeats: .init(repeatWeekDay: self.repeatWeekday)
          )
        ),
        attributes: .init(
          presentation: .init(
            alert: alert,
            countdown: countdownPresentation,
            paused: pausedPresentation
          ),
          metadata: SleepTimelineAlarmMetadata(),
          tintColor: Color.blue
        ),
        stopIntent: StopIntent(alarmID: draft.id.uuidString),
        sound: .default
      )
      
      try await alarmScheduler.schedule(
        id: draft.id,
        configuration: configuration
      )
    }
    
  }

  private func alarmTimeBinding(for alarm: Binding<AlarmEditorState>) -> Binding<Date> {
    Binding<Date>(
      get: {
        alarmDate(
          hour: alarm.wrappedValue.hour,
          minute: alarm.wrappedValue.minute
        )
      },
      set: { newDate in
        let components = alarmComponents(from: newDate)
        var updated = alarm.wrappedValue
        updated.hour = components.hour
        updated.minute = components.minute
        alarm.wrappedValue = updated
      }
    )
  }

  func addAlarm() {
    let components = calendar.dateComponents([.hour, .minute], from: wakeTime)
    let newState = AlarmEditorState(
      hour: clampedHour(components.hour ?? 7),
      minute: clampedMinute(components.minute ?? 0),
      allowsSnooze: false
    )
    alarms.append(newState)
    let alarmTime = alarmDate(hour: newState.hour, minute: newState.minute)
    AnalyticsClient.shared.track(event: .addAlarmToTimeline(alarmTime: alarmTime))
  }

  func removeAlarm(_ id: UUID) {
    let wasScheduled = existingScheduledAlarmIDs.contains(id)
    alarms.removeAll { $0.id == id }
    if wasScheduled {
      removedAlarmIDs.insert(id)
      existingScheduledAlarmIDs.remove(id)
    }
    AnalyticsClient.shared.track(event: .removeAlarmFromTimeline)
  }

  func secondsOffset(from date: Date) -> TimeInterval {
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    let hours = components.hour ?? 0
    let minutes = components.minute ?? 0
    let seconds = components.second ?? 0
    return TimeInterval(hours * 3600 + minutes * 60 + seconds)
  }

  func alarmDate(
    hour: Int,
    minute: Int
  ) -> Date {
    let sanitizedHour = clampedHour(hour)
    let sanitizedMinute = clampedMinute(minute)
    let dayStart = calendar.startOfDay(for: Date())
    return calendar.date(
      bySettingHour: sanitizedHour,
      minute: sanitizedMinute,
      second: 0,
      of: dayStart
    ) ?? dayStart
  }

  func alarmComponents(
    from date: Date
  ) -> (hour: Int, minute: Int) {
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let hour = clampedHour(components.hour ?? 0)
    let minute = clampedMinute(components.minute ?? 0)
    return (hour, minute)
  }

  func clampedHour(_ value: Int) -> Int {
    max(0, min(23, value))
  }

  func clampedMinute(_ value: Int) -> Int {
    max(0, min(59, value))
  }

  func toggleWeekday(_ day: RepeatWeekday) {
    if repeatWeekday.contains(day) {
      repeatWeekday.remove(day)
    } else if availableWeekday.contains(day) {
      repeatWeekday.insert(day)
    }
  }

  func circleBackground(for day: RepeatWeekday) -> some ShapeStyle {
    if repeatWeekday.contains(day) {
      return Color.accentColor
    }
    return isSelectable(day: day) ? Color(.systemGray5) : Color(.systemGray6)
  }

  func foregroundColor(for day: RepeatWeekday) -> some ShapeStyle {
    if repeatWeekday.contains(day) {
      return Color.white
    }
    return isSelectable(day: day) ? Color(.systemGray) : Color(.systemGray3)
  }

  func isSelectable(day: RepeatWeekday) -> Bool {
    availableWeekday.contains(day) || repeatWeekday.contains(day)
  }

  func unavailableWeekdaySymbols(from unavailableDays: RepeatWeekday) -> [String] {
    let baseCount = Self.weekdayBaseOrder.count
    let rawSymbols = calendar.shortWeekdaySymbols
    let fallbackSymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let activeSymbols = rawSymbols.count == baseCount ? rawSymbols : fallbackSymbols
    let orderedDays = (0..<baseCount).map { index -> RepeatWeekday in
      let symbolIndex = (index + calendar.firstWeekday - 1) % baseCount
      return Self.weekdayBaseOrder[symbolIndex]
    }

    return orderedDays.compactMap { day in
      guard unavailableDays.contains(day) else { return nil }
      guard let symbolIndex = Self.weekdayBaseOrder.firstIndex(of: day) else { return nil }
      return activeSymbols[symbolIndex]
    }
  }

  static func sleepDurationLabel(for value: TimeInterval) -> String {
    if value == 0 { return "At time of sleep" }
    return durationFormatter.string(from: value) ?? "At time of sleep"
  }

  static func wakeUpDurationLabel(for value: TimeInterval) -> String {
    if value == 0 { return "At time of wake up" }
    return durationFormatter.string(from: value) ?? "At time of weak up"
  }
}

#Preview {
  SleepTimelineEditorView(timeline: nil, entry: .home)
}
