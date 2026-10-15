//
//  snapziApp.swift
//  snapzi
//

import SwiftUI
import SwiftData

@main
struct snapziApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerFactory.makeShared()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
