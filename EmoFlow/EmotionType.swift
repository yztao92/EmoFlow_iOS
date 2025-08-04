import Foundation
import SwiftUI

enum EmotionType: String, CaseIterable, Codable {  // ✅ 加上 Codable
    case angry, sad, unhappy, happy, peaceful, happiness
}

extension EmotionType {
    var color: Color {
        switch self {
        case .angry: return Color(red: 1, green: 0.52, blue: 0.24) // FF843E
        case .sad: return Color(red: 0.55, green: 0.64, blue: 0.93) // 8CA4EE
        case .unhappy: return Color(red: 0.63, green: 0.91, blue: 0.92) // A1E7EB
        case .happy: return Color(red: 0.99, green: 0.87, blue: 0.44) // FDDD6F
        case .peaceful: return Color(red: 0.87, green: 0.92, blue: 1) // DFEBFF
        case .happiness: return Color(red: 1, green: 0.65, blue: 0.74) // FFA7BC
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .angry: return Color(red: 1, green: 0.94, blue: 0.90) // FFEFE5
        case .sad: return Color(red: 0.92, green: 0.94, blue: 1) // EBF0FF
        case .unhappy: return Color(red: 0.93, green: 1, blue: 1) // EDFEFF
        case .happy: return Color(red: 1, green: 0.98, blue: 0.93) // FFFBED
        case .peaceful: return Color(red: 0.96, green: 0.97, blue: 1) // F5F9FF
        case .happiness: return Color(red: 1, green: 0.94, blue: 0.95) // FFF0F3
        }
    }

    var iconName: String {
        switch self {
        case .angry: return "Angry"
        case .sad: return "Sad"
        case .unhappy: return "Unhappy"
        case .happy: return "Happy"
        case .peaceful: return "Peaceful"
        case .happiness: return "Happiness"
        }
    }

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .unhappy: return "不开心"
        case .sad: return "悲伤"
        case .angry: return "愤怒"
        case .peaceful: return "平和"
        case .happiness: return "幸福"
        }
    }
}
