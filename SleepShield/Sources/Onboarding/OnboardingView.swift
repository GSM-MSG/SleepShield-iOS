import SwiftUI
import FamilyControls
import SwiftData
import UIKit

struct OnboardingView: View {
  @Environment(\.modelContext) var modelContext
  @Environment(\.calendar) var calendar
  @Environment(\.familyActivitySelectionStore) var familyActivitySelectionStore
  @Environment(\.openURL) var openURL
  @Environment(\.alarmScheduler) var alarmScheduler
  @State var stage: Stage = .paging
  @State var currentCardIndex: Int = 0
  @State var animationTask: Task<Void, Never>?
  @State var displayedTime: Date = ShortsClock.startTime
  @State var introTask: Task<Void, Never>?
  @State var titleOpacity: Double = 0
  @State var showContinueButton: Bool = false
  @State var sleepTime: Date = Self.defaultSleepTime
  @State var wakeTime: Date = Self.defaultWakeTime
  @State var preSleepBlockingMinutes: Int = 60
  @State var postWakeBlockingMinutes: Int = 30
  @State var repeatWeekday: RepeatWeekday = .everyday
  @State var alarmDraft: AlarmDraft?
  @State var pendingAlarmCancellationID: UUID?
  @State var didSkipAlarmSelection: Bool = false
  @State var isPresentingAlarmSheet: Bool = false
  @State var shouldAdvanceAfterAlarmSheet: Bool = false
  @StateObject private var authorizationCenter = AuthorizationCenter.shared
  var familyAuthorizationStatus: AuthorizationStatus {
    authorizationCenter.authorizationStatus
  }
  @State var isRequestingFamilyAuthorization: Bool = false
  @State var showFamilyAuthorizationAlert: Bool = false
  @State var familyAuthorizationAlertMessage: String = ""
  @State var isPresentingFamilyPicker: Bool = false
  @State var isCompletingRoutine: Bool = false
  @State var routineSetupErrorMessage: LocalizedStringKey = ""
  @State var showRoutineSetupError: Bool = false
  @State var selectionChangeToken: Int = 0
  @Namespace private var ctaContainer

  @State var showPhone: Bool = false
  private static let defaultSleepTime: Date = Calendar.autoupdatingCurrent.date(from: DateComponents(hour: 23, minute: 0)) ?? .now
  private static let defaultWakeTime: Date = Calendar.autoupdatingCurrent.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
  static let durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
    formatter.collapsesLargestUnit = false
    return formatter
  }()
  static let minuteMeasurementFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .providedUnit
    formatter.unitStyle = .short
    return formatter
  }()

  struct AlarmDraft: Identifiable, Equatable {
    let id: UUID
    var hour: Int
    var minute: Int

    init(id: UUID = UUID(), hour: Int, minute: Int) {
      self.id = id
      self.hour = hour
      self.minute = minute
    }
  }

  let onComplete: () -> Void

  init(onComplete: @escaping () -> Void) {
    self.onComplete = onComplete
  }

  var body: some View {
    ZStack {
      background
        .ignoresSafeArea()

      Group {
        switch stage {
        case .routineSleepTime, .routineWakeTime, .routineSummary:
          RoutineSetupStage(
            stage: stage,
            title: titleText,
            sleepTime: $sleepTime,
            wakeTime: $wakeTime,
            preSleepBlockingMinutes: $preSleepBlockingMinutes,
            postWakeBlockingMinutes: $postWakeBlockingMinutes,
            repeatWeekday: $repeatWeekday,
            alarmDraft: $alarmDraft,
            isPresentingAlarmSheet: $isPresentingAlarmSheet,
            didSkipAlarmSelection: $didSkipAlarmSelection,
            shouldAdvanceAfterAlarmSheet: $shouldAdvanceAfterAlarmSheet
          )
          .transition(.move(edge: .trailing).combined(with: .opacity))
        default:
          VStack(spacing: 28) {
            if stage.showsPhoneScene, showPhone == false {
              Spacer()
            }

            VStack(spacing: 10) {
              let foregroundColor: Color = if stage == .morning || stage == .familyAuthorization {
                .black
              } else {
                .white
              }

              Text(titleText)
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(foregroundColor)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.3)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .containerRelativeFrame(.vertical) { length, _ in
              length * 0.1
            }
            .padding(.top, 24)

            if stage == .familyAuthorization {
              FamilyControlsStageView(
                status: familyAuthorizationStatus,
                isRequesting: isRequestingFamilyAuthorization,
                selection: familyActivitySelectionStore.selection,
                selectionChangeToken: selectionChangeToken,
                onRequestPermission: { handleFamilyAuthorization() },
                onOpenSettings: { openScreenTimeSettings() },
                onEditSelection: { isPresentingFamilyPicker = true }
              )
              .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if showPhone && stage.showsPhoneScene {
              PhoneScene(
                stage: stage,
                currentIndex: currentCardIndex,
                items: ShortsContent.items,
                displayedTime: displayedTime
              )
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 12)
              .padding(.bottom, 16)
              .transition(
                .asymmetric(
                  insertion: .scale(scale: 0.92, anchor: .bottom)
                    .combined(with: .move(edge: .bottom)),
                  removal: .opacity
                )
              )
            }

            Spacer(minLength: 0)
          }
          .padding(.horizontal, 28)
          .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.45), value: stage)
    }
    .overlay(alignment: .bottom) {
      if showContinueButton {
        GlassEffectContainer {
          HStack {
            if let previousStage = stage.previousStage {
              Button {
                transitionToStage(previousStage)
              } label: {
                Image(systemName: "chevron.backward")
                  .foregroundStyle(Color.black)
                  .frame(width: 16, height: 16)
                  .padding()
              }
              .aspectRatio(1.0, contentMode: .fit)
              .glassEffect(.clear.interactive())
              .glassEffectID("backward", in: ctaContainer)
            }

            Button {
              handleContinueTap()
            } label: {
              Text(ctaButtonTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.black)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())
            }
            .disabled(isContinueButtonDisabled)
            .opacity(isContinueButtonDisabled ? 0.6 : 1)
            .glassEffect(.clear.interactive())
            .glassEffectID("continue", in: ctaContainer)
          }
          .padding(.horizontal, 24)
          .transition(
            .asymmetric(
              insertion: .opacity.combined(with: .move(edge: .bottom)),
              removal: .opacity
            )
          )
        }
      }
    }
    .familyActivityPicker(
      headerText: String(localized: "Blocklist"),
      isPresented: $isPresentingFamilyPicker,
      selection: Binding(
        get: { familyActivitySelectionStore.selection },
        set: { newValue in
          familyActivitySelectionStore.updateSelection(newValue)
        }
      )
    )
    .alert("Screen Time Access Required", isPresented: $showFamilyAuthorizationAlert) {
      Button("OK", role: .cancel) {}
      if familyAuthorizationStatus == .denied {
        Button("Open Settings") {
          openScreenTimeSettings()
        }
      }
    } message: {
      Text(familyAuthorizationAlertMessage)
    }
    .alert("Couldn't Complete Setup", isPresented: $showRoutineSetupError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(routineSetupErrorMessage)
    }
    .sheet(isPresented: $isPresentingAlarmSheet, onDismiss: { handleAlarmSheetDismissed() }) {
      AlarmSetupSheet(
        wakeTime: wakeTime,
        alarmDraft: $alarmDraft,
        isPresented: $isPresentingAlarmSheet,
        pendingCancellationID: $pendingAlarmCancellationID,
        didSkipAlarm: $didSkipAlarmSelection
      )
      .presentationDetents([.medium])
    }
    .onAppear {
      AnalyticsClient.shared.track(event: .viewOnboarding)
      playIntro()
    }
    .onChange(of: stage) { _, newStage in
      trackStageChange(newStage)
    }
    .onChange(of: familyActivitySelectionStore.selection) { _, _ in
      selectionChangeToken &+= 1
    }
    .onDisappear {
      introTask?.cancel()
      introTask = nil
      stopSequence()
    }
    .sensoryFeedback(trigger: stage) {
      stage.sensoryFeedback
    }
    .sensoryFeedback(.selection, trigger: currentCardIndex) { _, _ in stage == .paging }
    .sensoryFeedback(.selection, trigger: selectionChangeToken) { _, _ in
      stage == .familyAuthorization && familyAuthorizationStatus == .approved
    }
  }
}

#Preview {
  OnboardingView {}
    .preferredColorScheme(.light)
}
