import Foundation
import StoreKit

// MARK: - 购买状态枚举
enum PurchaseState {
    case idle
    case purchasing
    case success
    case failed(Error)
    case restored
}

// MARK: - StoreKit购买管理器
@MainActor
class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var purchaseState: PurchaseState = .idle
    @Published var availableProducts: [Product] = []
    
    private var productIds: Set<String> = []
    private var purchaseCompletion: ((Result<Transaction, Error>) -> Void)?
    
    private override init() {
        super.init()
        setupStoreKit()
    }
    
    // MARK: - 设置StoreKit
    private func setupStoreKit() {
        // 监听交易更新
        Task {
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
        }
    }
    
    // MARK: - 加载产品
    func loadProducts(productIds: Set<String>) async throws {
        self.productIds = productIds
        
        print("🔍 StoreKit - 开始加载产品...")
        print("🔍 产品ID列表: \(productIds)")
        print("🔍 Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
        print("🔍 当前环境: \(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "真机")")
        
        // 检查是否在Sandbox环境
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            print("🔍 Receipt URL: \(receiptURL)")
            if receiptURL.path.contains("sandboxReceipt") {
                print("✅ 检测到Sandbox环境")
            } else {
                print("⚠️ 可能不是Sandbox环境")
            }
        }
        
        // 检查是否有StoreKit Configuration File
        if let configURL = Bundle.main.url(forResource: "Configuration", withExtension: "storekit") {
            print("✅ 找到StoreKit Configuration File: \(configURL)")
        } else {
            print("⚠️ 未找到StoreKit Configuration File")
        }
        
        // 注意：StoreKit Configuration File 需要在Xcode中正确配置才能生效
        // 目前我们直接使用标准StoreKit API
        
        do {
            let products = try await Product.products(for: productIds)
            self.availableProducts = products.sorted { $0.id < $1.id }
            print("✅ StoreKit - 成功加载 \(products.count) 个产品")
            
            // 打印产品信息用于调试
            for product in products {
                print("📦 产品: \(product.id) - \(product.displayName) - \(product.displayPrice)")
                print("📦 产品类型: \(product.type)")
                print("📦 产品描述: \(product.description)")
            }
            
            if products.isEmpty {
                print("⚠️ StoreKit - 没有找到任何产品，可能的原因：")
                print("   1. 产品ID不匹配 - 当前尝试: \(productIds)")
                print("   2. Bundle ID不匹配 - 当前: \(Bundle.main.bundleIdentifier ?? "未知")")
                print("   3. 产品状态不是Ready to Submit")
                print("   4. 没有使用Sandbox测试账户")
                print("   5. 产品没有正确同步到App Store")
                print("   6. App Store Connect中的产品ID: com.yztao92.EmoFlow.subscription.monthly")
                print("   7. 检查App Store Connect中产品的Bundle ID是否匹配")
                print("   8. 确保产品已提交审核或处于Ready to Submit状态")
                print("   9. 确保在App Store Connect中创建了Sandbox测试账户")
                print("   10. 确保设备已登录Sandbox测试账户")
                print("   11. 产品可能需要时间同步到Sandbox环境")
                
                // 尝试加载所有可用产品进行调试
                print("🔍 尝试加载所有可用产品进行调试...")
                let allProducts = try await Product.products(for: [])
                print("🔍 所有可用产品数量: \(allProducts.count)")
                for product in allProducts {
                    print("🔍 发现产品: \(product.id) - \(product.displayName)")
                }
            }
        } catch {
            print("❌ StoreKit - 加载产品失败: \(error)")
            print("❌ 尝试加载的产品ID: \(productIds)")
            print("❌ 错误详情: \(error.localizedDescription)")
            print("❌ 错误类型: \(type(of: error))")
            throw error
        }
    }
    
    // MARK: - 购买产品
    func purchase(_ product: Product) async throws -> Transaction {
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseState = .success
                print("✅ StoreKit - 购买成功: \(product.displayName)")
                return transaction
                
            case .userCancelled:
                purchaseState = .idle
                throw StoreKitError.userCancelled
                
            case .pending:
                purchaseState = .idle
                throw StoreKitError.pending
                
            @unknown default:
                purchaseState = .idle
                throw StoreKitError.unknown
            }
        } catch {
            purchaseState = .failed(error)
            print("❌ StoreKit - 购买失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 恢复购买
    func restorePurchases() async throws {
        purchaseState = .purchasing
        
        do {
            try await AppStore.sync()
            purchaseState = .restored
            print("✅ StoreKit - 恢复购买成功")
        } catch {
            purchaseState = .failed(error)
            print("❌ StoreKit - 恢复购买失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 处理交易更新
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await transaction.finish()
            print("✅ StoreKit - 交易更新处理完成: \(transaction.productID)")
        } catch {
            print("❌ StoreKit - 交易更新处理失败: \(error)")
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
    
    // MARK: - 获取产品信息
    func getProduct(by id: String) -> Product? {
        return availableProducts.first { $0.id == id }
    }
}

// MARK: - StoreKit错误枚举
enum StoreKitError: Error, LocalizedError {
    case userCancelled
    case pending
    case unknown
    case unverified
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "用户取消了购买"
        case .pending:
            return "购买正在处理中"
        case .unknown:
            return "未知错误"
        case .unverified:
            return "交易验证失败"
        case .productNotFound:
            return "产品未找到"
        case .purchaseFailed:
            return "购买失败"
        }
    }
}
