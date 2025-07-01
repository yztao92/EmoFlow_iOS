//
//  MainView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab: Int = 0
    @State private var showChatSheet = false
    @State private var emotions: [EmotionType] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 心情输入
            ContentView(showChatSheet: $showChatSheet, emotions: $emotions)
                .tabItem {
                    Image(selectedTab == 0 ? "tab_heart_selected" : "tab_heart_default")
                }
                .tag(0)

            // 2. 聊天记录
            ChatHistoryView()
                .tabItem {
                    Image(selectedTab == 1 ? "tab_record_selected" : "tab_record_default")
                }
                .tag(1)

            // 3. 待办
            TodoView()
                .tabItem {
                    Image(selectedTab == 2 ? "tab_todo_selected" : "tab_todo_default")
                }
                .tag(2)

            // 4. 设置
            SettingsView()
                .tabItem {
                    Image(selectedTab == 3 ? "tab_settings_selected" : "tab_settings_default")
                }
                .tag(3)
        }
        .sheet(isPresented: $showChatSheet) {
            ChatView(
                emotions: $emotions,          // ← 传入 Binding<[EmotionType]>
                selectedTab: $selectedTab,
                showChatSheet: $showChatSheet
            )
            .presentationDetents([.large])
        }
    }
}
