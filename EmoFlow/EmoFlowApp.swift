import SwiftUI

@main
struct EmoFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
        }
    }
}
