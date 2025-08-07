//
//  MainView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct MainView: View {
    @State private var navigationPath = NavigationPath()
    @State private var currentBackgroundColor: Color = Color(.systemGroupedBackground)
    @State private var currentSecondaryColor: Color = .primary

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 主要内容 - 情绪选择页面
                ContentView(
                    navigationPath: $navigationPath,
                    onBackgroundColorChange: { color in
                        self.currentBackgroundColor = color
                    },
                    onSecondaryColorChange: { color in
                        self.currentSecondaryColor = color
                    }
                )
                .transition(.opacity)
                
                // 右上角按钮组
                VStack {
                    HStack {
                        Spacer()
                        
                        // 日记按钮
                        Button(action: {
                            navigationPath.append(AppRoute.journalList)
                        }) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(currentSecondaryColor)
                                .frame(width: 44, height: 44)
                        }
                        
                        // 设置按钮
                        Button(action: {
                            navigationPath.append(AppRoute.settings)
                        }) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(currentSecondaryColor)
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
            
            // 统一的路由处理
            .navigationDestination(for: AppRoute.self) { route in
                createView(for: route)
            }
        }
    }
    
    @ViewBuilder
    private func createView(for route: AppRoute) -> some View {
        switch route {
        case .chat(let emotion, let initialMessage):
            ChatView(emotion: emotion, initialMessage: initialMessage, navigationPath: $navigationPath)
        case .journalCreate(let emotion):
            JournalEditView(initialEmotion: emotion, navigationPath: $navigationPath)
        case .journalEdit(let record):
            JournalEditView(record: record, navigationPath: $navigationPath)
        case .journalList:
            ChatHistoryView(navigationPath: $navigationPath)
        case .journalDetail(let id):
            JournalDetailContainerView(journalId: id, navigationPath: $navigationPath)
        case .settings:
            SettingsView()
        }
    }
    

}
