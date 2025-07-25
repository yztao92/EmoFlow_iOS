import SwiftUI
import AuthenticationServices

struct AppLoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.98, blue: 1),
                    Color(red: 0.87, green: 0.92, blue: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo和标题
        VStack(spacing: 20) {
                    Image("AIicon") // 使用应用图标
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(24)
                    
                    Text("EmoFlow")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53))
                    
                    Text("记录你的情绪，探索内心世界")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53).opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
            Spacer()

                // 登录按钮
                VStack(spacing: 20) {
                    // 苹果登录按钮
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // 开发模式跳过登录按钮
                    Button(action: {
                        // 开发模式：直接登录
                        UserDefaults.standard.set("dev_user", forKey: "userToken")
                        UserDefaults.standard.set("开发用户", forKey: "userName")
                        UserDefaults.standard.set("dev@example.com", forKey: "userEmail")
                        isLoggedIn = true
                    }) {
                        Text("开发模式 - 跳过登录")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 底部说明
                Text("登录后即可开始使用所有功能")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.53).opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .overlay(
            // 加载指示器
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
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
    }
    
    // 处理苹果登录结果
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
                switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // 获取Apple登录凭证
                let userID = appleIDCredential.user
                let identityToken = appleIDCredential.identityToken
                let authorizationCode = appleIDCredential.authorizationCode
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                // 调试信息：打印获取到的用户信息
                print("🔍 Apple登录调试信息:")
                print("   UserID: \(userID)")
                print("   FullName: \(fullName?.givenName ?? "nil") \(fullName?.familyName ?? "nil")")
                print("   Email: \(email ?? "nil")")
                print("   IdentityToken: \(identityToken != nil ? "有" : "无")")
                print("   AuthorizationCode: \(authorizationCode != nil ? "有" : "无")")
                print("   Real User Status: \(appleIDCredential.realUserStatus.rawValue)")
                print("   State: \(appleIDCredential.state ?? "nil")")
                
                // 发送到后端验证
                verifyWithBackend(
                    userID: userID,
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: fullName,
                    email: email
                )
                    }
            
                case .failure(let error):
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
                }
            }
    
    // 与后端验证
    private func verifyWithBackend(
        userID: String,
        identityToken: Data?,
        authorizationCode: Data?,
        fullName: PersonNameComponents?,
        email: String?
    ) {
        // 准备请求数据 - 发送所有可用信息
        var loginData: [String: Any] = [
            "identity_token": identityToken?.base64EncodedString() ?? ""
        ]
        
        // 如果有用户信息，也一起发送（首次登录时会有）
        let fullNameString = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
        if !fullNameString.isEmpty {
            loginData["full_name"] = fullNameString
        }
        if let email = email, !email.isEmpty {
            loginData["email"] = email
        }
        
        // 发送到后端API - 匹配后端端点
        guard let url = URL(string: "https://emoflow.net.cn/auth/apple") else {
            isLoading = false
            errorMessage = "无效的服务器地址"
            showError = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        } catch {
            isLoading = false
            errorMessage = "数据编码失败"
            showError = true
                        return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "服务器无响应"
                    self.showError = true
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? String,
                       status == "ok" {
                        
                        // 调试：打印后端返回的JSON数据
                        print("🔍 后端返回数据:")
                        print("   JSON: \(json)")
                        
                        // 保存后端返回的用户信息
                        let token = json["token"] as? String ?? ""
                        let userEmail = json["email"] as? String ?? ""
                        let userId = json["user_id"] as? Int ?? 0
                        let userName = json["name"] as? String ?? "用户\(userId)" // 使用后端返回的姓名，如果没有则使用默认值
                        
                        UserDefaults.standard.set(token, forKey: "userToken")
                        UserDefaults.standard.set(userName, forKey: "userName") // 使用真实姓名
                        UserDefaults.standard.set(userEmail, forKey: "userEmail")
                        
                        // 登录成功
                        self.isLoggedIn = true
                        
                        // 同步日记列表
                        Task {
                            await JournalListService.shared.syncJournals()
                        }
                } else {
                        self.errorMessage = "登录验证失败"
                        self.showError = true
                    }
                } catch {
                    self.errorMessage = "响应解析失败"
                    self.showError = true
                }
            }
        }.resume()
    }
}

struct AppLoginView_Previews: PreviewProvider {
    static var previews: some View {
        AppLoginView(isLoggedIn: .constant(false))
    }
} 