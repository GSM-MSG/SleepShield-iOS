//
//  ContentView.swift
//  SleepShield
//
//  Created by baegteun on 9/20/25.
//

import AlarmKit
import FamilyControls
import ManagedSettings
import SwiftData
import SwiftUI

struct EventRowLabeledContentStyle: LabeledContentStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .center, spacing: 18) {
      configuration.content

      configuration.label

      Spacer()
    }
  }
}

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var isPresentAddTimeline = false
  @State private var timelineToEdit: SleepTimeline?
  @State private var isPresentFamilyPicker = false
  @State private var isPresentSleepTimelineList = false
  @State private var isPresentSettings = false
  @State private var weekday: RepeatWeekday = .sunday
  @State private var isBlockingActive = false
  @State private var showBlockingDisableError = false
  @State private var creationFeedbackTrigger = false
  @State private var deletionFeedbackTrigger = false

  @EnvironmentObject private var familyActivitySelectionStore: FamilyActivitySelectionStore
  @Environment(\.alarmScheduler) private var alarmScheduler
  @Environment(\.calendar) private var calendar

  @Query private var timelines: [SleepTimeline]
  @Namespace var id

  private var todayTimeline: SleepTimeline? {
    timelines.first(where: { $0.repeatWeekday.contains(weekday) })
  }

  private var todayAlarms: [Alarm] {
    alarmScheduler.alarms(containsWeekday: weekday)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color.backgroundPrimary
          .ignoresSafeArea()

        ScrollView(.vertical) {
          VStack(alignment: .leading, spacing: 24) {
            header()

            if let timeline = todayTimeline, isBlockingActive {
              blockingStatusBanner(for: timeline)
            }

            Group {
              if let timeline = todayTimeline {
                Button {
                  isPresentSleepTimelineList = true
                } label: {
                  TimelineCard(
                    timeline: timeline,
                    alarms: todayAlarms,
                    onEdit: {
                      presentTimelineEditor(timeline: timeline)
                    }
                  )
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
              } else {
                Button {
                  isPresentAddTimeline = true
                } label: {
                  timelineSetupPrompt()
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
              }
            }

            Button {
              AnalyticsClient.shared.track(event: .clickFamilyPicker)
              if AuthorizationCenter.shared.authorizationStatus == .notDetermined {
                Task {
                  try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                  if AuthorizationCenter.shared.authorizationStatus == .approved {
                    isPresentFamilyPicker = true
                  }
                }
              } else if AuthorizationCenter.shared.authorizationStatus == .approved {
                isPresentFamilyPicker = true
              } else {
                #warning("TODO: Show alert for authorization status")
              }
            } label: {
              AppBlockingSummaryView(selection: familyActivitySelectionStore.selection)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .glassEffect(
              .regular.interactive(),
              in: .rect(cornerRadius: 28)
            )
          }
          .padding(.horizontal, 24)
          .padding(.top, 24)
          .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isPresentSettings = true
          } label: {
            Image(systemName: "gearshape.fill")
              .font(.headline)
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(Color.textPrimary)
          }
          .accessibilityLabel(Text("Settings"))
        }
      }
    }
    .sheet(isPresented: $isPresentAddTimeline) {
      SleepTimelineEditorView(availableWeekday: availableWeekdays(), entry: .home)
    }
    .sheet(item: $timelineToEdit) { timeline in
      SleepTimelineEditorView(
        timeline: timeline,
        availableWeekday: availableWeekdays(excluding: timeline),
        entry: .home
      )
    }
    .sheet(isPresented: $isPresentSleepTimelineList) {
      NavigationStack {
        SleepTimelineListView()
      }
    }
    .sheet(isPresented: $isPresentSettings) {
      NavigationStack {
        SettingsView()
      }
    }
    .familyActivityPicker(
      headerText: String(localized: "Blocklist"),
      isPresented: $isPresentFamilyPicker,
      selection: familyActivitySelectionStore.selectionBinding
    )
    .onAppear {
      AnalyticsClient.shared.track(event: .viewHome)
      weekday = repeatWeekday(date: Date.now)
      updateBlockingStatus()

      UserPropertyUpdater.updateAllProperties(
        modelContext: modelContext,
        alarmScheduler: alarmScheduler,
        familyActivitySelection: familyActivitySelectionStore.selection,
        onboardingCompleted: true
      )
    }
    .onChange(of: familyActivitySelectionStore.selection) { _, newSelection in
      updateBlockingStatus()

      UserPropertyUpdater.updateAppBlockingProperties(familyActivitySelection: newSelection)
    }
    .onChange(of: timelines) { oldValue, newValue in
      updateBlockingStatus()
      if newValue.count > oldValue.count {
        creationFeedbackTrigger.toggle()
      } else if newValue.count < oldValue.count {
        deletionFeedbackTrigger.toggle()
      }
    }
    .onChange(of: weekday) { _, _ in
      updateBlockingStatus()
    }
    .task {
      weekday = repeatWeekday(date: Date.now)
      updateBlockingStatus()
      for await _ in NotificationCenter.default.notifications(named: UIApplication.significantTimeChangeNotification) {
        weekday = repeatWeekday(date: Date.now)
        updateBlockingStatus()
      }
    }
    .alert("Unable to Turn Off Blocking", isPresented: $showBlockingDisableError) {
      Button("OK", role: .cancel) {}
    }
    .sensoryFeedback(.success, trigger: creationFeedbackTrigger)
    .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: deletionFeedbackTrigger)
  }

  @ViewBuilder
  private func header() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("SleepShield")
        .font(.footnote)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundStyle(Color.textPrimary.secondary)
        .textCase(.uppercase)
        .kerning(1.2)

      VStack(alignment: .leading, spacing: 2) {
        Text("Tonight's Schedule")
          .font(.title)
          .fontWeight(.bold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)

        Text("Pre-sleep restrictions and alarm overview")
          .font(.subheadline)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary.secondary)
      }
    }
  }
}

extension HomeView {
  @ViewBuilder
  fileprivate func blockingStatusBanner(for timeline: SleepTimeline) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Blocking Active")
          .font(.headline)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)

        Text("App blocking is currently applied based on your sleep schedule.")
          .font(.subheadline)
          .fontWeight(.medium)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary.secondary)
      }

      Button {
        disableBlocking(for: timeline)
      } label: {
        Text("Turn Off Blocking today")
          .font(.body)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(24)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
  }

  @ViewBuilder
  fileprivate func timelineSetupPrompt() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Set Up Sleep Routine")
        .font(.headline)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundStyle(Color.textPrimary)

      Text("Add your sleep and wake times so SleepShield can build tonight's timeline.")
        .font(.subheadline)
        .fontWeight(.medium)
        .fontDesign(.rounded)
        .foregroundStyle(Color.textPrimary.secondary)
        .multilineTextAlignment(.leading)

      if otherScheduledDaysCount > 0 {
        Button(action: presentTimelineList) {
          HStack(spacing: 4) {
            Image(systemName: "calendar")

            Text(otherScheduledDaysCaption)
          }
          .font(.caption)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
      }

      Button(action: presentTimelineAdd) {
        Text("Add Sleep Routine")
          .font(.body)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.glassProminent)
      .tint(Color.blue)
      .controlSize(.large)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color.white.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    )
  }

  fileprivate func presentTimelineAdd() {
    isPresentAddTimeline = true
  }

  fileprivate func presentTimelineList() {
    isPresentSleepTimelineList = true
  }

  fileprivate func presentTimelineEditor(timeline: SleepTimeline) {
    timelineToEdit = timeline
  }

  private func availableWeekdays(excluding timeline: SleepTimeline? = nil) -> RepeatWeekday {
    let usedByOthers = timelines.reduce(into: RepeatWeekday()) { partial, candidate in
      if let timeline, candidate === timeline { return }
      partial.formUnion(candidate.repeatWeekday)
    }

    return RepeatWeekday.everyday.subtracting(usedByOthers)
  }

  private func repeatWeekday(date: Date) -> RepeatWeekday {
    let weekdayIndex = Calendar.current.component(.weekday, from: date)
    switch weekdayIndex {
    case 1: return .sunday
    case 2: return .monday
    case 3: return .tuesday
    case 4: return .wednesday
    case 5: return .thursday
    case 6: return .friday
    case 7: return .saturday
    default: return .sunday
    }
  }

  private func updateBlockingStatus(reference date: Date = Date()) {
    isBlockingActive = AppBlockingScheduler.shared.blockingIsActivated
  }

  private func disableBlocking(for timeline: SleepTimeline) {
    AnalyticsClient.shared.track(event: .clickDisableBlocking)
    AppBlockingScheduler.shared.pauseBlocking()
    updateBlockingStatus()
  }

  private var otherScheduledDaysCount: Int {
    let scheduledDays = timelines.reduce(into: RepeatWeekday()) { partial, timeline in
      partial.formUnion(timeline.repeatWeekday)
    }

    let otherDays = scheduledDays.subtracting(weekday)
    return RepeatWeekday.allOptions.filter { otherDays.contains($0) }.count
  }

  private var otherScheduledDaysCaption: String {
    return String(localized: .otherDayAlreadyScheduled(Int32(otherScheduledDaysCount)))
  }
}

#Preview {
  let schema = Schema([SleepTimeline.self])
  let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: schema, configurations: [configuration])
  let context = ModelContext(container)
  let existingTimelines = (try? context.fetch(FetchDescriptor<SleepTimeline>())) ?? []

  if existingTimelines.isEmpty {
    let timeline = SleepTimeline(
      sleepTimeSecondsOffset: 23 * 60 * 60,
      wakeTimeSecondsOffset: 7 * 60 * 60,
      preSleepBlockDuration: 60 * 60,
      postWakeBlockDuration: 60 * 60,
      repeatWeekdayRawValue: 0
    )
//    context.insert(timeline)
//    try? context.save()
  }

  return HomeView()
    .modelContainer(container)
    .environmentObject(FamilyActivitySelectionStore())
}
