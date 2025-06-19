//
//  EmoFlowApp.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/19.
//

import SwiftUI

@main
struct EmoFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
