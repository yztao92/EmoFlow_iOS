//
//  SettingView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//
import SwiftUI

struct SettingsView: View {
    // Example user data
    @State private var username: String = "张三"
    @State private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("账户")) {
                    HStack {
                        Text("用户名")
                        Spacer()
                        TextField("用户名", text: $username)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("偏好设置")) {
                    Toggle("新消息提醒", isOn: $notificationsEnabled)
                }

                Section {
                    Button(role: .destructive) {
                        // TODO: 删除账户逻辑
                    } label: {
                        Text("退出登录")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
