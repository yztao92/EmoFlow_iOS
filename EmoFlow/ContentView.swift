import SwiftUI
import UIKit

// MARK: - 情绪数据模型
struct EmotionData {
    let emotionType: EmotionType
    let assetName: String
    let primary: Color
    let secondary: Color
    
    var name: String {
        return emotionType.emotionDataName
    }
    
    static let emotions: [EmotionData] = [
        // 生气
        EmotionData(
            emotionType: .angry,
            assetName: "Angry",
            primary: ColorManager.Angry.primary,
            secondary: ColorManager.Angry.secondary
        ),
        // 悲伤
        EmotionData(
            emotionType: .sad,
            assetName: "Sad",
            primary: ColorManager.Sad.primary,
            secondary: ColorManager.Sad.secondary
        ),
        // 不开心
        EmotionData(
            emotionType: .unhappy,
            assetName: "Unhappy",
            primary: ColorManager.Unhappy.primary,
            secondary: ColorManager.Unhappy.secondary
        ),
        // 平和
        EmotionData(
            emotionType: .peaceful,
            assetName: "Peaceful",
            primary: ColorManager.Peaceful.primary,
            secondary: ColorManager.Peaceful.secondary
        ),
        // 开心
        EmotionData(
            emotionType: .happy,
            assetName: "Happy",
            primary: ColorManager.Happy.primary,
            secondary: ColorManager.Happy.secondary
        ),
        // 幸福
        EmotionData(
            emotionType: .happiness,
            assetName: "Happiness",
            primary: ColorManager.Happiness.primary,
            secondary: ColorManager.Happiness.secondary
        )
    ]
}

// MARK: - 心心显示组件
struct HeartDisplayView: View {
    let heartCount: Int
    let secondaryColor: Color
    let primaryColor: Color
    let onPlusTap: () -> Void // 添加加号点击回调
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧白色区域 - 心心图标和数量
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(secondaryColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("\(heartCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(secondaryColor)
            }
            .frame(width: 96, height: 36) // 固定宽度92px，高度36px
            .background(secondaryColor.opacity(0.2))
            .cornerRadius(12, corners: [.topLeft, .bottomLeft])
            
            // 右侧青色区域 - 加号按钮
            Button(action: onPlusTap) {
                Image(systemName: "plus")
                    .foregroundColor(primaryColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 36, height: 36) // 固定36x36px
            .background(secondaryColor)
            .cornerRadius(12, corners: [.topRight, .bottomRight])
        }
    }
}

// MARK: - 问候语组件
struct GreetingView: View {
    let greeting: String
    let secondaryColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Text(greeting)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(secondaryColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("你今天过得好吗？")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(secondaryColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - 情绪图标组件
struct EmotionIconView: View {
    let emotion: EmotionData
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(emotion.assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: isSelected ? 300 : 120, height: isSelected ? 300 : 120)
            .opacity(isSelected ? (colorScheme == .dark ? 0.8 : 1.0) : 0.4)
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
    var onSecondaryColorChange: ((Color) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme

    @State private var currentEmotionIndex: Int = 3 // 默认显示平和
    @State private var showHeartInsufficientToast: Bool = false // 心心数量不足的toast状态
    @State private var inputText: String = "" // 输入框内容
    @State private var showFloatingModal: Bool = false // 浮窗显示状态
    @State private var heartCount: Int = 0 // 用户心心数量
    @State private var showSubscriptionModal: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = "" // 订阅弹窗显示状态

    
    private var currentEmotion: EmotionData {
        EmotionData.emotions[currentEmotionIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 顶部状态栏区域
                    HStack {
                        // 左上角心心显示
                        VStack(alignment: .center, spacing: 4) {
                            HeartDisplayView(
                                heartCount: heartCount, 
                                secondaryColor: currentEmotion.secondary, 
                                primaryColor: currentEmotion.primary,
                                onPlusTap: {
                                    showSubscriptionModal = true
                                }
                            )
                            
                            // 恢复时间提示
                            Text("每天00:00将恢复")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(currentEmotion.secondary.opacity(0.8))
                        }
                        .padding(.top, 28) // 调整到28px
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    
                // 问候语区域
                GreetingView(greeting: greeting, secondaryColor: currentEmotion.secondary)
                    .padding(.top, 48) // 调整问候语位置

                // 情绪选择区域
                VStack(spacing: 0) {
                    // 情绪图标和文字区域
                    VStack(spacing: 12) {
                        // 情绪图标
                        EmotionSelectionArea(
                            emotions: EmotionData.emotions,
                            currentIndex: currentEmotionIndex,
                            onEmotionTap: { index in
                                // 点击情绪图标不执行任何操作
                            }
                        )
                        
                        // 情绪文字
                        Text(currentEmotion.emotionType.displayName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(currentEmotion.secondary)
                        //     .multilineTextAlignment(.center)
                    }
                    
                    // 间距120px
                    Spacer().frame(height: 120)
                    
                    // 输入按钮
                    Button(action: {
                        // 点击输入按钮显示浮窗
                        print("🔍 点击输入按钮，显示浮窗")
                        showFloatingModal = true
                    }) {
                        HStack {
                            if inputText.isEmpty {
                                Text("记录此刻的情绪...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(currentEmotion.secondary)
                            } else {
                                Text(inputText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(currentEmotion.secondary.opacity(0.2))
                        .cornerRadius(42)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.top, 68) // 情绪图标和问候语间距68px
                .frame(maxWidth: .infinity) // 确保宽度占满容器

                Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(currentEmotion.primary)
            .onChange(of: currentEmotion.primary) { _, newColor in
                onBackgroundColorChange?(newColor)
            }
            .onChange(of: currentEmotion.secondary) { _, newColor in
                onSecondaryColorChange?(newColor)
            }
            .onAppear {
                onBackgroundColorChange?(currentEmotion.primary)
                onSecondaryColorChange?(currentEmotion.secondary)
                // 更新用户名状态
                currentUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
                // 初始化心心数量
                loadHeartCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: .userNameUpdated)) { _ in
                // 监听用户名更新通知
                currentUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
            }
            .onReceive(NotificationCenter.default.publisher(for: .heartCountUpdated)) { _ in
                // 监听心心数量更新通知
                heartCount = UserDefaults.standard.integer(forKey: "heartCount")
            }
            .onChange(of: currentEmotionIndex) { _, _ in
                // 当情绪切换时，更新颜色和情绪文本
                onBackgroundColorChange?(currentEmotion.primary)
                onSecondaryColorChange?(currentEmotion.secondary)
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
            
            // 心心数量不足的toast
            if showHeartInsufficientToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("心心数量不足，聊天需要至少2个心心")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(18)
                        Spacer()
                    }
                    .padding(.bottom, 120) // 距离底部按钮区域有一定距离
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showHeartInsufficientToast)
            }

        }
        .sheet(isPresented: $showFloatingModal) {
            FloatingModalView(
                currentEmotion: currentEmotion,
                mode: .create,
                isPresented: $showFloatingModal,
                navigationPath: $navigationPath
            )
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showSubscriptionModal) {
            SubscriptionModalView(
                isPresented: $showSubscriptionModal,
                onPaymentSuccess: {
                    showToast(message: "支付成功")
                },
                onRestoreSuccess: {
                    showToast(message: "恢复购买成功")
                }
            )
            .presentationDetents([.height(650), .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .overlay(
            // Toast 提示
            VStack {
                if showToast {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text(toastMessage)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.3), value: showToast)
                }
                Spacer()
            }
            .padding(.top, 20)
        )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 私有方法
    @State private var currentUserName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
        
        // 2秒后自动隐藏 toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
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
        return emotionData.emotionType
    }
    
    private func getEmotionChatMessage(_ emotionType: EmotionType) -> String {
        return emotionType.displayName
    }
    
    // MARK: - 心心数量管理
    private func loadHeartCount() {
        // 从本地存储获取心心数量，如果没有则设置为默认值
        if UserDefaults.standard.object(forKey: "heartCount") == nil {
            UserDefaults.standard.set(20, forKey: "heartCount")
            heartCount = 20
        } else {
            heartCount = UserDefaults.standard.integer(forKey: "heartCount")
        }
        
        // 异步获取最新的心心数量
        Task {
            await fetchLatestHeartCount()
        }
    }
    
    private func fetchLatestHeartCount() async {
        do {
            let latestHeartCount = try await UserHeartService.shared.fetchUserHeart()
            await MainActor.run {
                heartCount = latestHeartCount
            }
        } catch {
            print("获取心心数量失败: \(error)")
            // 如果获取失败，保持本地存储的值
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
