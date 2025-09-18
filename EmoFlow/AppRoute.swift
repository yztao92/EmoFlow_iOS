import Foundation
import SwiftUI

/// 应用路由枚举
/// 定义所有可能的导航路径，确保类型安全
enum AppRoute: Hashable {
    /// 聊天页面
    /// - emotion: 当前情绪类型
    /// - initialMessage: 初始消息
    case chat(emotion: EmotionType, initialMessage: String)
    
    /// 创建日记页面
    /// - emotion: 当前情绪类型
    /// - emotionText: 当前显示的情绪文本
    case journalCreate(emotion: EmotionType, emotionText: String)
    
    /// 编辑日记页面
    /// - record: 日记记录
    case journalEdit(record: ChatRecord)
    
    /// 日记列表页面
    case journalList
    
    /// 日记详情页面
    /// - id: 日记ID
    case journalDetail(id: Int)
    
    /// 设置页面
    case settings
}

// MARK: - 路由扩展
extension AppRoute {
    /// 获取路由的标题（用于调试）
    var title: String {
        switch self {
        case .chat:
            return "聊天"
        case .journalCreate:
            return "创建日记"
        case .journalEdit:
            return "编辑日记"
        case .journalList:
            return "日记列表"
        case .journalDetail:
            return "日记详情"
        case .settings:
            return "设置"
        }
    }
} 