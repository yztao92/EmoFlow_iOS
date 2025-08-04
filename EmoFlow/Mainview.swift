//
//  MainView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct MainView: View {
    @State private var emotions: [EmotionType] = []
    @State private var initialMessage: String = ""
    @State private var sessionID: String = UUID().uuidString
    @State private var chatActive: Bool = false
    @State private var selectedRecord: ChatRecord? = nil
    @State private var records: [ChatRecord] = RecordManager.loadAll()
    @State private var showLogoutAlert = false
    @State private var currentBackgroundColor: Color = Color(.systemGroupedBackground)
    @State private var navigateToJournalId: Int? = nil // 控制导航到日记详情
    @State private var showJournalList = false // 控制显示日记列表
    @State private var showSettings = false // 控制显示设置页面
    @Namespace private var tabAnim

    var body: some View {
        NavigationStack {
            ZStack {
                // 主要内容 - 情绪选择页面
                ContentView(
                    onTriggerChat: { emotion, message in
                        self.emotions = [emotion]
                        self.initialMessage = message
                        self.sessionID = UUID().uuidString
                        DispatchQueue.main.async {
                            self.chatActive = true
                        }
                    },
                    emotions: $emotions,
                    onBackgroundColorChange: { color in
                        self.currentBackgroundColor = color
                    },
                    navigateToJournalId: $navigateToJournalId,
                    onNavigateToJournal: { journalId in
                        // 显示日记列表并导航到详情
                        self.navigateToJournalId = journalId
                        self.showJournalList = true
                    }
                )
                .transition(.opacity)
                
                // 右上角按钮组
                VStack {
                    HStack {
                        Spacer()
                        
                        // 日记按钮
                        Button(action: {
                            showJournalList = true
                        }) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(getIconColor())
                                .frame(width: 44, height: 44)
                        }
                        
                        // 设置按钮
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(getIconColor())
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 20) // 和屏幕右边有20px的间距
                    }
                    .padding(.top, 20) // 距离顶部20px
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(.keyboard)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            
            // 导航到日记详情
            .navigationDestination(item: $selectedRecord) { record in
                ChatrecordDetailView(record: record, onSave: { newSummary in
                    record.summary = newSummary
                    RecordManager.saveAll(records)
                })
            }
            
            // 导航到聊天页面
            .navigationDestination(isPresented: $chatActive) {
                ChatView(
                    emotions: $emotions,
                    initialMessage: initialMessage,
                    sessionID: sessionID,
                    selectedRecord: $selectedRecord
                )
            }
            
            // 导航到日记列表
            .navigationDestination(isPresented: $showJournalList) {
                ChatHistoryView(
                    selectedRecord: $selectedRecord,
                    navigateToJournalId: navigateToJournalId,
                    onNavigationComplete: {
                        // 导航完成后清除状态
                        navigateToJournalId = nil
                    }
                )
            }
            
            // 导航到设置页面
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    private func getIconColor() -> Color {
        // 根据当前背景色确定图标颜色
        if currentBackgroundColor == Color(red: 0.87, green: 0.92, blue: 1) {
            // 平和情绪 - DFEBFF背景
            return Color(red: 0.31, green: 0.36, blue: 0.53) // 505D87
        } else if currentBackgroundColor == Color(red: 0.99, green: 0.87, blue: 0.44) {
            // 开心情绪 - FDDD6F背景
            return Color(red: 0.40, green: 0.31, blue: 0) // 664F00
        } else if currentBackgroundColor == Color(red: 1, green: 0.65, blue: 0.74) {
            // 幸福情绪 - FFA7BC背景
            return Color(red: 0.30, green: 0.20, blue: 0.22) // 4D3238
        } else if currentBackgroundColor == Color(red: 1, green: 0.52, blue: 0.24) {
            // 生气情绪 - FF843E背景
            return Color(red: 0.47, green: 0.18, blue: 0.02) // 782E04
        } else if currentBackgroundColor == Color(red: 0.55, green: 0.64, blue: 0.93) {
            // 悲伤情绪 - 8CA4EE背景
            return Color(red: 0.19, green: 0.23, blue: 0.33) // 313A54
        } else if currentBackgroundColor == Color(red: 0.63, green: 0.91, blue: 0.92) {
            // 不开心情绪 - A1E7EB背景
            return Color(red: 0.23, green: 0.45, blue: 0.47) // 3A7478
        } else {
            // 默认颜色
            return .primary
        }
    }
}
