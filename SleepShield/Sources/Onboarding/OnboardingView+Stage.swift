import SwiftUI
import FamilyControls

extension OnboardingView {
  enum Stage: Equatable {
    case paging
    case blocking
    case morningPreview
    case morning
    case familyAuthorization
    case routineSleepTime
    case routineWakeTime
    case routineSummary
  }

  var titleText: LocalizedStringKey {
    switch stage {
    case .paging:
      return "Struggle to drift off?"
    case .blocking:
      return "We silence the scroll when bedtime hits."
    case .morningPreview:
      return "Here’s the morning shift."
    case .morning:
      return "Wake focused while we keep distractions silent."
    case .familyAuthorization:
      return familyControlsTitle
    case .routineSleepTime:
      return "When do you want to sleep?"
    case .routineWakeTime:
      return "When do you want to wake up?"
    case .routineSummary:
      return "Review your wind-down plan."
    }
  }

  var familyControlsTitle: LocalizedStringKey {
    _ = selectionChangeToken
    switch familyAuthorizationStatus {
    case .approved:
      return hasSelectedBlockedItems
        ? "Apps quiet when your routine starts."
        : "Choose what we keep quiet."
    case .denied:
      return "Enable Screen Time permission in Settings."
    case .notDetermined:
      return "Allow SleepShield Screen Time permission."
    @unknown default:
      return "Allow SleepShield Screen Time permission."
    }
  }

  var ctaButtonTitle: LocalizedStringKey {
    switch stage {
    case .morning:
      return "Continue"
    case .familyAuthorization:
      if isRequestingFamilyAuthorization {
        return "Requesting..."
      }
      if familyAuthorizationStatus == .approved {
        return isCompletingRoutine ? "Finishing..." : "Get Started"
      }
      return "Allow Screen Time Access"
    case .routineSleepTime, .routineWakeTime, .routineSummary:
      return "Continue"
    default:
      return "Continue"
    }
  }

  var isContinueButtonDisabled: Bool {
    switch stage {
    case .familyAuthorization:
      return isRequestingFamilyAuthorization || isCompletingRoutine
    case .routineSummary:
      return repeatWeekday.isEmpty
    default:
      return false
    }
  }

  var hasSelectedBlockedItems: Bool {
    let selection = familyActivitySelectionStore.selection
    return !(selection.categories.isEmpty && selection.applications.isEmpty && selection.webDomains.isEmpty)
  }
}

extension OnboardingView.Stage {
  var isRoutineStage: Bool {
    switch self {
    case .routineSleepTime, .routineWakeTime, .routineSummary:
      return true
    default:
      return false
    }
  }

  var previousStage: OnboardingView.Stage? {
    switch self {
    case .routineWakeTime:
      return .routineSleepTime
    case .routineSummary:
      return .routineWakeTime
    default:
      return nil
    }
  }

  var showsPhoneScene: Bool {
    switch self {
    case .paging, .blocking, .morningPreview, .morning:
      return true
    default:
      return false
    }
  }

  var sensoryFeedback: SensoryFeedback? {
    switch self {
    case .paging:
      return nil
    case .blocking:
      return .error
    case .morningPreview:
      return .selection
    case .morning:
      return .success
    case .familyAuthorization:
      return .impact(weight: .light)
    case .routineSleepTime, .routineWakeTime:
      return .impact(weight: .light)
    case .routineSummary:
      return .selection
    }
  }
}

extension AuthorizationStatus {
  var sensoryFeedback: SensoryFeedback? {
    switch self {
    case .approved:
      return .success
    case .notDetermined:
      return .selection
    case .denied:
      return .error
    @unknown default:
      return nil
    }
  }
}
