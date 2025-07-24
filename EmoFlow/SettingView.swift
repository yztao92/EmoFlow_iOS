//
//  SettingView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//
import SwiftUI

struct SettingsView: View {
    @State private var username: String = UserDefaults.standard.string(forKey: "userName") ?? "用户"
    @State private var userEmail: String = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
    @State private var showLogoutAlert = false
    
    // 用于控制应用重新启动到登录页面
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("账户信息")) {
                HStack {
                    Text("用户名")
                    Spacer()
                    Text(username)
                        .foregroundColor(.secondary)
                }
                
                if !userEmail.isEmpty {
                    HStack {
                        Text("邮箱")
                        Spacer()
                        Text(userEmail)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("偏好设置")) {
                Toggle("新消息提醒", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "notifications_enabled")
                    }
            }

            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("退出登录")
                    }
                }
            }
        }
        .navigationTitle("设置")
        .alert("确认退出登录", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出登录", role: .destructive) {
                logout()
            }
        } message: {
            Text("退出登录后需要重新登录才能使用应用")
        }
        .onAppear {
            // 更新用户信息显示
            username = UserDefaults.standard.string(forKey: "userName") ?? "用户"
            userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        }
    }
    
    private func logout() {
        // 清除用户数据
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        
        // 发送登出通知
        NotificationCenter.default.post(name: .logout, object: nil)
    }
}
