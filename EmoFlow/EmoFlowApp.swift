import SwiftUI

/// EmoFlow 应用入口
/// 负责管理应用的生命周期、登录状态和核心数据环境
@main
struct EmoFlowApp: App {
    /// Core Data 持久化控制器，用于管理本地数据存储
    let persistenceController = PersistenceController.shared
    
    /// 用户登录状态，控制显示主界面还是登录界面
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    // 用户已登录，显示主界面
                    MainView()
                        // 注入 Core Data 上下文，供子视图使用
                        .environment(\.managedObjectContext,
                                     persistenceController.container.viewContext)
                        // 监听登出通知，当收到通知时自动跳转到登录页面
                        .onReceive(NotificationCenter.default.publisher(for: .logout)) { _ in
                            isLoggedIn = false
                        }
                } else {
                    // 用户未登录，显示登录界面
                    AppLoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .onAppear {
                // 应用启动时检查登录状态
                // 如果本地存储中有 userToken，则认为用户已登录
                if let _ = UserDefaults.standard.string(forKey: "userToken") {
                    isLoggedIn = true
                    
                    // APP启动时获取最新的心心数量
                    Task {
                        do {
                            let heartCount = try await UserHeartService.shared.fetchUserHeart()
                            print("🔍 APP启动时获取心心数量: \(heartCount)")
                        } catch {
                            print("⚠️ APP启动时获取心心数量失败: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 通知扩展
/// 定义应用内使用的通知名称
extension Notification.Name {
    /// 登出通知：当用户需要重新登录时发送此通知
    /// 网络服务收到 401 错误时会发送此通知
    static let logout = Notification.Name("logout")
    
    /// 用户名更新通知：当用户名更新时发送此通知
    static let userNameUpdated = Notification.Name("userNameUpdated")
    
    /// 日记更新通知：当日记被编辑或创建时发送此通知
    static let journalUpdated = Notification.Name("journalUpdated")
}
