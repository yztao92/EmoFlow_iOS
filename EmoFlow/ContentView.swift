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
            name: "生气",
            assetName: "Angry",
            color: Color(red: 1, green: 0.52, blue: 0.24),
            backgroundColor: Color(red: 1, green: 0.94, blue: 0.90), // FFFEF5
            cardBackgroundColor: Color(red: 1, green: 0.52, blue: 0.24), // FF843E
            titleColor: Color(red: 0.47, green: 0.18, blue: 0.02), // 782E04
            emotionTextColor: Color(red: 0.57, green: 0.22, blue: 0.01), // 913704
            paginationColor: Color(red: 1, green: 0.52, blue: 0.24) // FF843E
        ),
        // 悲伤
        EmotionData(
            name: "悲伤",
            assetName: "Sad",
            color: Color(red: 0.55, green: 0.64, blue: 0.93),
            backgroundColor: Color(red: 0.92, green: 0.94, blue: 1), // EBF0FF
            cardBackgroundColor: Color(red: 0.55, green: 0.64, blue: 0.93), // 8CA4EE
            titleColor: Color(red: 0.19, green: 0.23, blue: 0.33), // 313A54
            emotionTextColor: Color(red: 0.21, green: 0.25, blue: 0.35), // 363F59
            paginationColor: Color(red: 0.55, green: 0.64, blue: 0.93) // 8CA4EE
        ),
        // 不开心
        EmotionData(
            name: "不开心",
            assetName: "Unhappy",
            color: Color(red: 0.63, green: 0.91, blue: 0.92),
            backgroundColor: Color(red: 0.93, green: 1, blue: 1), // EDFEFF
            cardBackgroundColor: Color(red: 0.63, green: 0.91, blue: 0.92), // A1E7EB
            titleColor: Color(red: 0.19, green: 0.23, blue: 0.33), // 313A54
            emotionTextColor: Color(red: 0.21, green: 0.25, blue: 0.35), // 363F59
            paginationColor: Color(red: 0.63, green: 0.91, blue: 0.92) // A1E7EB
        ),
        // 平和
        EmotionData(
            name: "平和",
            assetName: "Peaceful",
            color: Color(red: 0.36, green: 0.42, blue: 0.63),
            backgroundColor: Color(red: 0.96, green: 0.98, blue: 1), // F5F9FF
            cardBackgroundColor: Color(red: 0.87, green: 0.92, blue: 1), // DFEBFF
            titleColor: Color(red: 0.31, green: 0.36, blue: 0.53), // 505D87
            emotionTextColor: Color(red: 0.36, green: 0.42, blue: 0.63), // 5C6CA1
            paginationColor: Color(red: 0.87, green: 0.92, blue: 1) // DFEBFF
        ),
        // 开心
        EmotionData(
            name: "开心",
            assetName: "Happy",
            color: Color(red: 0.99, green: 0.87, blue: 0.44),
            backgroundColor: Color(red: 1, green: 0.98, blue: 0.93), // FFFBED
            cardBackgroundColor: Color(red: 0.99, green: 0.87, blue: 0.44), // FDDD6F
            titleColor: Color(red: 0.40, green: 0.31, blue: 0), // 664F00
            emotionTextColor: Color(red: 0.39, green: 0.33, blue: 0.13), // 635522
            paginationColor: Color(red: 0.99, green: 0.87, blue: 0.44) // FDDD6F
        ),
        // 幸福
        EmotionData(
            name: "幸福",
            assetName: "Happiness",
            color: Color(red: 0.63, green: 0.91, blue: 0.92),
            backgroundColor: Color(red: 1, green: 0.94, blue: 0.95), // FFF0F3
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
        HStack {
            Text(greeting)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(titleColor)
                .padding(.leading, 20)
            Spacer()
        }
    }
}

// MARK: - 情绪图标组件
struct EmotionIconView: View {
    let emotion: EmotionData
    
    var body: some View {
        ZStack {
            Image(emotion.assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: emotion.assetName)
        }
        .frame(height: 219)
    }
}

// MARK: - 情绪卡片组件
struct EmotionCardView: View {
    let emotion: EmotionData
    
    var body: some View {
        VStack(spacing: 20) {
            // 卡片标题
            Text("现在的感觉是")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(emotion.titleColor)
            
            // 情绪图标
            EmotionIconView(emotion: emotion)
            
            // 情绪名称
            Text(emotion.name)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(emotion.emotionTextColor)
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 6, trailing: 0))
        }
        .padding(EdgeInsets(top: 36, leading: 0, bottom: 16, trailing: 0))
        .frame(maxWidth: .infinity)
        .background(emotion.cardBackgroundColor)
        .cornerRadius(24)
        .padding(.horizontal, 20)
    }
}

// MARK: - 分页指示器组件
struct PaginationView: View {
    let emotions: [EmotionData]
    let currentIndex: Int
    let onTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Spacer()
            ForEach(0..<emotions.count, id: \.self) { index in
                Circle()
                    .fill(emotions[index].paginationColor)
                    .frame(width: index == currentIndex ? 24 : 12, height: index == currentIndex ? 24 : 12)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    .onTapGesture {
                        onTap(index)
                    }
            }
            Spacer()
        }
    }
}

// MARK: - 情绪弹窗组件
struct EmotionModalView: View {
    let emotion: EmotionData
    @Binding var isPresented: Bool
    let onChatButtonTapped: () -> Void
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // 弹窗内容
            VStack(spacing: 24) {
                // 情绪卡片
                EmotionCardView(emotion: emotion)
                    .scaleEffect(1.1) // 稍微放大一点
                
                // 和我聊聊按钮
                Button(action: {
                    isPresented = false // 关闭弹窗
                    onChatButtonTapped() // 触发聊天
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("和我聊聊")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(emotion.cardBackgroundColor)
                    .cornerRadius(25)
                    .shadow(color: emotion.cardBackgroundColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.clear)
    }
}

// MARK: - 主视图
struct ContentView: View {
    var onTriggerChat: (EmotionType, String) -> Void
    @Binding var emotions: [EmotionType]
    
    @State private var currentEmotionIndex: Int = 3 // 默认显示平和
    @State private var showEmotionModal: Bool = false // 控制弹窗显示
    
    private var currentEmotion: EmotionData {
        EmotionData.emotions[currentEmotionIndex]
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 问候语
                GreetingView(greeting: greeting, titleColor: currentEmotion.titleColor)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // 情绪卡片
                    EmotionCardView(emotion: currentEmotion)
                    
                    // 分页指示器
                    PaginationView(
                        emotions: EmotionData.emotions,
                        currentIndex: currentEmotionIndex,
                        onTap: { index in
                            // 触发震动反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentEmotionIndex = index
                            }
                        }
                    )
                }
                
                Spacer()
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(currentEmotion.backgroundColor)
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    let horizontalThreshold: CGFloat = 30 // 水平方向的阈值
                    
                    // 判断主要滑动方向
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)
                    
                    if verticalDistance > horizontalDistance {
                        // 垂直滑动为主
                        if value.translation.height < -threshold {
                            // 向上滑动显示弹窗
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmotionModal = true
                            }
                        }
                    } else {
                        // 水平滑动为主
                        if value.translation.width > horizontalThreshold {
                            switchToPreviousEmotion()
                        } else if value.translation.width < -horizontalThreshold {
                            switchToNextEmotion()
                        }
                    }
                }
        )
        .fullScreenCover(isPresented: $showEmotionModal) {
            EmotionModalView(
                emotion: currentEmotion,
                isPresented: $showEmotionModal,
                onChatButtonTapped: {
                    // 触发聊天功能
                    let emotionType = convertEmotionDataToEmotionType(currentEmotion)
                    let chatMessage = "我现在感觉到 \(currentEmotion.name)"
                    onTriggerChat(emotionType, chatMessage)
                }
            )
        }
    }
    
    // MARK: - 私有方法
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
        
        return "\(timeGreeting), Nick"
    }
    
    private func switchToNextEmotion() {
        // 触发震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentEmotionIndex = (currentEmotionIndex + 1) % EmotionData.emotions.count
        }
    }
    
    private func switchToPreviousEmotion() {
        // 触发震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentEmotionIndex = (currentEmotionIndex - 1 + EmotionData.emotions.count) % EmotionData.emotions.count
        }
    }
    
    // 转换EmotionData到EmotionType
    private func convertEmotionDataToEmotionType(_ emotion: EmotionData) -> EmotionType {
        switch emotion.name {
        case "生气":
            return .angry
        case "悲伤":
            return .sad
        case "不开心":
            return .unhappy
        case "平和":
            return .peaceful
        case "开心":
            return .happy
        case "幸福":
            return .happiness
        default:
            return .happy
        }
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            onTriggerChat: { _, _ in },
            emotions: .constant([])
        )
    }
}