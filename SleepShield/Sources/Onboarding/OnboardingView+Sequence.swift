internal import ActivityKit
import AlarmKit
import FamilyControls
import SwiftData
import SwiftUI
import UIKit

extension OnboardingView {
  @MainActor
  func playIntro() {
    stopSequence()
    introTask?.cancel()
    introTask = nil
    resetIntroState()

    introTask = Task {
      try? await Task.sleep(for: .seconds(0.35))

      await MainActor.run {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.85, blendDuration: 0.2)) {
          titleOpacity = 1
        }
      }

      try? await Task.sleep(for: .seconds(1.05))

      await MainActor.run {
        withAnimation(.spring(response: 1.4, dampingFraction: 0.88, blendDuration: 0.25)) {
          showPhone = true
        }
      }

      try? await Task.sleep(for: .seconds(1.2))

      await MainActor.run {
        startSequence()
        introTask = nil
      }
    }
  }

  func startSequence() {
    guard animationTask == nil else { return }

    animationTask = Task {
      await MainActor.run {
        stage = .paging
        currentCardIndex = 0
        displayedTime = ShortsClock.startTime
        showContinueButton = false
      }

      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          await pageThroughShorts()
        }

        group.addTask {
          await advanceClock()
        }

        await group.waitForAll()
      }

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.75)) {
          stage = .blocking
        }
      }

      try? await Task.sleep(for: .seconds(1.6))

      await MainActor.run {
        displayedTime = ShortsClock.morningPreviewTime
        withAnimation(.easeInOut(duration: 1.0)) {
          stage = .morningPreview
        }
      }

      try? await Task.sleep(for: .seconds(1.6))

      await runMorningCountdown()
    }
  }

  @MainActor
  func stopSequence() {
    animationTask?.cancel()
    animationTask = nil
    stage = .paging
    currentCardIndex = 0
    displayedTime = ShortsClock.startTime
    showContinueButton = false
  }

  func pageThroughShorts() async {
    let visiblePages = min(ShortsContent.items.count, 3)
    guard visiblePages > 0 else { return }

    let stepDuration: TimeInterval = 1.6
    let transitionDuration: TimeInterval = 0.7
    let additionalHold: TimeInterval = 1.9

    for index in 1..<visiblePages {
      try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))

      await MainActor.run {
        withAnimation(.easeInOut(duration: transitionDuration)) {
          currentCardIndex = index
        }
      }
    }

    try? await Task.sleep(for: .seconds(additionalHold))
  }

  func advanceClock() async {
    for step in 1...ShortsClock.totalSteps {
      try? await Task.sleep(for: .seconds(ShortsClock.tickInterval))

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.6)) {
          displayedTime = ShortsClock.time(for: step)
        }
      }
    }
  }

  func runMorningCountdown() async {
    for step in 1...ShortsClock.morningCountdownTotalSteps {
      try? await Task.sleep(for: .seconds(ShortsClock.morningCountdownInterval))

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.7)) {
          displayedTime = ShortsClock.morningCountdownTime(for: step)
        }
      }
    }

    await MainActor.run {
      displayedTime = ShortsClock.morningReleaseTime
      withAnimation(.spring(response: 1.35, dampingFraction: 0.85, blendDuration: 0.3)) {
        stage = .morning
      }
    }

    try? await Task.sleep(for: .seconds(0.65))

    await MainActor.run {
      withAnimation(.easeInOut(duration: 0.45)) {
        showContinueButton = true
      }
    }
  }

  func handleContinueTap() {
    switch stage {
    case .morning:
      transitionToStage(.routineSleepTime)
    case .familyAuthorization:
      if familyAuthorizationStatus == .approved {
        completeRoutineSetup()
      } else {
        handleFamilyAuthorization()
      }
    case .routineSleepTime:
      AnalyticsClient.shared.track(event: .setupOnboardingSleeptime(
        preSleepBlock: preSleepBlockingMinutes,
        sleepTime: sleepTime
      ))
      transitionToRoutineStage(.routineWakeTime)
    case .routineWakeTime:
      AnalyticsClient.shared.track(event: .setupOnboardingWaketime(
        postWakeBlock: postWakeBlockingMinutes,
        wakeTime: wakeTime
      ))
      shouldAdvanceAfterAlarmSheet = true
      isPresentingAlarmSheet = true
    case .routineSummary:
      transitionToStage(.familyAuthorization)
    default:
      break
    }
  }

  func trackStageChange(_ newStage: Stage) {
    switch newStage {
    case .blocking:
      AnalyticsClient.shared.track(event: .viewOnboardingScrollBlock)
    case .routineSleepTime:
      AnalyticsClient.shared.track(event: .viewOnboardingSleep)
    case .routineWakeTime:
      AnalyticsClient.shared.track(event: .viewOnboardingWake)
    case .routineSummary:
      AnalyticsClient.shared.track(event: .viewOnboardingSummary)
    case .familyAuthorization:
      AnalyticsClient.shared.track(event: .viewScreenTimePermission)
    default:
      break
    }
  }

  func transitionToRoutineStage(_ nextStage: Stage) {
    guard nextStage.isRoutineStage else { return }
    transitionToStage(nextStage)
  }

  func transitionToStage(_ nextStage: Stage) {
    withAnimation(.easeInOut(duration: 0.4)) {
      stage = nextStage
      if !nextStage.showsPhoneScene {
        showPhone = false
      }
    }

    if nextStage.showsPhoneScene && !showPhone {
      withAnimation(.easeInOut(duration: 0.4)) {
        showPhone = true
      }
    }
  }

  func handleFamilyAuthorization() {
    switch familyAuthorizationStatus {
    case .approved:
      break
    case .notDetermined:
      requestFamilyAuthorization()
    case .denied:
      familyAuthorizationAlertMessage = "Allow Screen Time permission in Settings so SleepShield can block your selected apps."
      showFamilyAuthorizationAlert = true
    @unknown default:
      familyAuthorizationAlertMessage = "We were unable to confirm Screen Time access. Please try again."
      showFamilyAuthorizationAlert = true
    }
  }

  func requestFamilyAuthorization() {
    guard !isRequestingFamilyAuthorization else { return }

    isRequestingFamilyAuthorization = true

    Task {
      do {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
      } catch {
        await MainActor.run {
          familyAuthorizationAlertMessage = "We could not finish the request. Please try again."
          showFamilyAuthorizationAlert = true
        }
      }

      await MainActor.run {
        isRequestingFamilyAuthorization = false

        if familyAuthorizationStatus == .approved {
          if !hasSelectedBlockedItems {
            isPresentingFamilyPicker = true
          }
        }
      }
    }
  }

  func openScreenTimeSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    openURL(url)
  }

  func completeRoutineSetup() {
    guard !isCompletingRoutine else { return }
    guard familyAuthorizationStatus == .approved else {
      handleFamilyAuthorization()
      return
    }

    isCompletingRoutine = true

    Task { await finalizeRoutineSetup() }
  }

  @MainActor
  func finalizeRoutineSetup() async {
    withAnimation(.easeInOut(duration: 0.4)) {
      showContinueButton = false
    }

    var upsertResult: (timeline: SleepTimeline, wasCreated: Bool, repeatWeekday: RepeatWeekday)?

    do {
      let result = try createOrUpdateRoutineTimeline()
      upsertResult = result

      if result.wasCreated == false {
        try? AppBlockingScheduler.shared.stopBlocking(for: result.timeline)
      } else {
        AppBlockingScheduler.shared.stopAllBlocking()
      }

      _ = try AppBlockingScheduler.shared.scheduleBlocking(
        for: result.timeline,
        selection: familyActivitySelectionStore.selection
      )

      await scheduleOnboardingAlarm(for: result.repeatWeekday)

      let alarmTime: Date? = if let draft = alarmDraft {
        calendar.date(
          bySettingHour: draft.hour,
          minute: draft.minute,
          second: 0,
          of: calendar.startOfDay(for: wakeTime)
        )
      } else {
        nil
      }

      AnalyticsClient.shared.track(event: .completeOnboarding(
        alarmTime: alarmTime,
        postWakeBlock: postWakeBlockingMinutes,
        preSleepBlock: preSleepBlockingMinutes,
        sleepTime: sleepTime,
        wakeTime: wakeTime,
        weekday: DefaultAnalyticsEvent.weekdayStrings(from: result.repeatWeekday)
      ))

      UserPropertyUpdater.updateAllProperties(
        modelContext: modelContext,
        alarmScheduler: alarmScheduler,
        familyActivitySelection: familyActivitySelectionStore.selection,
        onboardingCompleted: true
      )

      isCompletingRoutine = false
      onComplete()
    } catch {
      if let result = upsertResult, result.wasCreated {
        modelContext.delete(result.timeline)
        try? modelContext.save()
      }
      routineSetupErrorMessage = "We couldn't finish saving your routine. Please try again."
      showRoutineSetupError = true
      withAnimation(.easeInOut(duration: 0.25)) {
        showContinueButton = true
      }
      isCompletingRoutine = false
      print("Failed to complete routine setup: \(error)")
    }
  }

  @MainActor
  func resetIntroState() {
    titleOpacity = 0
    showPhone = false
    showContinueButton = false
  }

  @MainActor
  func createOrUpdateRoutineTimeline() throws -> (timeline: SleepTimeline, wasCreated: Bool, repeatWeekday: RepeatWeekday) {
    let sleepOffset = secondsOffset(for: sleepTime)
    let wakeOffset = secondsOffset(for: wakeTime)
    let preSleepDuration = TimeInterval(preSleepBlockingMinutes * 60)
    let postWakeDuration = TimeInterval(postWakeBlockingMinutes * 60)
    let selectedRepeatWeekday = repeatWeekday.isEmpty ? RepeatWeekday.everyday : repeatWeekday

    var timelines = try modelContext.fetch(FetchDescriptor<SleepTimeline>())

    if timelines.count > 1 {
      for extra in timelines.dropFirst() {
        modelContext.delete(extra)
      }
      try modelContext.save()
      timelines = try modelContext.fetch(FetchDescriptor<SleepTimeline>())
    }

    let timeline: SleepTimeline
    let wasCreated: Bool

    if let existing = timelines.first {
      timeline = existing
      wasCreated = false
    } else {
      timeline = SleepTimeline(
        sleepTimeSecondsOffset: sleepOffset,
        wakeTimeSecondsOffset: wakeOffset,
        preSleepBlockDuration: preSleepDuration,
        postWakeBlockDuration: postWakeDuration,
        repeatWeekdayRawValue: selectedRepeatWeekday.rawValue
      )
      modelContext.insert(timeline)
      wasCreated = true
    }

    timeline.sleepTimeSecondsOffset = sleepOffset
    timeline.wakeTimeSecondsOffset = wakeOffset
    timeline.preSleepBlockDuration = preSleepDuration
    timeline.postWakeBlockDuration = postWakeDuration
    timeline.repeatWeekdayRawValue = selectedRepeatWeekday.rawValue

    try modelContext.save()

    return (timeline, wasCreated, selectedRepeatWeekday)
  }

  @MainActor
  func scheduleOnboardingAlarm(for repeatWeekday: RepeatWeekday) async {
    if let cancellationID = pendingAlarmCancellationID {
      do {
        try alarmScheduler.cancel(id: cancellationID)
      } catch {
        print("Failed to cancel skipped alarm: \(error)")
      }
      pendingAlarmCancellationID = nil
    }

    guard let alarmDraft else { return }

    do {
      try alarmScheduler.cancel(id: alarmDraft.id)
    } catch {
      // If no existing alarm, ignore
    }

    let alert = AlarmPresentation.Alert(
      title: "Wake up",
      stopButton: .init(
        text: "Wake up",
        textColor: .white,
        systemImageName: "sun.max.fill"
      ),
      secondaryButton: nil,
      secondaryButtonBehavior: nil
    )

    let configuration = AlarmManager.AlarmConfiguration<SleepTimelineAlarmMetadata>(
      countdownDuration: nil,
      schedule: .relative(
        .init(
          time: .init(hour: alarmDraft.hour, minute: alarmDraft.minute),
          repeats: .init(repeatWeekDay: repeatWeekday)
        )
      ),
      attributes: .init(
        presentation: .init(
          alert: alert,
          countdown: nil,
          paused: nil
        ),
        metadata: SleepTimelineAlarmMetadata(),
        tintColor: Color.accentColor
      ),
      stopIntent: StopIntent(alarmID: alarmDraft.id.uuidString),
      sound: .default
    )

    do {
      _ = try await alarmScheduler.schedule(id: alarmDraft.id, configuration: configuration)
    } catch {
      print("Failed to schedule onboarding alarm: \(error)")
    }
  }

  func secondsOffset(for date: Date) -> TimeInterval {
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    let hours = components.hour ?? 0
    let minutes = components.minute ?? 0
    let seconds = components.second ?? 0
    return TimeInterval(hours * 3600 + minutes * 60 + seconds)
  }

  func handleAlarmSheetDismissed() {
    if shouldAdvanceAfterAlarmSheet && stage == .routineWakeTime {
      shouldAdvanceAfterAlarmSheet = false
      transitionToRoutineStage(.routineSummary)
    } else {
      shouldAdvanceAfterAlarmSheet = false
    }
  }
}
