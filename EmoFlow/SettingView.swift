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
    @State private var userBirthday: String? = nil
    @State private var subscriptionStatus: String = "inactive"
    @State private var showLogoutAlert = false
    @State private var showUsernameEditAlert = false
    @State private var tempUsername: String = ""
    @State private var isUpdatingUsername = false
    @State private var showUpdateError = false
    @State private var updateErrorMessage = ""
    
    // 生日编辑相关状态
    @State private var showBirthdayPicker = false
    @State private var selectedBirthday = Date()
    @State private var isUpdatingBirthday = false
    
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
                
                Divider()
                HStack {
                    Text("生日")
                    Spacer()
                    if isUpdatingBirthday {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        if let birthday = userBirthday, !birthday.isEmpty {
                            // 已设置生日，只显示文本
                            Text(birthday)
                                .foregroundColor(.secondary)
                        } else {
                            // 未设置生日，显示可点击的"设置"按钮
                            Button(action: {
                                showBirthdayPicker = true
                            }) {
                                Text("设置")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                HStack {
                    Text("会员状态")
                    Spacer()
                    Text(subscriptionStatus == "active" ? "Pro用户" : "普通用户")
                        .foregroundColor(subscriptionStatus == "active" ? .yellow : .secondary)
                }
                .padding()
            }
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
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.primary)
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
        .sheet(isPresented: $showBirthdayPicker) {
            BirthdayPickerView(
                selectedDate: $selectedBirthday,
                onSave: { newDate in
                    updateBirthdayOnBackend(newDate)
                },
                onCancel: {
                    showBirthdayPicker = false
                }
            )
        }
        .onAppear {
            // 更新用户信息显示
            username = UserDefaults.standard.string(forKey: "userName") ?? ""
            userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
            userBirthday = UserDefaults.standard.string(forKey: "userBirthday")
            subscriptionStatus = UserDefaults.standard.string(forKey: "subscriptionStatus") ?? "inactive"
            
            
            // 设置selectedBirthday的初始值
            if let birthday = userBirthday, !birthday.isEmpty {
                if let date = parseBirthdayString(birthday) {
                    selectedBirthday = date
                }
            }
            
            // 每次进入设置页面时获取最新的用户信息（包含心心数量）
            Task {
                do {
                    let userInfo = try await UserProfileService.shared.fetchUserProfile()
                    await MainActor.run {
                        username = userInfo.name
                        userEmail = userInfo.email
                        userBirthday = userInfo.birthday
                        subscriptionStatus = userInfo.subscription_status
                        
                        // 更新selectedBirthday
                        if let birthday = userInfo.birthday, !birthday.isEmpty {
                            if let date = parseBirthdayString(birthday) {
                                selectedBirthday = date
                            }
                        }
                    }
                    print("🔍 设置页面进入时获取用户信息: \(userInfo.name), 心心数量: \(userInfo.heart), 生日: \(userInfo.birthday ?? "未设置"), 订阅状态: \(userInfo.subscription_status)")
                } catch {
                    print("⚠️ 设置页面进入时获取用户信息失败: \(error)")
                }
            }
        }
    }
    

    
    private func logout() {
        // 清除用户数据
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userBirthday")
        UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
        UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
        
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
    
    // MARK: - 生日更新
    /// 更新生日到后端
    private func updateBirthdayOnBackend(_ newDate: Date) {
        // 显示加载状态
        isUpdatingBirthday = true
        
        Task {
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let birthdayString = dateFormatter.string(from: newDate)
                
                // 调用后端API更新生日
                let userInfo = try await UserProfileService.shared.updateBirthday(birthdayString)
                
                await MainActor.run {
                    // 更新本地显示
                    userBirthday = userInfo.birthday
                    isUpdatingBirthday = false
                    showBirthdayPicker = false
                }
                
                print("✅ 生日更新成功: \(birthdayString)")
            } catch {
                await MainActor.run {
                    isUpdatingBirthday = false
                    updateErrorMessage = error.localizedDescription
                    showUpdateError = true
                }
                
                print("❌ 生日更新失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 日期解析
    /// 将生日字符串解析为Date对象
    private func parseBirthdayString(_ birthdayString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: birthdayString)
    }
}
