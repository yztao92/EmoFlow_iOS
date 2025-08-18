import SwiftUI
import AuthenticationServices

/// EmoFlow 应用登录界面
/// 提供 Apple Sign in with Apple 登录功能，包含网络权限检查和错误处理
struct AppLoginView: View {
    /// 登录状态绑定，由父视图控制
    @Binding var isLoggedIn: Bool
    
    /// 加载状态，控制加载指示器的显示
    @State private var isLoading: Bool = false
    
    /// 错误弹窗显示状态
    @State private var showError: Bool = false
    
    /// 错误信息内容
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack {
            // MARK: - 背景设计
            // 使用渐变背景，从浅蓝色到深蓝色，营造平静的氛围
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.98, blue: 1),  // 浅蓝色
                    Color(red: 0.87, green: 0.92, blue: 1)   // 深蓝色
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // MARK: - Logo 和标题区域
                VStack(spacing: 20) {
                    // 应用图标，使用圆角设计
                    Image("AIicon") // 使用应用图标
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(24)
                    
                    // 应用名称，使用粗体字体
                    Text("EmoFlow")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53))
                    
                    // 应用副标题，描述应用功能
                    Text("记录你的情绪，探索内心世界")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53).opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
            Spacer()

                // MARK: - 登录按钮区域
                VStack(spacing: 20) {
                    // Apple Sign in with Apple 登录按钮
                    // 使用 Apple 官方提供的按钮组件，确保符合 Apple 设计规范
                    SignInWithAppleButton(
                        onRequest: { request in
                            // 请求用户的姓名和邮箱权限
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            // 处理 Apple 登录结果
                            handleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)  // 使用白色样式，适配深色背景
                    .frame(height: 50)
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)  // 添加阴影效果
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // MARK: - 底部说明文字
                // 提示用户登录后可以使用的功能
                Text("登录后即可开始使用所有功能")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53).opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .overlay(
            // MARK: - 加载指示器
            // 在登录过程中显示加载状态，提供用户反馈
            Group {
                if isLoading {
                    // 半透明黑色背景，覆盖整个界面
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    // 白色圆形进度指示器，放大 1.5 倍
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
        .alert("登录失败", isPresented: $showError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 检查网络权限
            checkNetworkPermission()
        }
        .onAppear {
            // 检查网络权限
            checkNetworkPermission()
        }
    }
    
    // MARK: - 网络权限检查
    /// 在界面加载时主动触发网络权限请求
    /// 避免用户在登录时因网络权限问题导致失败
    private func checkNetworkPermission() {
        // 主动发起一个简单的网络请求来触发权限请求
        // 使用百度服务器，确保稳定可靠
        guard let testURL = URL(string: "https://www.baidu.com") else { return }
        
        var request = URLRequest(url: testURL)
        request.httpMethod = "HEAD"  // 只请求头部，不下载内容，节省流量
        request.timeoutInterval = 5.0  // 5秒超时，避免长时间等待
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            // 不管成功失败，目的只是触发权限请求
            if let error = error {
                print("🔍 网络权限检查 - 请求失败: \(error.localizedDescription)")
            } else {
                print("🔍 网络权限检查 - 请求成功，网络权限已获取")
            }
        }.resume()
    }
    
    // MARK: - Apple 登录结果处理
    /// 处理 Apple Sign in with Apple 的认证结果
    /// 包括成功和失败两种情况
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = true  // 显示加载状态
        
        switch result {
        case .success(let authorization):
            // Apple 认证成功，获取用户凭证
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // 从 Apple 凭证中提取用户信息
                let userID = appleIDCredential.user  // 用户的唯一标识符
                let identityToken = appleIDCredential.identityToken  // 身份令牌
                let authorizationCode = appleIDCredential.authorizationCode  // 授权码
                let fullName = appleIDCredential.fullName  // 用户姓名
                let email = appleIDCredential.email  // 用户邮箱
                
                // 调试信息：打印获取到的用户信息
                print("🔍 Apple登录调试信息:")
                print("   UserID: \(userID)")
                print("   FullName: \(fullName?.givenName ?? "nil") \(fullName?.familyName ?? "nil")")
                print("   Email: \(email ?? "nil")")
                print("   IdentityToken: \(identityToken != nil ? "有" : "无")")
                print("   AuthorizationCode: \(authorizationCode != nil ? "有" : "无")")
                print("   Real User Status: \(appleIDCredential.realUserStatus.rawValue)")
                print("   State: \(appleIDCredential.state ?? "nil")")
                
                // 将 Apple 凭证发送到后端进行验证
                verifyWithBackend(
                    userID: userID,
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: fullName,
                    email: email
                )
                    }
            
        case .failure(let error):
            // Apple 认证失败，显示错误信息
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
            }
    
    // MARK: - 后端验证
    /// 将 Apple 登录凭证发送到后端进行验证
    /// 验证成功后保存用户信息并跳转到主界面
    private func verifyWithBackend(
        userID: String,  // Apple 用户唯一标识符
        identityToken: Data?,  // Apple 身份令牌
        authorizationCode: Data?,  // Apple 授权码
        fullName: PersonNameComponents?,  // 用户姓名
        email: String?  // 用户邮箱
    ) {
        // 准备请求数据 - 发送所有可用的 Apple 凭证信息
        var loginData: [String: Any] = [
            "identity_token": identityToken?.base64EncodedString() ?? ""  // 身份令牌，Base64 编码
        ]
        
        // 如果有用户信息，也一起发送（首次登录时会有，后续登录可能为空）
        let fullNameString = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
        if !fullNameString.isEmpty {
            loginData["full_name"] = fullNameString  // 用户姓名
        }
        if let email = email, !email.isEmpty {
            loginData["email"] = email  // 用户邮箱
        }
        
        // 发送到后端 API 进行验证 - 匹配后端端点
        guard let url = URL(string: "https://emoflow.net.cn/auth/apple") else {
            isLoading = false
            errorMessage = "无效的服务器地址"
            showError = true
            return
        }

        // 配置 HTTP 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // 将登录数据编码为 JSON 格式
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        } catch {
            // JSON 编码失败
            isLoading = false
            errorMessage = "数据编码失败"
            showError = true
            return
        }
        
        // 发起网络请求到后端验证
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false  // 隐藏加载状态
                
                // 检查网络错误
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                // 检查响应数据
                guard let data = data else {
                    self.errorMessage = "服务器无响应"
                    self.showError = true
                    return
                }
                
                do {
                    // 解析后端返回的 JSON 数据
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? String,
                       status == "ok" {
                        
                        // 保存后端返回的用户信息到本地存储
                        let token = json["token"] as? String ?? ""  // JWT token
                        let userEmail = json["email"] as? String ?? ""  // 用户邮箱
                        let userId = json["user_id"] as? Int ?? 0  // 用户ID
                        let userName = json["name"] as? String ?? "用户\(userId)"  // 用户姓名，如果没有则使用默认值
                        
                        // 保存到 UserDefaults
                        UserDefaults.standard.set(token, forKey: "userToken")  // 保存 JWT token
                        UserDefaults.standard.set(userName, forKey: "userName")  // 保存用户姓名
                        UserDefaults.standard.set(userEmail, forKey: "userEmail")  // 保存用户邮箱
                        
                        // 登录成功，更新状态
                        self.isLoggedIn = true
                        
                        // 同步日记列表到本地
                        Task {
                            await JournalListService.shared.syncJournals()
                        }
                        
                        // 获取最新的心心数量
                        Task {
                            do {
                                let heartCount = try await UserHeartService.shared.fetchUserHeart()
                                print("🔍 登录成功后获取心心数量: \(heartCount)")
                            } catch {
                                print("⚠️ 登录成功后获取心心数量失败: \(error)")
                            }
                        }
                    } else {
                        // 后端验证失败
                        self.errorMessage = "登录验证失败"
                        self.showError = true
                    }
                } catch {
                    // JSON 解析失败
                    self.errorMessage = "响应解析失败"
                    self.showError = true
                }
            }
        }.resume()  // 启动网络请求
    }
}

// MARK: - 预览
/// SwiftUI 预览提供者，用于在 Xcode 中预览界面
struct AppLoginView_Previews: PreviewProvider {
    static var previews: some View {
        AppLoginView(isLoggedIn: .constant(false))
    }
} 