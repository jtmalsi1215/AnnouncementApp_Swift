//
//  AcadvisoryApp.swift
//  Acadvisory
//
//  Created by John Lorenz Malsi on 5/21/26.
//

import SwiftUI
import CoreData

@main
struct AcadvisoryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
