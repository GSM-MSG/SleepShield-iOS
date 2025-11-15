import SwiftUI

private struct FamilyActivitySelectionStoreKey: EnvironmentKey {
  @MainActor static var defaultValue = FamilyActivitySelectionStore.standard
}

extension EnvironmentValues {
  var familyActivitySelectionStore: FamilyActivitySelectionStore {
    get { self[FamilyActivitySelectionStoreKey.self] }
    set { self[FamilyActivitySelectionStoreKey.self] = newValue }
  }
}
