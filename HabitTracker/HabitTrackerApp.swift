//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Chirag on 5/12/22.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
