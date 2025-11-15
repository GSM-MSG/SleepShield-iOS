import Combine
import FamilyControls
import Foundation
import SwiftUI

final class FamilyActivitySelectionStore: ObservableObject {
  private let defaults: UserDefaults
  private let defaultsKey: String
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  @Published private(set) var selection: FamilyActivitySelection

  static let standard = FamilyActivitySelectionStore()

  init(
    defaults: UserDefaults = .sleepShieldSelectionStore,
    defaultsKey: String = "sleepshield.familyActivitySelection",
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.defaults = defaults
    self.defaultsKey = defaultsKey
    self.encoder = encoder
    self.decoder = decoder

    let initialSelection = Self.loadSelection(
      using: defaults,
      decoder: decoder,
      key: defaultsKey
    )
    self.selection = initialSelection
  }

  func updateSelection(_ newSelection: FamilyActivitySelection) {
    selection = newSelection
    persistSelection()
  }

  var selectionBinding: Binding<FamilyActivitySelection> {
    Binding(
      get: { self.selection },
      set: { [weak self] newSelection in
        guard let self else { return }
        self.updateSelection(newSelection)
      }
    )
  }

  private func persistSelection() {
    do {
      let encoded = try encoder.encode(selection)
      defaults.set(encoded, forKey: defaultsKey)
    } catch {
      assertionFailure("Failed to encode family activity selection: \(error)")
    }
  }

  private static func loadSelection(
    using defaults: UserDefaults,
    decoder: JSONDecoder,
    key: String
  ) -> FamilyActivitySelection {
    guard let data = defaults.data(forKey: key) else {
      return FamilyActivitySelection()
    }

    do {
      return try decoder.decode(FamilyActivitySelection.self, from: data)
    } catch {
      assertionFailure("Failed to decode saved family activity selection: \(error)")
      return FamilyActivitySelection()
    }
  }
}
