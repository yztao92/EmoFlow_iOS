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
    
    private func tabTitle(for tab: Int) -> String {
        switch tab {
        case 0: return ""
        case 1: return "心情笔记"
        case 2: return "设置"
        default: return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
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
                .tabItem {
                    Image(selectedTab == 0 ? "tab_heart_selected" : "tab_heart_default")
                }
                .tag(0)
                
                ChatHistoryView(selectedRecord: $selectedRecord)
                    .tabItem {
                        Image(selectedTab == 1 ? "tab_record_selected" : "tab_record_default")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Image(selectedTab == 2 ? "tab_settings_selected" : "tab_settings_default")
                    }
                    .tag(2)
            }
            .navigationTitle(tabTitle(for: selectedTab))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !tabTitle(for: selectedTab).isEmpty {
                        Text(tabTitle(for: selectedTab))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationDestination(item: $selectedRecord) { record in
                ChatRecordDetailView(record: record)
            }
            .navigationDestination(isPresented: $chatActive) {
                ChatView(
                    emotions: $emotions,
                    selectedTab: $selectedTab,
                    initialMessage: initialMessage,
                    sessionID: sessionID
                )
            }
        }
    }
}
