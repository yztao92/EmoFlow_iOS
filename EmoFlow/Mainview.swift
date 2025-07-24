//
//  MainView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab: Int = 0
    @State private var emotions: [EmotionType] = []
    @State private var initialMessage: String = ""
    @State private var sessionID: String = UUID().uuidString
    @State private var chatActive: Bool = false
    @State private var selectedRecord: ChatRecord? = nil
    @State private var records: [ChatRecord] = RecordManager.loadAll()
    @State private var showLogoutAlert = false
    @Namespace private var tabAnim
    
    private let tabIcons = [
        ("tab_heart_default", "tab_heart_selected"),
        ("tab_record_default", "tab_record_selected"),
        ("tab_settings_default", "tab_settings_selected")
    ]
    private let tabTitles = ["", "心情笔记", "设置"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部标题区
                // 删除顶部自定义tabTitles标题的ZStack及相关frame/background/animation
                
                // 内容区
                ZStack {
                    if selectedTab == 0 {
                        ContentView(
                            onTriggerChat: { emotion, message in
                                self.emotions = [emotion]
                                self.initialMessage = message
                                self.sessionID = UUID().uuidString
                                DispatchQueue.main.async {
                                    self.chatActive = true
                                }
                            },
                            emotions: $emotions
                        )
                        .transition(.opacity)
                    }
                    if selectedTab == 1 {
                        ChatHistoryView(selectedRecord: $selectedRecord)
                            .transition(.opacity)
                    }
                    if selectedTab == 2 {
                        SettingsView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 自定义TabBar
                HStack {
                    ForEach(0..<tabIcons.count, id: \ .self) { idx in
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTab = idx
                            }
                        }) {
                            Image(selectedTab == idx ? tabIcons[idx].1 : tabIcons[idx].0)
                                .resizable()
                                .frame(width: 28, height: 28)
                }
                        Spacer()
                    }
                }
                .frame(height: 56)
                .background(.ultraThinMaterial)
            }
            .ignoresSafeArea(.keyboard)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            // 跳转详情
            .navigationDestination(item: $selectedRecord) { record in
                ChatrecordDetailView(record: record, onSave: { newSummary in
                    record.summary = newSummary
                    RecordManager.saveAll(records)
                })
        }
            // 跳转对话
            .navigationDestination(isPresented: $chatActive) {
            ChatView(
                    emotions: $emotions,
                selectedTab: $selectedTab,
                    initialMessage: initialMessage,
                    sessionID: sessionID,
                    selectedRecord: $selectedRecord
            )
            }
        }
    }
}
