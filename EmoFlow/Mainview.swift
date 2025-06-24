//
//  Mainview.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            // 1. 情绪输入
            ContentView()
                .tabItem {
                    Label("心情输入", systemImage: "heart.fill")
                }

            // 2. 聊天记录
            ChatHistoryView()
                .tabItem {
                    Label("记录", systemImage: "book.fill")
                }

            // 3. 待办列表
            TodoView()
                .tabItem {
                    Label("待办", systemImage: "checkmark.circle.fill")
                }

            // 4. 设置 / 个人账户
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "person.circle.fill")
                }
        }
    }
}
