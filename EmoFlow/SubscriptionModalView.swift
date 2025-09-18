import SwiftUI
import StoreKit


// MARK: - 订阅会员弹窗
struct SubscriptionModalView: View {
    @Binding var isPresented: Bool
    let onPaymentSuccess: () -> Void
    let onRestoreSuccess: () -> Void
    
    @State private var products: [SubscriptionProduct] = []
    @State private var selectedProduct: SubscriptionProduct?
    @State private var isAgreementChecked: Bool = false
    @State private var showConfirmDialog: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var isPurchasing: Bool = false
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 标题和恢复购买按钮
                ZStack {
                    // 标题居中
                    Text("订阅会员")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // 恢复购买按钮在右侧
                    HStack {
                        Spacer()
                        Button("恢复购买") {
                            handleRestorePurchase()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // 订阅选项卡片
                if isLoading {
                    // 加载状态
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("加载订阅选项...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                } else if let errorMessage = errorMessage {
                    // 错误状态
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.system(size: 24))
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            loadProducts()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 40)
                } else {
                    // 正常显示订阅选项
                    HStack(spacing: 12) {
                        ForEach(products) { product in
                            SubscriptionCardView(
                                product: product,
                                isSelected: selectedProduct?.id == product.id
                            ) {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                
                // Pro权益说明
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    Text("Pro权益说明")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // 权益对比表格
                VStack(spacing: 0) {
                    // 表头
                    HStack {
                        Text("功能")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("普通用户")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 80)
                        
                        Text("Pro用户")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    
                    // 表格内容
                    VStack(spacing: 0) {
                        BenefitRowView(
                            feature: "星星数量",
                            normalUser: "20个/天",
                            proUser: "100个/天"
                        )
                        
                        BenefitRowView(
                            feature: "情绪记录",
                            normalUser: "1条/天",
                            proUser: "畅享"
                        )

                        BenefitRowView(
                            feature: "月度分析",
                            normalUser: "无",
                            proUser: "专享"
                        )
                        
                        BenefitRowView(
                            feature: "详细人格报告",
                            normalUser: "无",
                            proUser: "专享"
                        )
                        
                        BenefitRowView(
                            feature: "图片聊天",
                            normalUser: "无",
                            proUser: "畅享"
                        )
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                
                // 确认付费按钮
                Button(action: {
                    if isAgreementChecked {
                        handlePayment()
                    } else {
                        showConfirmDialog = true
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isPurchasing ? "处理中..." : "确认并支付")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedProduct != nil && !isPurchasing ? Color.orange : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // 服务协议
                HStack {
                    Button(action: {
                        isAgreementChecked.toggle()
                    }) {
                        Image(systemName: isAgreementChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isAgreementChecked ? .blue : .secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("开通前确认《会员服务协议》《自动续费协议》")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .onAppear {
            loadProducts()
        }
        .alert("确认开通", isPresented: $showConfirmDialog) {
            Button("继续开通", role: .none) {
                // 自动勾选协议复选框
                isAgreementChecked = true
                // 执行支付
                handlePayment()
            }
            Button("取消", role: .cancel) {
                // 什么都不做，关闭弹窗
            }
        } message: {
            Text("我已阅读并同意《会员服务协议》《自动续费协议》，确认开通该套餐。")
        }
    }
    
    private func loadProducts() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                // 同时加载后端产品和StoreKit产品
                async let backendProducts = SubscriptionService.shared.fetchSubscriptionProducts()
                
                let fetchedProducts = try await backendProducts
                
                // 提取Apple产品ID并加载StoreKit产品
                let appleProductIds = Set(fetchedProducts.map { $0.apple_product_id })
                try await storeKitManager.loadProducts(productIds: appleProductIds)
                
                await MainActor.run {
                    self.products = fetchedProducts
                    // 默认选择第一个产品，或者推荐产品
                    if let popularProduct = fetchedProducts.first(where: { $0.is_popular == true }) {
                        self.selectedProduct = popularProduct
                    } else if let firstProduct = fetchedProducts.first {
                        self.selectedProduct = firstProduct
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handlePayment() {
        guard let selectedProduct = selectedProduct else {
            print("❌ 未选择订阅产品")
            return
        }
        
        print("🛒 用户选择订阅: \(selectedProduct.name)")
        print("   价格: \(selectedProduct.price)")
        print("   周期: \(selectedProduct.period_display)")
        print("   Apple产品ID: \(selectedProduct.apple_product_id)")
        
        Task {
            do {
                isPurchasing = true
                
                // 先重新加载产品
                let productIds = Set([selectedProduct.apple_product_id])
                try await storeKitManager.loadProducts(productIds: productIds)
                
                // 获取StoreKit产品
                guard let storeKitProduct = storeKitManager.getProduct(by: selectedProduct.apple_product_id) else {
                    print("❌ StoreKit产品未找到: \(selectedProduct.apple_product_id)")
                    print("❌ 可用产品列表: \(storeKitManager.availableProducts.map { $0.id })")
                    throw StoreKitError.productNotFound
                }
                
                print("✅ 找到StoreKit产品: \(storeKitProduct.id)")
                
                // 执行购买
                let transaction = try await storeKitManager.purchase(storeKitProduct)
                
                print("✅ StoreKit购买成功: \(transaction.productID)")
                
                // 验证购买成功后，调用后端验证接口
                await verifyPurchaseWithBackend(transaction: transaction, product: selectedProduct)
                
            } catch {
                print("❌ 购买失败: \(error)")
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func verifyPurchaseWithBackend(transaction: StoreKit.Transaction, product: SubscriptionProduct) async {
        do {
            print("🔄 验证购买收据...")
            
            // 获取收据数据 - 使用StoreKit 2的新方法
            let result = try await AppTransaction.shared
            let appTransaction = try checkVerified(result)
            
            // 从本地获取收据(不是 appTransaction 里)
            guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                  let receiptData = try? Data(contentsOf: appStoreReceiptURL) else {
                throw StoreKitError.purchaseFailed
            }
            let receiptString = receiptData.base64EncodedString()
            
            // 调用后端验证接口
            let subscriptionDetail = try await SubscriptionService.shared.verifyPurchase(
                receiptData: receiptString
            )
            
            print("✅ 后端验证成功: \(subscriptionDetail.status)")
            
            await MainActor.run {
                isPurchasing = false
                // 先关闭弹窗
                isPresented = false
                
                // 弹窗关闭后调用回调显示 toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onPaymentSuccess()
                }
            }
            
        } catch {
            print("❌ 后端验证失败: \(error)")
            await MainActor.run {
                isPurchasing = false
                errorMessage = "购买验证失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleRestorePurchase() {
        print("🔄 用户点击恢复购买")
        
        Task {
            do {
                isPurchasing = true
                
                // 执行StoreKit恢复购买
                try await storeKitManager.restorePurchases()
                
                print("✅ StoreKit恢复购买成功")
                
                // 获取收据数据并调用后端验证 - 使用StoreKit 2的新方法
                let result = try await AppTransaction.shared
                let appTransaction = try checkVerified(result)
                
                // 从本地获取收据(不是 appTransaction 里)
                guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                      let receiptData = try? Data(contentsOf: appStoreReceiptURL) else {
                    throw StoreKitError.purchaseFailed
                }
                let receiptString = receiptData.base64EncodedString()
                
                // 调用后端恢复购买接口
                let subscriptionDetail = try await SubscriptionService.shared.restoreSubscription(receiptData: receiptString)
                
                print("✅ 后端恢复购买成功: \(subscriptionDetail.status)")
                
                await MainActor.run {
                    isPurchasing = false
                    // 先关闭弹窗
                    isPresented = false
                    
                    // 弹窗关闭后调用回调显示 toast
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onRestoreSuccess()
                    }
                }
                
            } catch {
                print("❌ 恢复购买失败: \(error)")
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unverified
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - 订阅卡片视图
struct SubscriptionCardView: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 产品名称居中
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(product.price)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(product.daily_price)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 权益对比行视图
struct BenefitRowView: View {
    let feature: String
    let normalUser: String
    let proUser: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(normalUser)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80)
            
            Text(proUser)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}


#Preview {
    SubscriptionModalView(
        isPresented: .constant(true),
        onPaymentSuccess: {
            print("支付成功")
        },
        onRestoreSuccess: {
            print("恢复购买成功")
        }
    )
}
