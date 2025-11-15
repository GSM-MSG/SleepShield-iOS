import SwiftUI
import FamilyControls

extension OnboardingView {
  struct FamilyControlsStageView: View {
    let status: AuthorizationStatus
    let isRequesting: Bool
    let selection: FamilyActivitySelection
    let selectionChangeToken: Int
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void
    let onEditSelection: () -> Void

    var body: some View {
      VStack(spacing: 24) {
        PermissionCard(
          status: status,
          isRequesting: isRequesting,
          onRequestPermission: onRequestPermission,
          onOpenSettings: onOpenSettings
        )

        if status == .approved {
          SelectionCard(
            selection: selection,
            onEditSelection: onEditSelection
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .frame(maxWidth: .infinity)
      .sensoryFeedback(trigger: status) { _, _ in
        status.sensoryFeedback
      }
      .sensoryFeedback(.selection, trigger: selectionChangeToken) { _, _ in
        status == .approved
      }
    }

    private struct PermissionCard: View {
      let status: AuthorizationStatus
      let isRequesting: Bool
      let onRequestPermission: () -> Void
      let onOpenSettings: () -> Void

      var body: some View {
        VStack(spacing: 18) {
          Image(systemName: "lock.shield")
            .font(.system(size: 40, weight: .semibold))
            .symbolVariant(.fill)
            .foregroundStyle(Color.blue)
            .padding(18)
            .background(
              Circle()
                .fill(Color.blue.opacity(0.12))
            )

          if status != .approved {
            Text("SleepShield needs Screen Time permission to block your selected apps.")
              .font(.body)
              .multilineTextAlignment(.center)
              .foregroundStyle(Color.primary.opacity(0.75))
          }

          StatusBadge(status: status, isRequesting: isRequesting)

          if let actionTitle = actionTitle {
            Button {
              action?()
            } label: {
              HStack(spacing: 10) {
                Text(buttonTitle)
                  .font(.headline.weight(.semibold))
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 14)
              }
              .foregroundStyle(Color.white)
              .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                  .fill(
                    LinearGradient(
                      colors: [
                        Color(red: 0.31, green: 0.53, blue: 0.98),
                        Color(red: 0.42, green: 0.66, blue: 1.0)
                      ],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
              )
            }
            .buttonStyle(.plain)
            .disabled(isRequesting || action == nil)
          }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
      }

      private var action: (() -> Void)? {
        switch status {
        case .notDetermined:
          return onRequestPermission
        case .denied:
          return onOpenSettings
        default:
          return nil
        }
      }

      private var actionTitle: String? {
        switch status {
        case .notDetermined:
          return "Grant permission"
        case .denied:
          return "Open Settings"
        default:
          return nil
        }
      }

      private var buttonTitle: String {
        isRequesting ? "Requesting..." : (actionTitle ?? "")
      }
    }

    private struct StatusBadge: View {
      let status: AuthorizationStatus
      let isRequesting: Bool

      var body: some View {
        HStack(spacing: 10) {
          Image(systemName: statusSymbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(statusColor)

          Text(statusLabel)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(statusColor)

          if isRequesting && status == .notDetermined {
            ProgressView()
              .controlSize(.small)
              .tint(statusColor)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
          Capsule(style: .continuous)
            .fill(statusColor.opacity(0.14))
        )
      }

      private var statusLabel: LocalizedStringKey {
        switch status {
        case .approved:
          return "Access granted"
        case .notDetermined:
          return "Awaiting approval"
        case .denied:
          return "Permission needed"
        @unknown default:
          return "Status unavailable"
        }
      }

      private var statusSymbol: String {
        switch status {
        case .approved:
          return "checkmark.circle.fill"
        case .notDetermined:
          return "questionmark.circle.fill"
        case .denied:
          return "exclamationmark.triangle.fill"
        @unknown default:
          return "questionmark.circle.fill"
        }
      }

      private var statusColor: Color {
        switch status {
        case .approved:
          return Color.green
        case .notDetermined:
          return Color.blue
        case .denied:
          return Color.orange
        @unknown default:
          return Color.gray
        }
      }
    }

    private struct SelectionCard: View {
      let selection: FamilyActivitySelection
      let onEditSelection: () -> Void

      var body: some View {
        VStack(spacing: 20) {
          SelectionSummary(selection: selection)

          Button {
            onEditSelection()
          } label: {
            Label("Choose apps and categories", systemImage: "square.grid.2x2")
              .font(.headline.weight(.semibold))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .foregroundStyle(Color.white)
              .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .fill(Color.blue.gradient)
              )
              .glassEffect(.identity.interactive(), in: .rect(cornerRadius: 18))
          }
          .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
      }
    }

    private struct SelectionSummary: View {
      let selection: FamilyActivitySelection

      var body: some View {
        VStack(spacing: 16) {
          if hasSelection {
            summaryRow(
              title: "Categories",
              systemName: "square.grid.2x2",
              color: Color.blue,
              count: selection.categories.count
            )
            summaryRow(
              title: "Apps",
              systemName: "apps.iphone",
              color: Color.purple,
              count: selection.applications.count
            )
            summaryRow(
              title: "Web Domains",
              systemName: "globe",
              color: Color.cyan,
              count: selection.webDomains.count
            )
          } else {
            VStack(spacing: 12) {
              Image(systemName: "apps.iphone")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.blue)
                .padding(16)
                .background(
                  Circle()
                    .fill(Color.blue.opacity(0.12))
                )

              Text("No apps selected yet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.primary)

              Text("Pick the apps, categories, or websites to keep quiet during your routine.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
          }
        }
        .frame(maxWidth: .infinity)
      }

      private var hasSelection: Bool {
        !(selection.categories.isEmpty && selection.applications.isEmpty && selection.webDomains.isEmpty)
      }

      @ViewBuilder
      private func summaryRow(
        title: LocalizedStringResource,
        systemName: String,
        color: Color,
        count: Int
      ) -> some View {
        HStack(spacing: 16) {
          Label {
            Text(title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(Color.primary)
          } icon: {
            Image(systemName: systemName)
              .symbolVariant(.fill)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(color)
          }

          Spacer()

          Text("\(count)")
            .font(.title3.weight(.semibold))
            .foregroundStyle(color)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color.opacity(0.12))
        )
      }
    }
  }
}
