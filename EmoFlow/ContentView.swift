import SwiftUI
import UIKit

struct ContentView: View {
    var onTriggerChat: (EmotionType, String) -> Void
    @Binding var emotions: [EmotionType]

    @State private var selectedEmotion: EmotionType?
    @State private var triggeredEmotion: EmotionType?  // ✅ 用于最终触发
    @State private var isHolding = false
    @State private var didTrigger = false

    @State private var fillOpacity: Double = 0
    @State private var heartScale: CGFloat = 1.0

    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    @State private var feedbackTimer: Timer?
    @State private var vibrationInterval: Double = 0

    @State private var scaleFillTimer: Timer?
    @State private var animationStart: Date?

    private let pressDuration: Double = 5.0
    private let emotionOrder: [EmotionType] = [.happy, .tired, .sad, .angry]

    // 新增：记录长按开始和结束时间
    @State private var pressStartTime: Date?

    var body: some View {
        VStack {
            Text(greeting)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading).padding(.top, 8)

            Spacer()

            ZStack {
                HeartShape()
                    .stroke(selectedEmotion?.color ?? .gray, lineWidth: 3)
                    .frame(width: 200, height: 180)
                    .scaleEffect(heartScale)

                HeartShape()
                    .fill(selectedEmotion?.color ?? .clear)
                    .frame(width: 200, height: 180)
                    .opacity(fillOpacity)
                    .scaleEffect(heartScale)
            }

            Spacer()

            HStack(spacing: 32) {
                ForEach(emotionOrder, id: \ .self) { emotion in
                    EmotionBubble(emotion: emotion)
                        .opacity(selectedEmotion == nil || selectedEmotion == emotion ? 1 : 0.4)
                        .allowsHitTesting(selectedEmotion == nil || selectedEmotion == emotion)
                        .gesture(
                            LongPressGesture(minimumDuration: pressDuration)
                                .onChanged { _ in
                                    guard !isHolding else { return }
                                    isHolding = true
                                    didTrigger = false
                                    selectedEmotion = emotion     // ✅ 提前设置用于动画
                                    triggeredEmotion = emotion    // ✅ 同时记录最终触发的情绪
                                    pressStartTime = Date()       // 记录长按开始时间
                                    startVibration()
                                    startHeartAnimation()
                                }
                                .onEnded { _ in
                                    guard isHolding && !didTrigger else { return }
                                    let pressEndTime = Date()
                                    let duration = pressStartTime != nil ? pressEndTime.timeIntervalSince(pressStartTime!) : 0
                                    let percent = min(1.0, duration / pressDuration)
                                    let message = descriptionForEmotion(emotion, percent: percent)
                                    print("[LOG] 长按情绪: \(message)")
                                    onTriggerChat(emotion, message)
                                    didTrigger = true
                                    isHolding = false
                                    resetState()
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { _ in
                                    guard isHolding && !didTrigger else { return }
                                    let pressEndTime = Date()
                                    let duration = pressStartTime != nil ? pressEndTime.timeIntervalSince(pressStartTime!) : 0
                                    let percent = min(1.0, duration / pressDuration)
                                    let message = descriptionForEmotion(emotion, percent: percent)
                                    print("[LOG] 拖动情绪: \(message)")
                                    onTriggerChat(emotion, message)
                                    didTrigger = true
                                    isHolding = false
                                    resetState()
                                }
                        )
                }
            }
            .padding(.bottom, 64)
        }
        .padding()
        .onAppear(perform: resetState)
    }

    private func startVibration() {
        feedbackTimer?.invalidate()
        vibrationInterval = pressDuration / 8
        heavyFeedback.prepare()
        scheduleVibration()
    }

    private func scheduleVibration() {
        guard isHolding && !didTrigger else { return }
        heavyFeedback.impactOccurred()
        vibrationInterval = max(0.05, vibrationInterval * 0.7)
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: vibrationInterval, repeats: false) { _ in
            scheduleVibration()
        }
    }

    private func startHeartAnimation() {
        animationStart = Date()
        scaleFillTimer?.invalidate()
        scaleFillTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            guard isHolding && !didTrigger, let start = animationStart else {
                timer.invalidate()
                return
            }
            let progress = min(Date().timeIntervalSince(start) / pressDuration, 1)
            heartScale  = 1 + CGFloat(progress)
            fillOpacity = progress
            if progress >= 1 { timer.invalidate() }
        }
    }

    private func stopAll() {
        feedbackTimer?.invalidate()
        scaleFillTimer?.invalidate()
    }

    private func resetState() {
        selectedEmotion = nil
        triggeredEmotion = nil
        fillOpacity     = 0
        heartScale      = 1
        isHolding       = false
        didTrigger      = false
        stopAll()
        pressStartTime  = nil
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "上午好，现在心里装着什么情绪啊？"
        case 12..<18: return "下午好，现在心里装着什么情绪啊？"
        default:     return "晚上好，现在心里装着什么情绪啊？"
        }
    }

    // 根据情绪类型返回中文
    private func emotionTextForType(_ type: EmotionType) -> String {
        switch type {
        case .angry: return "生气"
        case .sad: return "难过"
        case .tired: return "疲惫"
        case .happy: return "开心"
        }
    }
    // 根据情绪类型返回值文案
    private func valueTextForType(_ type: EmotionType) -> String {
        switch type {
        case .angry: return "怒气值"
        case .sad: return "悲伤值"
        case .tired: return "疲惫值"
        case .happy: return "开心值"
        }
    }

    private func descriptionForEmotion(_ type: EmotionType, percent: Double) -> String {
        let percentValue = Int(percent * 100)
        let base: String
        switch percentValue {
        case 0..<25:
            base = "我现在有点"
        case 25..<50:
            base = "我现在挺"
        case 50..<75:
            base = "我现在相当"
        default:
            base = "我现在"
        }
        let emo = emotionTextForType(type)
        if percentValue >= 75 {
            return "\(base) \(emo) 炸了"
        } else {
            return "\(base) \(emo)"
        }
    }
}
