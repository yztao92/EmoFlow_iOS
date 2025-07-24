import SwiftUI

@main
struct EmoFlowApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    MainView()
                        .environment(\.managedObjectContext,
                                     persistenceController.container.viewContext)
                        .onReceive(NotificationCenter.default.publisher(for: .logout)) { _ in
                            isLoggedIn = false
                        }
                } else {
                    AppLoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .onAppear {
                // 检查是否已经登录
                if let _ = UserDefaults.standard.string(forKey: "userToken") {
                    isLoggedIn = true
                }
            }
        }
    }
}

// 添加通知扩展
extension Notification.Name {
    static let logout = Notification.Name("logout")
}
