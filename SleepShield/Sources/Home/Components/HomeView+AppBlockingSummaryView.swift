import FamilyControls
import SwiftUI

extension HomeView {
  struct AppBlockingSummaryView: View {
    private let summaryIconSize: CGFloat = 56

    let selection: FamilyActivitySelection

    var body: some View {
      VStack(alignment: .leading, spacing: 32) {
        HStack {
          Text("Blocked")
            .font(.headline)
            .foregroundStyle(Color.textPrimary)

          Spacer()

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(Color.textPrimary)
        }
        .fontWeight(.semibold)
        .fontDesign(.rounded)

        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 18) {
            SummaryBadge(
              count: selection.categories.count,
              title: "Categories",
              systemName: "square.grid.2x2",
              gradientColors: [Color.blue.opacity(0.75), Color.indigo],
              layout: .stacked,
              iconSize: summaryIconSize
            )

            SummaryBadge(
              count: selection.applications.count,
              title: "Apps",
              systemName: "apps.iphone",
              gradientColors: [Color.purple, Color.blue],
              layout: .stacked,
              iconSize: summaryIconSize
            )

            SummaryBadge(
              count: selection.webDomains.count,
              title: "Web Domains",
              systemName: "globe",
              gradientColors: [Color.cyan, Color.blue.opacity(0.7)],
              layout: .stacked,
              iconSize: summaryIconSize
            )
          }

          VStack(alignment: .leading, spacing: 18) {
            SummaryBadge(
              count: selection.categories.count,
              title: "Categories",
              systemName: "square.grid.2x2",
              gradientColors: [Color.blue.opacity(0.75), Color.indigo],
              layout: .inline,
              iconSize: summaryIconSize
            )

            SummaryBadge(
              count: selection.applications.count,
              title: "Apps",
              systemName: "apps.iphone",
              gradientColors: [Color.purple, Color.blue],
              layout: .inline,
              iconSize: summaryIconSize
            )

            SummaryBadge(
              count: selection.webDomains.count,
              title: "Web Domains",
              systemName: "globe",
              gradientColors: [Color.cyan, Color.blue.opacity(0.7)],
              layout: .inline,
              iconSize: summaryIconSize
            )
          }
        }
      }
    }
  }
}

extension HomeView.AppBlockingSummaryView {
  struct SummaryBadge: View {
    enum LayoutStyle: Sendable {
      case stacked
      case inline
    }

    let count: Int
    let title: LocalizedStringKey
    let systemName: String
    let gradientColors: [Color]
    let layout: LayoutStyle
    let iconSize: CGFloat

    var body: some View {
      Group {
        switch layout {
        case .stacked:
          VStack(spacing: 12) {
            iconView()

            titleText()
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)

        case .inline:
          HStack(spacing: 16) {
            iconView()

            titleText()
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(title) blocked")
      .accessibilityValue("\(count)")
    }

    @ViewBuilder
    private func iconView() -> some View {
      ZStack(alignment: .topTrailing) {
        Circle()
          .fill(
            LinearGradient(
              colors: gradientColors,
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

        Text("\(count)")
          .font(.caption)
          .fontWeight(.bold)
          .fontDesign(.rounded)
          .foregroundStyle(Color.textPrimary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background {
            Circle()
              .fill(Color.textPrimary.opacity(0.16))
          }
          .offset(x: 12, y: -12)
      }
    }

    @ViewBuilder
    private func titleText() -> some View {
      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .fontDesign(.rounded)
        .foregroundStyle(Color.textPrimary.secondary)
    }
  }
}
