import SwiftUI

// MARK: - 颜色管理器
struct ColorManager {
    // MARK: - 通用颜色
    static let white = Color.white
    static let clear = Color.clear
    
    // MARK: - 按钮颜色
    static let buttonBackground = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1) : // 深色模式 - 深灰背景
            UIColor(red: 0.16, green: 0.15, blue: 0.16, alpha: 1) // 浅色模式 - 深灰背景
    })
    
    static let buttonText = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1) : // 深色模式 - 浅灰文字
            UIColor(red: 0.90, green: 0.96, blue: 0.94, alpha: 1) // 浅色模式 - 浅灰文字
    })
    
    // MARK: - 情绪颜色 - 生气
    struct Angry {
        static let primary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.39, green: 0.18, blue: 0.09, alpha: 1) : // 深色模式 - 642F17
                UIColor(red: 1, green: 0.52, blue: 0.24, alpha: 1) // 浅色模式 - 鲜艳橙色
        })
        
        static let secondary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 1, green: 0.79, blue: 0.64, alpha: 1) : // 深色模式 - 亮浅橙色
                UIColor(red: 0.47, green: 0.18, blue: 0.02, alpha: 1) // 浅色模式 - 深橙色/棕色
        })
        
        static let light = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.23, green: 0.12, blue: 0.08, alpha: 1) : // 深色模式 - 3A1E14
                UIColor(red: 1, green: 0.94, blue: 0.90, alpha: 1) // 浅色模式 - FFEFE5
        })
    }
    
    // MARK: - 情绪颜色 - 悲伤
    struct Sad {
        static let primary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.20, green: 0.26, blue: 0.40, alpha: 1) : // 深色模式 - 344266
                UIColor(red: 0.55, green: 0.64, blue: 0.93, alpha: 1) // 浅色模式 - 中等蓝色
        })
        
        static let secondary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.79, green: 0.84, blue: 1, alpha: 1) : // 深色模式 - 浅长春花蓝
                UIColor(red: 0.21, green: 0.25, blue: 0.35, alpha: 1) // 浅色模式 - 深蓝色/灰色
        })
        
        static let light = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1) : // 深色模式 - 1F2A3A
                UIColor(red: 0.92, green: 0.94, blue: 1, alpha: 1) // 浅色模式 - EBF0FF
        })
    }
    
    // MARK: - 情绪颜色 - 不开心
    struct Unhappy {
        static let primary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.17, green: 0.30, blue: 0.30, alpha: 1) : // 深色模式 - 2C4C4D
                UIColor(red: 0.63, green: 0.91, blue: 0.92, alpha: 1) // 浅色模式 - 浅青色/青绿色
        })
        
        static let secondary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.70, green: 0.95, blue: 0.95, alpha: 1) : // 深色模式 - 浅青色/水绿色
                UIColor(red: 0.23, green: 0.45, blue: 0.47, alpha: 1) // 浅色模式 - 深青色/绿色
        })
        
        static let light = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.10, green: 0.24, blue: 0.24, alpha: 1) : // 深色模式 - 1A3C3D
                UIColor(red: 0.93, green: 1, blue: 1, alpha: 1) // 浅色模式 - EDFEFF
        })
    }
    
    // MARK: - 情绪颜色 - 平和
    struct Peaceful {
        static let primary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.21, green: 0.27, blue: 0.37, alpha: 1) : // 深色模式 - 35465F
                UIColor(red: 0.87, green: 0.92, blue: 1, alpha: 1) // 浅色模式 - 浅蓝色
        })
        
        static let secondary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.82, green: 0.85, blue: 0.90, alpha: 1) : // 深色模式 - 浅灰蓝色
                UIColor(red: 0.31, green: 0.36, blue: 0.53, alpha: 1) // 浅色模式 - 深蓝色/灰色
        })
        
        static let light = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.17, green: 0.24, blue: 0.29, alpha: 1) : // 深色模式 - 2C3E4A
                UIColor(red: 0.96, green: 0.98, blue: 1, alpha: 1) // 浅色模式 - F5F9FF
        })
    }
    
    // MARK: - 情绪颜色 - 开心
    struct Happy {
        static let primary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.35, green: 0.29, blue: 0.12, alpha: 1) : // 深色模式 - 5A4A1E
                UIColor(red: 0.99, green: 0.87, blue: 0.44, alpha: 1) // 浅色模式 - 亮黄色
        })
        
        static let secondary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.96, green: 0.82, blue: 0.37, alpha: 1) : // 深色模式 - 亮金色
                UIColor(red: 0.40, green: 0.31, blue: 0, alpha: 1) // 浅色模式 - 深黄色/棕色
        })
        
        static let light = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.25, green: 0.23, blue: 0.11, alpha: 1) : // 深色模式 - 3F3A1C
                UIColor(red: 1, green: 0.98, blue: 0.88, alpha: 1) // 浅色模式 - FFFBE0
        })
    }
    
    // MARK: - 情绪颜色 - 幸福
    struct Happiness {
        static let primary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.36, green: 0.18, blue: 0.23, alpha: 1) : // 深色模式 - 5C2F3A
                UIColor(red: 1, green: 0.65, blue: 0.74, alpha: 1) // 浅色模式 - 柔和粉色
        })
        
        static let secondary = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.97, green: 0.67, blue: 0.71, alpha: 1) : // 深色模式 - 浅粉色
                UIColor(red: 0.30, green: 0.20, blue: 0.22, alpha: 1) // 浅色模式 - 深棕色/栗色
        })
        
        static let light = Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.24, green: 0.12, blue: 0.14, alpha: 1) : // 深色模式 - 3D1F24
                UIColor(red: 1, green: 0.94, blue: 0.95, alpha: 1) // 浅色模式 - FFF0F3
        })
    }
    
    // MARK: - 输入框和用户气泡颜色
    static let inputFieldColor = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1) : // 深色模式 - 浅灰色
            UIColor(red: 1, green: 1, blue: 1, alpha: 1) // 浅色模式 - 白色
    })
    
    // MARK: - 系统背景颜色
    static let sysbackground = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1) : // 深色模式 - 131416
            UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1) // 浅色模式 - F4F5F7
    })
    
    // MARK: - 卡片背景颜色
    static let cardbackground = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.11, green: 0.12, blue: 0.13, alpha: 1) : // 深色模式 - 1D1E22
            UIColor(red: 1, green: 1, blue: 1, alpha: 1) // 浅色模式 - FFFFFF
    })
}

// MARK: - 颜色常量扩展
extension Color {
    static let buttonBackground = ColorManager.buttonBackground
    static let buttonText = ColorManager.buttonText
} 