//
//  SettingView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//
import SwiftUI

struct SettingsView: View {
    @State private var username: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var userEmail: String = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var heartCount: Int = UserDefaults.standard.integer(forKey: "heartCount")
    @State private var showLogoutAlert = false
    @State private var showUsernameEditAlert = false
    @State private var tempUsername: String = ""
    @State private var isUpdatingUsername = false
    @State private var showUpdateError = false
    @State private var updateErrorMessage = ""
    
    // 用于控制应用重新启动到登录页面
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // 账户信息卡片
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("用户名")
                    Spacer()
                    if isUpdatingUsername {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: {
                            tempUsername = username
                            showUsernameEditAlert = true
                        }) {
                            Text(username.isEmpty ? "点击设置用户名" : username)
                                .foregroundColor(username.isEmpty ? .secondary : .blue)
                        }
                    }
                }
                .padding()
                
                if !userEmail.isEmpty {
                    Divider()
                    HStack {
                        Text("邮箱")
                        Spacer()
                        Text(userEmail)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .background(ColorManager.cardbackground)
            .cornerRadius(12)
            
                            // 心心卡片
                HStack {
                    Text("心心")
                    Spacer()
                    Text("\(heartCount)")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(ColorManager.cardbackground)
                .cornerRadius(12)
            
            // 退出登录卡片
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("退出登录")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorManager.cardbackground)
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .scrollContentBackground(.hidden)
        .background(ColorManager.sysbackground)
        .navigationTitle("设置")
        .navigationBarBackButtonHidden(true)  // 隐藏系统默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                }
            }
        }
        .alert("确认退出登录", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出登录", role: .destructive) {
                logout()
            }
        } message: {
            Text("退出登录后需要重新登录才能使用应用")
        }
        .alert("用户名更新失败", isPresented: $showUpdateError) {
            Button("确定") { }
        } message: {
            Text(updateErrorMessage)
        }
        .alert("编辑用户名", isPresented: $showUsernameEditAlert) {
            TextField("请输入用户名", text: $tempUsername)
            Button("取消", role: .cancel) { }
            Button("保存") {
                updateUserNameOnBackend(tempUsername)
            }
        } message: {
            Text("请输入您想要的用户名")
        }
        .onAppear {
            // 更新用户信息显示
            username = UserDefaults.standard.string(forKey: "userName") ?? ""
            userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
            
            // 初始化心心数值，如果UserDefaults中没有值则设置为20
            if UserDefaults.standard.object(forKey: "heartCount") == nil {
                UserDefaults.standard.set(20, forKey: "heartCount")
                heartCount = 20
            } else {
                heartCount = UserDefaults.standard.integer(forKey: "heartCount")
            }
            
            // 每次进入设置页面时获取最新的心心数量
            Task {
                do {
                    let newHeartCount = try await UserHeartService.shared.fetchUserHeart()
                    await MainActor.run {
                        heartCount = newHeartCount
                    }
                    print("🔍 设置页面进入时获取心心数量: \(newHeartCount)")
                } catch {
                    print("⚠️ 设置页面进入时获取心心数量失败: \(error)")
                }
            }
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
    
    // MARK: - 用户名更新
    /// 更新用户名到后端
    private func updateUserNameOnBackend(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果用户名为空，只保存到本地
        if trimmedName.isEmpty {
            UserDefaults.standard.set("", forKey: "userName")
            username = ""
            
            // 发送用户名更新通知
            NotificationCenter.default.post(name: .userNameUpdated, object: nil)
            return
        }
        
        // 显示加载状态
        isUpdatingUsername = true
        
        Task {
            do {
                let userInfo = try await UserProfileService.shared.updateUserName(trimmedName)
                
                // 更新成功，保存后端返回的用户信息
                await MainActor.run {
                    UserDefaults.standard.set(userInfo.name, forKey: "userName")
                    username = userInfo.name
                    isUpdatingUsername = false
                    
                    // 发送用户名更新通知
                    NotificationCenter.default.post(name: .userNameUpdated, object: nil)
                }
                
                print("✅ 用户名更新成功: \(userInfo.name)")
            } catch {
                // 更新失败，保持原值
                await MainActor.run {
                    isUpdatingUsername = false
                    updateErrorMessage = error.localizedDescription
                    showUpdateError = true
                }
                
                print("❌ 用户名更新失败: \(error.localizedDescription)")
            }
        }
    }
}
