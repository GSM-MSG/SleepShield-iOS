import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct SleepShieldWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<SleepTimelineAlarmMetadata>.self) { context in
      lockScreenView(attributes: context.attributes, state: context.state)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          alarmTitle(attributes: context.attributes, state: context.state)
        }

        DynamicIslandExpandedRegion(.trailing) {
          sleepIcon(state: context.state)
        }

        DynamicIslandExpandedRegion(.bottom) {
          bottomView(attributes: context.attributes, state: context.state)
        }

      } compactLeading: {
        countdown(state: context.state, maxWidth: 44)
          .foregroundStyle(context.attributes.tintColor)

      } compactTrailing: {
        AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)

      } minimal: {
        AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)
      }
      .keylineTint(context.attributes.tintColor)
    }
  }

  func lockScreenView(
    attributes: AlarmAttributes<SleepTimelineAlarmMetadata>,
    state: AlarmPresentationState
  ) -> some View {
    VStack {
      HStack(alignment: .top) {
        alarmTitle(attributes: attributes, state: state)
        Spacer()
        sleepIcon(state: state)
      }

      bottomView(attributes: attributes, state: state)
    }
    .padding(.all, 12)
  }

  func bottomView(
    attributes: AlarmAttributes<SleepTimelineAlarmMetadata>,
    state: AlarmPresentationState
  ) -> some View {
    HStack {
      countdown(state: state, maxWidth: 150)
        .font(.system(size: 40, design: .rounded))

      Spacer()

      AlarmControls(presentation: attributes.presentation, state: state)
    }
  }

  func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
    Group {
      switch state.mode {
      case .countdown(let countdown):
        Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
      case .paused(let pausedState):
        let remaining = Duration.seconds(
          pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
        )
        let pattern: Duration.TimeFormatStyle.Pattern =
          remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
        Text(remaining.formatted(.time(pattern: pattern)))
      default:
        EmptyView()
      }
    }
    .monospacedDigit()
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .frame(maxWidth: maxWidth, alignment: .leading)
  }

  @ViewBuilder func alarmTitle(
    attributes: AlarmAttributes<SleepTimelineAlarmMetadata>,
    state: AlarmPresentationState
  ) -> some View {
    let title: LocalizedStringResource? =
      switch state.mode {
      case .countdown:
        attributes.presentation.countdown?.title
      case .paused:
        attributes.presentation.paused?.title
      default:
        nil
      }

    if let title {
      Text(title)
        .font(.title3)
        .fontWeight(.semibold)
        .lineLimit(1)
        .padding(.leading, 6)
    }
  }

  @ViewBuilder func sleepIcon(state: AlarmPresentationState) -> some View {
    let iconName: String =
      switch state.mode {
      case .countdown, .paused:
        "moon.zzz"
      default:
        "sun.horizon"
      }

    Image(systemName: iconName)
      .font(.body)
      .fontWeight(.medium)
      .lineLimit(1)
      .padding(.trailing, 6)
  }
}

struct AlarmProgressView: View {
  var mode: AlarmPresentationState.Mode
  var tint: Color

  var body: some View {
    Group {
      switch mode {
      case .countdown(let countdown):
        ProgressView(
          timerInterval: Date.now...countdown.fireDate,
          countsDown: true,
          label: { EmptyView() },
          currentValueLabel: {
            Image(systemName: "moon.zzz")
              .scaleEffect(0.9)
          }
        )
      case .paused(let pausedState):
        let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
        ProgressView(
          value: remaining,
          total: pausedState.totalCountdownDuration,
          label: { EmptyView() },
          currentValueLabel: {
            Image(systemName: "pause.fill")
              .scaleEffect(0.8)
          }
        )
      default:
        EmptyView()
      }
    }
    .progressViewStyle(.circular)
    .foregroundStyle(tint)
    .tint(tint)
  }
}

struct AlarmControls: View {
  var presentation: AlarmPresentation
  var state: AlarmPresentationState

  var body: some View {
    HStack(spacing: 4) {
      switch state.mode {
      case .countdown, .paused:
        ButtonView(
          config: presentation.countdown?.pauseButton,
          intent: RepeatIntent(alarmID: state.alarmID.uuidString),
          tint: .orange
        )
      default:
        EmptyView()
      }

      ButtonView(
        config: presentation.alert.stopButton,
        intent: StopIntent(alarmID: state.alarmID.uuidString),
        tint: .red
      )
    }
  }
}

struct ButtonView<I>: View where I: AppIntent {
  var config: AlarmButton
  var intent: I
  var tint: Color

  init?(config: AlarmButton?, intent: I, tint: Color) {
    guard let config else { return nil }
    self.config = config
    self.intent = intent
    self.tint = tint
  }

  var body: some View {
    Button(intent: intent) {
      Label(config.text, systemImage: config.systemImageName)
        .lineLimit(1)
    }
    .tint(tint)
    .buttonStyle(.borderedProminent)
    .frame(width: 96, height: 30)
  }
}
