import SwiftUI

extension OnboardingView {
  struct PhoneScene: View {
    let stage: Stage
    let currentIndex: Int
    let items: [ShortsItem]
    let displayedTime: Date

    var body: some View {
      ZStack {
        RoundedRectangle(cornerRadius: 44, style: .continuous)
          .fill(shellColor)
          .overlay {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
              .stroke(shellStrokeColor, lineWidth: 1.5)
          }

        RoundedRectangle(cornerRadius: 38, style: .continuous)
          .fill(screenColor)
          .padding(10)
          .overlay(contentOverlay)
      }
      .animation(.easeInOut(duration: 0.7), value: stage)
    }

    @ViewBuilder private var contentOverlay: some View {
      VStack(spacing: 0) {
        StatusBar(stage: stage, displayedTime: displayedTime)
          .padding(.horizontal, 20)
          .padding(.top, 20)
          .padding(.bottom, 12)

        Rectangle()
          .fill(dividerColor)
          .frame(height: 1)
          .padding(.horizontal, 20)

        ShortsStage(stage: stage, currentIndex: currentIndex, items: items)
      }
      .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
      .animation(.easeInOut(duration: 0.7), value: stage)
    }

    private var shellColor: Color {
      Color.black.opacity(0.65)
    }

    private var shellStrokeColor: Color {
      Color.white.opacity(0.18)
    }

    private var screenColor: Color {
      Color.black.opacity(0.9)
    }

    private var dividerColor: Color {
      Color.white.opacity(0.08)
    }
  }

  struct StatusBar: View {
    let stage: Stage
    let displayedTime: Date

    var body: some View {
      HStack {
        Text(timeString)
          .font(.system(size: 22, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(primaryColor)
          .contentTransition(.numericText())

        Spacer()

        trailingContent
      }
      .padding(.horizontal, 4)
      .animation(.easeInOut(duration: 0.35), value: timeString)
      .animation(.easeInOut(duration: 0.35), value: stage)
    }

    private var timeString: String {
      switch stage {
      case .blocking:
        return ShortsClock.targetTimeString
      case .paging, .morningPreview, .morning, .familyAuthorization:
        return ShortsClock.formatter.string(from: displayedTime)
      case .routineSleepTime, .routineWakeTime, .routineSummary:
        return ShortsClock.formatter.string(from: ShortsClock.morningReleaseTime)
      }
    }

    private var primaryColor: Color {
      switch stage {
      case .paging, .blocking, .morningPreview, .morning, .familyAuthorization, .routineSleepTime, .routineWakeTime, .routineSummary:
        return .white
      }
    }

    private var secondaryColor: Color {
      switch stage {
      case .paging:
        return Color.white.opacity(0.85)
      case .blocking, .morningPreview:
        return Color.white.opacity(0.9)
      case .morning, .familyAuthorization, .routineSleepTime, .routineWakeTime, .routineSummary:
        return Color.white.opacity(0.9)
      }
    }

    @ViewBuilder
    private var trailingContent: some View {
      HStack(spacing: 6) {
        Image(systemName: "wifi")
        Image(systemName: "battery.100")
      }
      .font(.system(size: 16, weight: .medium))
      .foregroundStyle(secondaryColor)
    }
  }

  struct ShortsStage: View {
    let stage: Stage
    let currentIndex: Int
    let items: [ShortsItem]

    var body: some View {
      GeometryReader { proxy in
        ZStack {
          ShortsPager(items: items, currentIndex: currentIndex)
            .frame(width: proxy.size.width, height: proxy.size.height)

          if stage == .blocking || stage == .morningPreview {
            BlockingOverlay()
              .transition(.opacity)
          } else if stage == .morning {
            MorningOverlay()
              .transition(.opacity)
          }
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(outlineColor, lineWidth: 1)
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.horizontal, 18)
      .padding(.top, 16)
      .padding(.bottom, 22)
    }

    private var outlineColor: Color {
      switch stage {
      case .morning, .familyAuthorization, .routineSleepTime, .routineWakeTime, .routineSummary:
        return Color.black.opacity(0.08)
      case .paging, .blocking, .morningPreview:
        return Color.white.opacity(0.05)
      }
    }
  }

  struct ShortsPager: View {
    let items: [ShortsItem]
    let currentIndex: Int

    var body: some View {
      GeometryReader { proxy in
        ZStack {
          ForEach(items.indices, id: \.self) { index in
            if index == currentIndex {
              ShortsCard(item: items[index])
                .frame(width: proxy.size.width, height: proxy.size.height)
                .transition(
                  .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                  )
                )
            }
          }
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
      }
      .allowsHitTesting(false)
    }
  }

  struct ShortsCard: View {
    let item: ShortsItem

    var body: some View {
      ZStack(alignment: .bottomLeading) {
        LinearGradient(
          colors: item.colors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .overlay(
          LinearGradient(
            colors: [
              Color.black.opacity(0.1),
              Color.black.opacity(0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )

        VStack(alignment: .leading, spacing: 12) {
          Capsule()
            .fill(Color.white.opacity(0.45))
            .frame(width: 62, height: 4)

          VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
              .font(.title3.weight(.semibold))
              .foregroundStyle(.white)
              .lineLimit(2)
            Text(item.subtitle)
              .font(.subheadline)
              .foregroundStyle(Color.white.opacity(0.85))
          }
        }
        .padding(24)
      }
      .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
      .shadow(color: Color.black.opacity(0.55), radius: 14, x: 0, y: 12)
    }
  }

  struct ShortsItem: Identifiable, Equatable {
    var id: String { "\(title)" }
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let colors: [Color]
  }

  enum ShortsContent {
    static let items: [ShortsItem] = [
      ShortsItem(
        title: "Late-night meme sprint",
        subtitle: "Shorts • 12K watching",
        colors: [
          Color(red: 0.92, green: 0.3, blue: 0.48),
          Color(red: 0.57, green: 0.16, blue: 0.64)
        ]
      ),
      ShortsItem(
        title: "Top 5 midnight snacks",
        subtitle: "Shorts • 48K views",
        colors: [
          Color(red: 0.17, green: 0.43, blue: 0.86),
          Color(red: 0.04, green: 0.16, blue: 0.43)
        ]
      ),
      ShortsItem(
        title: "Spooky story in 60s",
        subtitle: "Shorts • Premiering now",
        colors: [
          Color(red: 0.98, green: 0.55, blue: 0.26),
          Color(red: 0.64, green: 0.18, blue: 0.18)
        ]
      ),
      ShortsItem(
        title: "Hyper-productive morning",
        subtitle: "Shorts • 81K likes",
        colors: [
          Color(red: 0.39, green: 0.78, blue: 0.59),
          Color(red: 0.18, green: 0.46, blue: 0.38)
        ]
      )
    ]
  }

  enum ShortsClock {
    static let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .short
      formatter.locale = .autoupdatingCurrent
      formatter.calendar = .autoupdatingCurrent
      return formatter
    }()

    static let startTime = Calendar.autoupdatingCurrent.date(from: DateComponents(hour: 22, minute: 57)) ?? .now
    static let totalSteps: Int = 3
    static let tickInterval: TimeInterval = 1.4
    static let morningPreviewTime = Calendar.autoupdatingCurrent.date(from: DateComponents(hour: 7, minute: 27)) ?? .now
    static let morningCountdownStartTime = Calendar.autoupdatingCurrent.date(from: DateComponents(hour: 7, minute: 27)) ?? .now
    static let morningReleaseTime = Calendar.autoupdatingCurrent.date(from: DateComponents(hour: 7, minute: 30)) ?? .now
    static let morningCountdownTotalSteps: Int = 1
    static let morningCountdownInterval: TimeInterval = 1.1

    static var targetTimeString: String {
      "11:00 PM"
    }

    static func time(for minuteOffset: Int) -> Date {
      guard let date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: minuteOffset, to: startTime) else {
        return startTime
      }
      return date
    }

    static func morningCountdownTime(for minuteOffset: Int) -> Date {
      guard let date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: minuteOffset, to: morningCountdownStartTime) else {
        return morningCountdownStartTime
      }
      return date
    }
  }

  struct BlockingOverlay: View {
    var body: some View {
      VStack(spacing: 18) {
        Image(systemName: "lock.fill")
          .font(.system(size: 32))
          .foregroundStyle(.white)
          .padding(16)
          .background(
            Circle()
              .fill(Color.blue.gradient)
          )

        Text("Shorts is blocked")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.white)

        Text("Come back after 07:30")
          .font(.subheadline)
          .foregroundStyle(Color.white.opacity(0.75))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black.opacity(0.82))
    }
  }

  struct MorningOverlay: View {
    var body: some View {
      VStack(spacing: 20) {
        Image(systemName: "sunrise.fill")
          .font(.system(size: 34))
          .foregroundStyle(Color(red: 0.98, green: 0.63, blue: 0.28))
          .padding(16)
          .background(
            Circle()
              .fill(Color(red: 1.0, green: 0.95, blue: 0.86))
          )

        VStack(spacing: 8) {
          Text("Phone-free morning")
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color(red: 0.24, green: 0.28, blue: 0.34))

          Text("Wake with intention while we keep distracting apps snoozing.")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(red: 0.36, green: 0.41, blue: 0.49))
        }
        .padding(.horizontal, 12)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(
        LinearGradient(
          colors: [
            Color.white.opacity(0.96),
            Color(red: 0.99, green: 0.9, blue: 0.78)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    }
  }
}
