//
//  SleepShieldApp.swift
//  SleepShield
//
//  Created by baegteun on 9/20/25.
//

import Firebase
import SwiftData
import SwiftUI

@main
struct SleepShieldApp: App {
  @StateObject private var familyActivitySelectionStore = FamilyActivitySelectionStore()
  @State private var alarmScheduler = AlarmScheduler()
  @AppStorage("hasCompletedAlarmOnboarding") private var hasCompletedAlarmOnboarding = false

  private let sharedModelContainer: ModelContainer = {
    let schema = Schema([
      SleepTimeline.self
    ])
    let modelConfiguration = ModelConfiguration(
      "SleepShield",
      schema: schema,
      isStoredInMemoryOnly: false,
      allowsSave: true,
      groupContainer: .identifier("group.msg.SleepShield"),
      cloudKitDatabase: .none
    )
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if hasCompletedAlarmOnboarding {
          NavigationStack {
            HomeView()
          }
        } else {
          OnboardingView {
            withAnimation {
              hasCompletedAlarmOnboarding = true
            }
          }
        }
      }
      .animation(.default, value: hasCompletedAlarmOnboarding)
      .environment(\.familyActivitySelectionStore, familyActivitySelectionStore)
      .environment(\.alarmScheduler, alarmScheduler)
      .environmentObject(familyActivitySelectionStore)
    }
    .modelContainer(sharedModelContainer)
  }
}
