//
//  Mainview.swift
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
            // 1. 情绪输入
            ContentView(showChatSheet: $showChatSheet, emotions: $emotions)
                .tabItem {
                    Label("心情输入", systemImage: "heart.fill")
                }
                .tag(0)

            // 2. 聊天记录
            ChatHistoryView()
                .tabItem {
                    Label("记录", systemImage: "book.fill")
                }
                .tag(1)

            // 3. 待办
            TodoView()
                .tabItem {
                    Label("待办", systemImage: "checkmark.circle.fill")
                }
                .tag(2)

            // 4. 设置
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .sheet(isPresented: $showChatSheet) {
            ChatView(
                emotions: emotions,
                selectedTab: $selectedTab,
                showChatSheet: $showChatSheet     // ✅ 必传
            )
            .presentationDetents([.large])
        }
    }
}
