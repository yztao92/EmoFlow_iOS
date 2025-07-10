//
//  SettingView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//
import SwiftUI

struct SettingsView: View {
    @State private var username: String = UserDefaults.standard.string(forKey: "username") ?? "张三"
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")

    var body: some View {
            Form {
                Section(header: Text("账户")) {
                    HStack {
                        Text("用户名")
                        Spacer()
                        TextField("用户名", text: $username)
                            .multilineTextAlignment(.trailing)
                        .onChange(of: username) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "username")
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
                        // TODO: 删除账户逻辑
                    } label: {
                        Text("退出登录")
                    }
                }
        }
    }
}
