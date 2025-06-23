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
            ContentView()
                .tabItem {
                    Label("心情输入", systemImage: "heart")
                }

            ChatHistoryView()
                .tabItem {
                    Label("记录", systemImage: "book")
                }
        }
    }
}
