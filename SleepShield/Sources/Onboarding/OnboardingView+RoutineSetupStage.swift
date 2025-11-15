import SwiftUI

extension OnboardingView {
  struct RoutineSetupStage: View {
    let stage: Stage
    let title: LocalizedStringKey
    @Binding var sleepTime: Date
    @Binding var wakeTime: Date
    @Binding var preSleepBlockingMinutes: Int
    @Binding var postWakeBlockingMinutes: Int
    @Binding var repeatWeekday: RepeatWeekday
    @Binding var alarmDraft: AlarmDraft?
    @Binding var isPresentingAlarmSheet: Bool
    @Binding var didSkipAlarmSelection: Bool
    @Binding var shouldAdvanceAfterAlarmSheet: Bool

    var body: some View {
      ScrollView {
        VStack(spacing: 36) {
          Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .fontDesign(.rounded)
            .multilineTextAlignment(.center)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .contentTransition(.numericText())
            .minimumScaleFactor(0.3)
            .padding(.horizontal)
            .containerRelativeFrame(.vertical) { length, _ in
              length * 0.1
            }
            .padding(.top, 24)

          if stage == .routineWakeTime ||  stage == .routineSleepTime {
            Spacer(minLength: 0)
          }

          SleepRoutineSetupView(
            stage: stage,
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

          Spacer()
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  struct SleepRoutineSetupView: View {
    let stage: Stage
    @Binding var sleepTime: Date
    @Binding var wakeTime: Date
    @Binding var preSleepBlockingMinutes: Int
    @Binding var postWakeBlockingMinutes: Int
    @Binding var repeatWeekday: RepeatWeekday
    @Binding var alarmDraft: AlarmDraft?
    @Binding var isPresentingAlarmSheet: Bool
    @Binding var didSkipAlarmSelection: Bool
    @Binding var shouldAdvanceAfterAlarmSheet: Bool
    @Environment(\.calendar) private var calendar
    @Namespace private var card

    private static let weekdayBaseOrder: [RepeatWeekday] = [
      .sunday,
      .monday,
      .tuesday,
      .wednesday,
      .thursday,
      .friday,
      .saturday
    ]

    var body: some View {
      stageCard
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var stageCard: some View {
      switch stage {
      case .routineSleepTime:
        timeCard(
          title: "Bedtime",
          date: $sleepTime,
          gradient: [
            Color(red: 0.22, green: 0.2, blue: 0.42),
            Color(red: 0.08, green: 0.1, blue: 0.25)
          ],
          primaryColor: .white,
          secondaryColor: Color.white.opacity(0.7),
          dividerColor: Color.white.opacity(0.18),
          borderColor: Color.white.opacity(0.22),
          prefersDarkControls: true,
          blocking: BlockingConfiguration(
            title: "Pre-sleep blocking",
            systemImage: "moon.zzz",
            minutes: $preSleepBlockingMinutes,
            labelColor: Color.white.opacity(0.8),
            valueColor: Color.white,
            backgroundColor: Color.white.opacity(0.14),
            formattedValue: preSleepBlockingDisplayValue
          )
        )
      case .routineWakeTime:
        VStack(spacing: 20) {
          timeCard(
            title: "Wake-up",
            date: $wakeTime,
            gradient: [
              Color(red: 1.0, green: 0.93, blue: 0.8),
              Color(red: 0.99, green: 0.78, blue: 0.56)
            ],
            primaryColor: Color(red: 0.48, green: 0.35, blue: 0.26),
            secondaryColor: Color(red: 0.66, green: 0.5, blue: 0.38),
            dividerColor: Color(red: 0.94, green: 0.81, blue: 0.66).opacity(0.6),
            borderColor: Color.white.opacity(0.6),
            prefersDarkControls: false,
            blocking: BlockingConfiguration(
              title: "Post-wake blocking",
              systemImage: "sun.max",
              minutes: $postWakeBlockingMinutes,
              labelColor: Color(red: 0.46, green: 0.35, blue: 0.26),
              valueColor: Color(red: 0.48, green: 0.35, blue: 0.26),
              backgroundColor: Color.white.opacity(0.85),
              formattedValue: postWakeBlockingDisplayValue
            )
          )
        }
      case .routineSummary:
        summaryCard
      default:
        EmptyView()
      }
    }

    private struct BlockingConfiguration {
      let title: LocalizedStringKey
      let systemImage: String
      let minutes: Binding<Int>
      let labelColor: Color
      let valueColor: Color
      let backgroundColor: Color
      let formattedValue: (Int) -> String
    }

    @ViewBuilder
    private func timeCard(
      title: LocalizedStringKey,
      date: Binding<Date>,
      gradient: [Color],
      primaryColor: Color,
      secondaryColor: Color,
      dividerColor: Color,
      borderColor: Color,
      prefersDarkControls: Bool,
      blocking: BlockingConfiguration? = nil
    ) -> some View {
      VStack(alignment: .leading, spacing: 20) {
        HStack(spacing: 16) {
          routineIcon(size: 48)

          VStack(alignment: .leading, spacing: 4) {
            Text(title)
              .font(.headline)
              .foregroundStyle(secondaryColor)

            Text(timeString(for: date.wrappedValue))
              .font(.system(size: 48, weight: .bold, design: .rounded))
              .contentTransition(.numericText())
              .foregroundStyle(primaryColor)
          }
        }

        Rectangle()
          .fill(dividerColor)
          .frame(height: 1)

        DatePicker(
          "",
          selection: date,
          displayedComponents: .hourAndMinute
        )
        .labelsHidden()
        .datePickerStyle(.wheel)
        .frame(maxWidth: 300)
        .frame(height: 150)
        .environment(\.colorScheme, prefersDarkControls ? .dark : .light)

        if let blocking {
          Rectangle()
            .fill(dividerColor.opacity(0.8))
            .frame(height: 1)

          DurationMenu(
            minutes: blocking.minutes,
            options: Array(stride(from: 0, through: 3 * 60, by: 15)),
            formattedValue: blocking.formattedValue,
            labelColor: blocking.labelColor,
            valueColor: blocking.valueColor,
            backgroundColor: blocking.backgroundColor,
            label: {
              Label(blocking.title, systemImage: blocking.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(blocking.labelColor)
            }
          )
        }
      }
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(
            LinearGradient(
              colors: gradient,
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .matchedGeometryEffect(id: "card", in: card)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(borderColor)
      )
      .fixedSize()
    }

    private var summaryCard: some View {
      VStack(alignment: .leading, spacing: 24) {
        HStack(spacing: 16) {
          Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(.white)
            .padding(16)
            .background(
              Circle()
                .fill(Color(red: 0.42, green: 0.54, blue: 0.96))
            )

          VStack(alignment: .leading, spacing: 6) {
            Text("Almost there")
              .font(.headline)
              .foregroundStyle(Color.black)
            Text("Make sure these times look right before we continue.")
              .font(.subheadline)
              .foregroundStyle(Color.gray)
          }
        }

        Rectangle()
          .fill(Color.white.opacity(0.45))
          .frame(height: 1)

        VStack(alignment: .leading, spacing: 20) {
          summaryRow(
            iconName: "moon.zzz.fill",
            iconForeground: .white,
            iconBackground: Color(red: 0.27, green: 0.28, blue: 0.52),
            title: "Bedtime",
            time: timeString(for: sleepTime),
            blockingDescription: preSleepBlockingDescription()
          )

          Rectangle()
            .fill(Color.white.opacity(0.35))
            .frame(height: 1)

          summaryRow(
            iconName: "sun.max.fill",
            iconForeground: Color(red: 0.98, green: 0.7, blue: 0.32),
            iconBackground: Color(red: 1.0, green: 0.94, blue: 0.82),
            title: "Wake-up",
            time: timeString(for: wakeTime),
            blockingDescription: postWakeBlockingDescription()
          )
        }

        Rectangle()
          .fill(Color.white.opacity(0.35))
          .frame(height: 1)

        VStack(alignment: .leading, spacing: 12) {
          Text("Active days")
            .font(.headline)
            .foregroundStyle(Color.gray)

          weekdaySelector

          Text(repeatWeekdaySummary)
            .font(.subheadline)
            .foregroundStyle(Color.gray)
            .fixedSize(horizontal: false, vertical: true)

          if repeatWeekday.isEmpty {
            Text("Select at least one day to continue.")
              .font(.footnote.weight(.semibold))
              .foregroundStyle(Color.red.secondary)
          }
        }

        Rectangle()
          .fill(Color.white.opacity(0.35))
          .frame(height: 1)

        alarmSummarySection
      }
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.91, green: 0.95, blue: 1.0),
                Color(red: 0.97, green: 0.93, blue: 1.0)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .matchedGeometryEffect(id: "card", in: card)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(Color.white.opacity(0.65))
      )
    }

  private func summaryRow(
    iconName: String,
    iconForeground: Color,
    iconBackground: Color,
    title: LocalizedStringKey,
    time: String,
    blockingDescription: LocalizedStringResource?
  ) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: iconName)
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(iconForeground)
        .padding(14)
        .background(
          Circle()
            .fill(iconBackground)
        )

      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.headline)
          .foregroundStyle(Color.gray)

        Text(time)
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .foregroundStyle(.black)
          .contentTransition(.numericText())

        if let blockingDescription {
          Text(blockingDescription)
            .font(.subheadline)
            .foregroundStyle(Color.gray)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private var alarmSummarySection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 12) {
        Image(systemName: "alarm.fill")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(alarmIconForeground)
          .frame(width: 44, height: 44)
          .background(
            Circle()
              .fill(alarmIconBackground)
          )

        VStack(alignment: .leading, spacing: 4) {
          Text("Alarm")
            .font(.headline)
            .foregroundStyle(Color.gray)

          Text(alarmSummaryHeadline)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .contentTransition(.numericText())
            .foregroundStyle(.black)
        }
      }

      Text(alarmSummaryDescription)
        .font(.subheadline)
        .foregroundStyle(.gray)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

    private var weekdaySelector: some View {
      HStack(spacing: 8) {
        ForEach(weekdayChipItems, id: \.day) { item in
          Button {
            toggleWeekday(item.day)
          } label: {
            Text(item.symbol)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(foregroundColor(for: item.day))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .aspectRatio(1.0, contentMode: .fill)
              .background(
                Circle()
                  .fill(circleBackground(for: item.day))
              )
              .overlay(
                Circle()
                  .stroke(borderColor(for: item.day), lineWidth: 1)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel(accessibilityLabel(for: item.day))
          .accessibilityValue(repeatWeekday.contains(item.day) ? "Selected" : "Not selected")
        }
      }
      .padding(.horizontal, 4)
      .frame(maxWidth: .infinity)
      .animation(.easeInOut(duration: 0.2), value: repeatWeekday)
      .sensoryFeedback(.selection, trigger: repeatWeekday.rawValue)
    }

    private var weekdayChipItems: [(day: RepeatWeekday, symbol: String)] {
      weekdayDisplayItems(
        symbols: calendar.veryShortStandaloneWeekdaySymbols,
        fallback: ["S", "M", "T", "W", "T", "F", "S"]
      ).map { (day: $0.0, symbol: $0.1) }
    }

    private var weekdayNameItems: [(day: RepeatWeekday, name: String)] {
      weekdayDisplayItems(
        symbols: calendar.weekdaySymbols,
        fallback: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
      ).map { (day: $0.0, name: $0.1) }
    }

    private func weekdayDisplayItems(
      symbols: [String],
      fallback: [String]
    ) -> [(RepeatWeekday, String)] {
      let baseCount = Self.weekdayBaseOrder.count
      let activeSymbols = symbols.count == baseCount ? symbols : fallback

      return (0..<baseCount).map { index in
        let symbolIndex = (index + calendar.firstWeekday - 1) % baseCount
        return (Self.weekdayBaseOrder[symbolIndex], activeSymbols[symbolIndex])
      }
    }

    private var alarmIconForeground: Color {
      alarmDraft == nil ? Color(red: 0.46, green: 0.35, blue: 0.26) : .white
    }

    private var alarmIconBackground: Color {
      alarmDraft == nil
        ? Color(red: 1.0, green: 0.94, blue: 0.82)
        : Color(red: 0.48, green: 0.35, blue: 0.26)
    }

    private var alarmSummaryHeadline: String {
      if let draft = alarmDraft {
        return timeString(for: alarmDate(from: draft))
      }
      return "Off"
    }

    private var alarmSummaryDescription: LocalizedStringResource {
      if alarmDraft != nil {
        return "Rings on your selected days."
      }
      return "No alarm scheduled. You can add one later in Settings."
    }

    private var alarmButtonTimeText: String {
      if let draft = alarmDraft {
        return timeString(for: alarmDate(from: draft))
      }
      if didSkipAlarmSelection {
        return String(localized: "Off")
      }
      return timeString(for: wakeTime)
    }

    private var alarmButtonSubtitleText: LocalizedStringResource {
      if alarmDraft != nil {
        return "Tap to adjust"
      }
      return didSkipAlarmSelection ? "Alarm disabled" : "Optional · matches wake-up time"
    }

    private var alarmAccessibilityValue: LocalizedStringKey {
      if let draft = alarmDraft {
        return "Enabled at \(timeString(for: alarmDate(from: draft)))"
      }
      return didSkipAlarmSelection ? "Disabled" : "Not configured"
    }

    private var repeatWeekdaySummary: String {
      if repeatWeekday.isEmpty {
        return String(localized: "No days selected")
      }
      if repeatWeekday == .everyday {
        return String(localized: "Every day")
      }
      if repeatWeekday == .weekdays {
        return String(localized: "Weekdays")
      }
      if repeatWeekday == RepeatWeekday.weekend {
        return String(localized: "Weekends")
      }

      let names = weekdayNameItems.compactMap { item in
        repeatWeekday.contains(item.day) ? item.name : nil
      }

      guard names.isEmpty == false else { return String(localized: "No days selected") }
      return ListFormatter.localizedString(byJoining: names)
    }

    private func toggleWeekday(_ day: RepeatWeekday) {
      withAnimation(.easeInOut(duration: 0.2)) {
        if repeatWeekday.contains(day) {
          _ = repeatWeekday.remove(day)
        } else {
          repeatWeekday.insert(day)
        }
      }
    }

    private func circleBackground(for day: RepeatWeekday) -> Color {
      repeatWeekday.contains(day) ? Color.accentColor : Color.white.opacity(0.85)
    }

    private func foregroundColor(for day: RepeatWeekday) -> Color {
      repeatWeekday.contains(day) ? .white : Color(red: 0.36, green: 0.4, blue: 0.55)
    }

    private func borderColor(for day: RepeatWeekday) -> Color {
      repeatWeekday.contains(day) ? Color.clear : Color.white.opacity(0.6)
    }

    private func accessibilityLabel(for day: RepeatWeekday) -> String {
      weekdayNameItems.first(where: { $0.day == day })?.name ?? "Day"
    }

    private func alarmDate(from draft: AlarmDraft) -> Date {
      let dayStart = calendar.startOfDay(for: wakeTime)
      return calendar.date(
        bySettingHour: draft.hour,
        minute: draft.minute,
        second: 0,
        of: dayStart
      ) ?? wakeTime
    }

    private func preSleepBlockingDescription() -> LocalizedStringResource {
      guard preSleepBlockingMinutes > 0,
        let start = calendar.date(byAdding: .minute, value: -preSleepBlockingMinutes, to: sleepTime)
      else {
        return "Blocking stays off before bed"
      }
      return "Blocking starts at \(timeString(for: start))"
    }

    private func preSleepBlockingDisplayValue(_ minutes: Int) -> String {
      minutes == 0 ? String(localized: "At time of sleep") : localizedDuration(minutes)
    }

    private func postWakeBlockingDescription() -> LocalizedStringResource {
      guard postWakeBlockingMinutes > 0,
        let end = calendar.date(byAdding: .minute, value: postWakeBlockingMinutes, to: wakeTime)
      else {
        return "Blocking lifts right away"
      }
      return "Blocking lifts at \(timeString(for: end))"
    }

    private func postWakeBlockingDisplayValue(_ minutes: Int) -> String {
      minutes == 0 ? String(localized: "At time of wake up") : localizedDuration(minutes)
    }

    private func routineIcon(size: CGFloat) -> some View {
      Image(systemName: iconName)
        .font(.system(size: size * 0.6))
        .foregroundStyle(iconColor)
        .padding(size * 0.38)
        .background {
          Circle()
            .fill(iconBackgroundColor)
        }
        .contentTransition(
          .symbolEffect(
            .replace.magic(fallback: .downUp.byLayer),
            options: .nonRepeating
          )
        )
    }

    private var iconName: String {
      switch stage {
      case .routineSleepTime:
        return "moon.zzz.fill"
      case .routineWakeTime:
        return "sun.max.fill"
      case .routineSummary:
        return "checkmark.seal.fill"
      default:
        return "circle"
      }
    }

    private var iconColor: Color {
      switch stage {
      case .routineSleepTime:
        return .white
      case .routineWakeTime:
        return Color(red: 0.98, green: 0.7, blue: 0.32)
      case .routineSummary:
        return Color(red: 0.42, green: 0.54, blue: 0.96)
      default:
        return .primary
      }
    }

    private var iconBackgroundColor: Color {
      switch stage {
      case .routineSleepTime:
        return Color.white.opacity(0.2)
      case .routineWakeTime:
        return Color.white.opacity(0.85)
      case .routineSummary:
        return Color.white.opacity(0.85)
      default:
        return Color.white.opacity(0.4)
      }
    }

    private func localizedDuration(_ minutes: Int) -> String {
      guard minutes >= 0 else { return "" }

      var components = DateComponents()
      components.hour = minutes / 60
      components.minute = minutes % 60

      if let formatted = OnboardingView.durationFormatter.string(from: components), !formatted.isEmpty {
        return formatted
      }

      let measurement = Measurement(value: Double(minutes), unit: UnitDuration.minutes)
      return OnboardingView.minuteMeasurementFormatter.string(from: measurement)
    }

    private func timeString(for date: Date) -> String {
      ShortsClock.formatter.string(from: date)
    }
  }

  struct DurationMenu<Label: View>: View {
    @Binding var minutes: Int
    let options: [Int]
    let formattedValue: (Int) -> String
    let labelColor: Color
    let valueColor: Color
    let backgroundColor: Color
    @ViewBuilder let label: () -> Label

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        label()

        Menu {
          ForEach(options, id: \.self) { option in
            Button {
              minutes = option
            } label: {
              HStack {
                Text(formattedValue(option))
                if option == minutes {
                  Spacer()
                  Image(systemName: "checkmark")
                }
              }
            }
          }
        } label: {
          HStack {
            Text(formattedValue(minutes))
              .font(.title3.weight(.semibold))
              .foregroundStyle(valueColor)
            Spacer()
            Image(systemName: "chevron.down")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(valueColor.opacity(0.75))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .fill(backgroundColor)
          )
        }
        .buttonStyle(.plain)
      }
      .sensoryFeedback(.selection, trigger: minutes)
    }
  }

  struct AlarmSetupSheet: View {
    let wakeTime: Date
    @Binding var alarmDraft: AlarmDraft?
    @Binding var isPresented: Bool
    @Binding var pendingCancellationID: UUID?
    @Binding var didSkipAlarm: Bool
    @Environment(\.calendar) private var calendar
    @State private var selectedDate: Date = .now

    var body: some View {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 6) {
          Text("\(Image(systemName: "alarm.fill")) Wake-up alarm")
            .font(.title2.weight(.semibold))
            .fontDesign(.rounded)
          Text("We’ll ring your alarm on the days your routine repeats.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        VStack(spacing: 16) {
          DatePicker(
            "Alarm time",
            selection: $selectedDate,
            displayedComponents: .hourAndMinute
          )
          .labelsHidden()
          .datePickerStyle(.wheel)
          .frame(maxWidth: .infinity)
          .frame(height: 160)

          Button {
            saveAlarm()
          } label: {
            Text("Save Alarm")
              .fontWeight(.semibold)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(.accentColor)
        }

        Button {
          skipAlarm()
        } label: {
          Text("Skip for now")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 32)
      .padding(.horizontal, 24)
      .presentationDragIndicator(.visible)
      .onAppear {
        AnalyticsClient.shared.track(event: .viewOnboardingAlarmSetup)
        selectedDate = initialDate()
      }
      .onChange(of: wakeTime) { _, newValue in
        guard alarmDraft == nil else { return }
        selectedDate = align(date: selectedDate, to: newValue)
      }
    }

    private func saveAlarm() {
      let components = calendar.dateComponents([.hour, .minute], from: selectedDate)
      let hour = components.hour ?? calendar.component(.hour, from: wakeTime)
      let minute = components.minute ?? calendar.component(.minute, from: wakeTime)
      let identifier = alarmDraft?.id ?? UUID()
      alarmDraft = AlarmDraft(id: identifier, hour: hour, minute: minute)
      pendingCancellationID = nil
      didSkipAlarm = false

      AnalyticsClient.shared.track(event: .setupOnboardingAlarm(alarmTime: selectedDate))

      isPresented = false
    }

    private func skipAlarm() {
      if let id = alarmDraft?.id {
        pendingCancellationID = id
      }
      alarmDraft = nil
      didSkipAlarm = true

      AnalyticsClient.shared.track(event: .skipOnboardingAlarm)

      isPresented = false
    }

    private func initialDate() -> Date {
      if let draft = alarmDraft {
        return date(from: draft)
      }
      return wakeTime
    }

    private func align(date: Date, to reference: Date) -> Date {
      let components = calendar.dateComponents([.hour, .minute], from: date)
      return calendar.date(
        bySettingHour: components.hour ?? calendar.component(.hour, from: reference),
        minute: components.minute ?? calendar.component(.minute, from: reference),
        second: 0,
        of: reference
      ) ?? reference
    }

    private func date(from draft: AlarmDraft) -> Date {
      let dayStart = calendar.startOfDay(for: wakeTime)
      return calendar.date(
        bySettingHour: draft.hour,
        minute: draft.minute,
        second: 0,
        of: dayStart
      ) ?? wakeTime
    }
  }
}
