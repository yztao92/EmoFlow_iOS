import SwiftUI
import UIKit

// MARK: - 颜色常量
extension Color {
    static let buttonBackground = Color(red: 0.16, green: 0.15, blue: 0.16)
    static let buttonText = Color(red: 0.90, green: 0.96, blue: 0.94)
}



// MARK: - 情绪数据模型
struct EmotionData {
    let name: String
    let assetName: String
    let color: Color
    let backgroundColor: Color
    let cardBackgroundColor: Color
    let titleColor: Color
    let emotionTextColor: Color
    let paginationColor: Color
    
    static let emotions: [EmotionData] = [
        // 生气
        EmotionData(
            name: "哼，气死我得了",
            assetName: "Angry",
            color: Color(red: 1, green: 0.52, blue: 0.24),
            backgroundColor: Color(red: 1, green: 0.52, blue: 0.24), // FF843E
            cardBackgroundColor: Color(red: 1, green: 0.52, blue: 0.24), // FF843E
            titleColor: Color(red: 0.47, green: 0.18, blue: 0.02), // 782E04
            emotionTextColor: Color(red: 0.57, green: 0.22, blue: 0.01), // 913704
            paginationColor: Color(red: 1, green: 0.52, blue: 0.24) // FF843E
        ),
        // 悲伤
        EmotionData(
            name: "唉，哭了",
            assetName: "Sad",
            color: Color(red: 0.55, green: 0.64, blue: 0.93),
            backgroundColor: Color(red: 0.55, green: 0.64, blue: 0.93), // 8CA4EE
            cardBackgroundColor: Color(red: 0.55, green: 0.64, blue: 0.93), // 8CA4EE
            titleColor: Color(red: 0.19, green: 0.23, blue: 0.33), // 313A54
            emotionTextColor: Color(red: 0.21, green: 0.25, blue: 0.35), // 363F59
            paginationColor: Color(red: 0.55, green: 0.64, blue: 0.93) // 8CA4EE
        ),
        // 不开心
        EmotionData(
            name: "今天我是不大高兴了",
            assetName: "Unhappy",
            color: Color(red: 0.63, green: 0.91, blue: 0.92),
            backgroundColor: Color(red: 0.63, green: 0.91, blue: 0.92), // A1E7EB
            cardBackgroundColor: Color(red: 0.63, green: 0.91, blue: 0.92), // A1E7EB
            titleColor: Color(red: 0.23, green: 0.45, blue: 0.47), // 3A7478
            emotionTextColor: Color(red: 0.21, green: 0.25, blue: 0.35), // 363F59
            paginationColor: Color(red: 0.63, green: 0.91, blue: 0.92) // A1E7EB
        ),
        // 平和
        EmotionData(
            name: "无风无浪的一天",
            assetName: "Peaceful",
            color: Color(red: 0.36, green: 0.42, blue: 0.63),
            backgroundColor: Color(red: 0.87, green: 0.92, blue: 1), // DFEBFF
            cardBackgroundColor: Color(red: 0.87, green: 0.92, blue: 1), // DFEBFF
            titleColor: Color(red: 0.31, green: 0.36, blue: 0.53), // 505D87
            emotionTextColor: Color(red: 0.36, green: 0.42, blue: 0.63), // 5C6CA1
            paginationColor: Color(red: 0.87, green: 0.92, blue: 1) // DFEBFF
        ),
        // 开心
        EmotionData(
            name: "今天蛮开心的",
            assetName: "Happy",
            color: Color(red: 0.99, green: 0.87, blue: 0.44),
            backgroundColor: Color(red: 0.99, green: 0.87, blue: 0.44), // FDDD6F
            cardBackgroundColor: Color(red: 0.99, green: 0.87, blue: 0.44), // FDDD6F
            titleColor: Color(red: 0.40, green: 0.31, blue: 0), // 664F00
            emotionTextColor: Color(red: 0.39, green: 0.33, blue: 0.13), // 635522
            paginationColor: Color(red: 0.99, green: 0.87, blue: 0.44) // FDDD6F
        ),
        // 幸福
        EmotionData(
            name: "满满的幸福",
            assetName: "Happiness",
            color: Color(red: 0.63, green: 0.91, blue: 0.92),
            backgroundColor: Color(red: 1, green: 0.65, blue: 0.74), // FFA7BC
            cardBackgroundColor: Color(red: 1, green: 0.65, blue: 0.74), // FFA7BC
            titleColor: Color(red: 0.30, green: 0.20, blue: 0.22), // 4D3238
            emotionTextColor: Color(red: 0.40, green: 0.26, blue: 0.29), // 66424B
            paginationColor: Color(red: 1, green: 0.65, blue: 0.74) // FFA7BC
        )
    ]
}

// MARK: - 问候语组件
struct GreetingView: View {
    let greeting: String
    let titleColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Text(greeting)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("你今天过得好吗？")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}



// MARK: - 情绪图标组件
struct EmotionIconView: View {
    let emotion: EmotionData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Image(emotion.assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: isSelected ? 280 : 120, height: isSelected ? 280 : 120)
            .opacity(isSelected ? 1.0 : 0.4)
    }
}

// MARK: - 情绪选择区域
struct EmotionSelectionArea: View {
    let emotions: [EmotionData]
    let currentIndex: Int
    let onEmotionTap: (Int) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 左侧未选中的情绪图标
                HStack {
                    EmotionIconView(
                        emotion: emotions[(currentIndex - 1 + emotions.count) % emotions.count],
                        isSelected: false
                    ) {
                        onEmotionTap((currentIndex - 1 + emotions.count) % emotions.count)
                    }
                    .offset(x: -60)
                    
                    Spacer()
                }
                
                // 中央选中的情绪图标
                HStack {
                    Spacer()
                    EmotionIconView(
                        emotion: emotions[currentIndex],
                        isSelected: true
                    ) {
                        onEmotionTap(currentIndex)
                    }
                    Spacer()
                }
                
                // 右侧未选中的情绪图标
                HStack {
                    Spacer()
                    EmotionIconView(
                        emotion: emotions[(currentIndex + 1) % emotions.count],
                        isSelected: false
                    ) {
                        onEmotionTap((currentIndex + 1) % emotions.count)
                    }
                    .offset(x: 60)
                }
            }
            .frame(width: geometry.size.width)
            .clipped()
        }
        .frame(height: 280)
        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: currentIndex)
    }
}

// MARK: - 主内容视图
struct ContentView: View {
    @Binding var navigationPath: NavigationPath
    var onBackgroundColorChange: ((Color) -> Void)? = nil

    @State private var currentEmotionIndex: Int = 3 // 默认显示平和
    
    private var currentEmotion: EmotionData {
        EmotionData.emotions[currentEmotionIndex]
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 问候语区域
                GreetingView(greeting: greeting, titleColor: currentEmotion.titleColor)
                    .padding(.top, 120) // 问候语到右上角图标间距56px（64px + 56px）

                // 情绪选择区域
                VStack(spacing: 20) {
                    // 情绪图标
                    EmotionSelectionArea(
                        emotions: EmotionData.emotions,
                        currentIndex: currentEmotionIndex,
                        onEmotionTap: { index in
                            // 点击情绪图标不执行任何操作
                        }
                    )
                    
                    // 情绪文字
                    Text(currentEmotion.name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(currentEmotion.emotionTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 68) // 情绪图标和问候语间距68px
                .frame(maxWidth: .infinity) // 确保宽度占满容器

                Spacer()
                
                // 底部按钮区域
                HStack(spacing: 16) {
                    // 记录一下按钮（outline样式）
                    Button(action: {
                        let emotionType = convertEmotionDataToEmotionType(currentEmotion)
                        navigationPath.append(AppRoute.journalCreate(emotion: emotionType))
                    }) {
                        Text("记录一下")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(currentEmotion.titleColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(currentEmotion.titleColor, lineWidth: 1.5)
                            )
                    }
                    
                    // 和我聊聊按钮（filled样式）
                    Button(action: {
                        let emotionType = convertEmotionDataToEmotionType(currentEmotion)
                        let chatMessage = getEmotionChatMessage(emotionType)
                        navigationPath.append(AppRoute.chat(emotion: emotionType, initialMessage: chatMessage))
                    }) {
                        Text("和我聊聊")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(currentEmotion.titleColor)
                            )
                    }
                }
                .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(currentEmotion.backgroundColor)
            .onChange(of: currentEmotion.backgroundColor) { _, newColor in
                onBackgroundColorChange?(newColor)
            }
            .onAppear {
                onBackgroundColorChange?(currentEmotion.backgroundColor)
                // 更新用户名状态
                currentUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
            }
            .onReceive(NotificationCenter.default.publisher(for: .userNameUpdated)) { _ in
                // 监听用户名更新通知
                currentUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 手势识别，但不触发震动反馈
                        // 避免干扰用户的情绪体验
                    }
                    .onEnded { value in
                        let horizontalThreshold: CGFloat = 80
                        
                        // 只保留水平滑动切换情绪的功能
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        
                        // 判断主要移动方向
                        if horizontalDistance > verticalDistance {
                            // 水平移动为主
                            if value.translation.width > horizontalThreshold {
                                // 向右滑动，切换到上一个情绪
                                switchToPreviousEmotion()
                            } else if value.translation.width < -horizontalThreshold {
                                // 向左滑动，切换到下一个情绪
                                switchToNextEmotion()
                            }
                        }
                    }
            )

        }
    }

    // MARK: - 私有方法
    @State private var currentUserName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        
        switch hour {
        case 5..<12:
            timeGreeting = "上午好"
        case 12..<18:
            timeGreeting = "下午好"
        default:
            timeGreeting = "晚上好"
        }
        
        // 使用当前用户名状态，如果为空则只显示时间问候
        let trimmedUserName = currentUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedUserName.isEmpty {
            return "\(timeGreeting), \(trimmedUserName)～"
        } else {
            return "\(timeGreeting)～"
        }
    }
    
    private func switchToNextEmotion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            currentEmotionIndex = (currentEmotionIndex + 1) % EmotionData.emotions.count
        }
        
        // 动画完成后触发情绪震动反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            triggerEmotionHaptic()
        }
    }
    
    private func switchToPreviousEmotion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            currentEmotionIndex = (currentEmotionIndex - 1 + EmotionData.emotions.count) % EmotionData.emotions.count
        }
        
        // 动画完成后触发情绪震动反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            triggerEmotionHaptic()
        }
    }
    
    // 根据情绪类型触发不同的震动模式
    private func triggerEmotionHaptic() {
        let emotionType = convertEmotionDataToEmotionType(currentEmotion)
        
        switch emotionType {
        case .angry:
            // 愤怒：节奏密集的重击感，有冲撞感 - 1.2秒
            // 模拟：捶桌或心跳飙升的感觉
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            heavyFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                heavyFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                heavyFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heavyFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                heavyFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                heavyFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                heavyFeedback.impactOccurred()
            }
            
        case .sad:
            // 悲伤：一段慢沉的拖尾，像低声叹息 - 2.0秒
            // 模拟：心脏隐隐作痛，或者一阵忧郁
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            mediumFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mediumFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                lightFeedback.impactOccurred()
            }
            
        case .unhappy:
            // 不开心：情绪下沉的顿感 - 1.5秒
            // 模拟：一阵失落或压抑的触感
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            mediumFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mediumFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mediumFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                lightFeedback.impactOccurred()
            }
            
        case .peaceful:
            // 平和：像温柔的波浪或呼吸节奏 - 2.0秒
            // 模拟：深呼吸、平静水面
            let softFeedback = UIImpactFeedbackGenerator(style: .soft)
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            softFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                softFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                softFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                softFeedback.impactOccurred()
            }
            
        case .happy:
            // 开心：欢快跃动，像蹦跳的小球 - 1.2秒
            // 模拟：跳跃感、轻盈活泼
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                lightFeedback.impactOccurred()
            }
            
        case .happiness:
            // 幸福：温暖、慢慢流淌的情绪波 - 2.0秒
            // 模拟：被幸福包裹的稳定触感
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            lightFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                mediumFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mediumFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                mediumFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                lightFeedback.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                lightFeedback.impactOccurred()
            }
        }
    }
    
    private func convertEmotionDataToEmotionType(_ emotionData: EmotionData) -> EmotionType {
        switch emotionData.name {
        case "哼，气死我得了":
            return .angry
        case "唉，哭了":
            return .sad
        case "今天我是不大高兴了":
            return .unhappy
        case "无风无浪的一天":
            return .peaceful
        case "今天蛮开心的":
            return .happy
        case "满满的幸福":
            return .happiness
        default:
            return .peaceful
        }
    }
    
    private func getEmotionChatMessage(_ emotionType: EmotionType) -> String {
        switch emotionType {
        case .angry:
            return "我现在感觉到很生气"
        case .sad:
            return "我现在感觉到很悲伤"
        case .unhappy:
            return "我现在感觉到不开心"
        case .peaceful:
            return "我现在心情感觉到很平和"
        case .happy:
            return "我现在感觉到蛮开心的"
        case .happiness:
            return "我现在感觉到很幸福"
        }
    }
    

}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
