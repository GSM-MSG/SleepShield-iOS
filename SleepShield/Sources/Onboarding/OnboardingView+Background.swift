import SwiftUI

extension OnboardingView {
  @ViewBuilder
  var background: some View {
    let palette = palette(for: stage)

    ZStack {
      LinearGradient(
        colors: palette.linearColors,
        startPoint: .top,
        endPoint: .bottom
      )
      RadialGradient(
        colors: [
          palette.topHighlight,
          .clear
        ],
        center: palette.topCenter,
        startRadius: palette.topStartRadius,
        endRadius: palette.topEndRadius
      )
      .offset(palette.topOffset)
      RadialGradient(
        colors: [
          palette.bottomHighlight,
          .clear
        ],
        center: palette.bottomCenter,
        startRadius: palette.bottomStartRadius,
        endRadius: palette.bottomEndRadius
      )
      .offset(palette.bottomOffset)
    }
    .animation(.easeInOut(duration: 1.2), value: stage)
  }

  func palette(for stage: Stage) -> BackgroundPalette {
    switch stage {
    case .paging, .blocking:
      return .night
    case .morningPreview:
      return .sunrise
    case .morning:
      return .morning
    case .familyAuthorization, .routineSleepTime, .routineWakeTime, .routineSummary:
      return .routine
    }
  }
}

extension OnboardingView {
  struct BackgroundPalette {
    let linearColors: [Color]
    let topHighlight: Color
    let bottomHighlight: Color
    let topCenter: UnitPoint
    let bottomCenter: UnitPoint
    let topStartRadius: CGFloat
    let topEndRadius: CGFloat
    let bottomStartRadius: CGFloat
    let bottomEndRadius: CGFloat
    let topOffset: CGSize
    let bottomOffset: CGSize

    static let night = BackgroundPalette(
      linearColors: [
        Color(red: 0.02, green: 0.05, blue: 0.15),
        Color(red: 0.01, green: 0.02, blue: 0.06)
      ],
      topHighlight: Color(red: 0.18, green: 0.23, blue: 0.35).opacity(0.6),
      bottomHighlight: Color(red: 0.32, green: 0.18, blue: 0.4).opacity(0.35),
      topCenter: .topLeading,
      bottomCenter: .bottomTrailing,
      topStartRadius: 20,
      topEndRadius: 400,
      bottomStartRadius: 40,
      bottomEndRadius: 420,
      topOffset: CGSize(width: -140, height: -180),
      bottomOffset: .zero
    )

    static let sunrise = BackgroundPalette(
      linearColors: [
        Color(red: 0.12, green: 0.16, blue: 0.32),
        Color(red: 0.36, green: 0.26, blue: 0.46)
      ],
      topHighlight: Color(red: 0.34, green: 0.28, blue: 0.52).opacity(0.45),
      bottomHighlight: Color(red: 0.78, green: 0.46, blue: 0.35).opacity(0.32),
      topCenter: .topLeading,
      bottomCenter: .bottomTrailing,
      topStartRadius: 26,
      topEndRadius: 420,
      bottomStartRadius: 58,
      bottomEndRadius: 430,
      topOffset: CGSize(width: -120, height: -200),
      bottomOffset: CGSize(width: 56, height: 110)
    )

    static let morning = BackgroundPalette(
      linearColors: [
        Color(red: 0.99, green: 0.87, blue: 0.68),
        Color(red: 0.99, green: 0.72, blue: 0.54)
      ],
      topHighlight: Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.55),
      bottomHighlight: Color(red: 0.98, green: 0.66, blue: 0.39).opacity(0.38),
      topCenter: .topLeading,
      bottomCenter: .bottom,
      topStartRadius: 40,
      topEndRadius: 460,
      bottomStartRadius: 70,
      bottomEndRadius: 480,
      topOffset: CGSize(width: -80, height: -220),
      bottomOffset: CGSize(width: 48, height: 160)
    )

    static let routine = BackgroundPalette(
      linearColors: [
        Color(red: 0.94, green: 0.96, blue: 1.0),
        Color(red: 0.82, green: 0.88, blue: 0.99)
      ],
      topHighlight: Color(red: 0.78, green: 0.86, blue: 1.0).opacity(0.45),
      bottomHighlight: Color(red: 0.92, green: 0.8, blue: 0.88).opacity(0.35),
      topCenter: .topTrailing,
      bottomCenter: .bottom,
      topStartRadius: 60,
      topEndRadius: 480,
      bottomStartRadius: 80,
      bottomEndRadius: 520,
      topOffset: CGSize(width: 120, height: -240),
      bottomOffset: CGSize(width: -40, height: 200)
    )
  }
}
