//
//  DeviceActivityMonitorExtension.swift
//  SleepShieldDeviceActivityMonitor
//
//  Created by baegteun on 10/12/25.
//

import DeviceActivity
import FamilyControls
import ManagedSettings

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  private let familyActivitySelectionStore = FamilyActivitySelectionStore.standard
  private let settingsStore: ManagedSettingsStore = .init(named: .sleepShieldMonitor)

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    familyActivitySelectionStore.refreshSelection()
    let selection = familyActivitySelectionStore.selection
    settingsStore.shield.applications = selection.applicationTokens
    settingsStore.shield.webDomains = selection.webDomainTokens
    settingsStore.shield.applicationCategories = .specific(selection.categoryTokens, except: [])
    settingsStore.shield.webDomainCategories = .specific(selection.categoryTokens, except: [])
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)

    settingsStore.shield.applications = nil
    settingsStore.shield.applicationCategories = nil
    settingsStore.shield.webDomains = nil
    settingsStore.shield.webDomainCategories = nil
    settingsStore.clearAllSettings()
  }

  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)

    // Handle the event reaching its threshold.
  }

  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)

    // Handle the warning before the interval starts.
  }

  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)

    // Handle the warning before the interval ends.
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)

    // Handle the warning before the event reaches its threshold.
  }
}
