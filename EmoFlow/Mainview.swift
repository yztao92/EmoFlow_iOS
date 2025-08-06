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

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 主要内容 - 情绪选择页面
                ContentView(
                    navigationPath: $navigationPath,
                    onBackgroundColorChange: { color in
                        self.currentBackgroundColor = color
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
                                .foregroundColor(getIconColor())
                                .frame(width: 44, height: 44)
                        }
                        
                        // 设置按钮
                        Button(action: {
                            navigationPath.append(AppRoute.settings)
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
