import SwiftUI
import UIKit

// 图片状态枚举
enum ImageState: Identifiable {
    case existing(String, String) // 原有图片，(imageId, imageUrl)
    case new(UIImage)     // 新增图片，UIImage是本地图片
    
    var id: String {
        switch self {
        case .existing(let imageId, _):
            return "existing_\(imageId)"
        case .new(let image):
            return "new_\(image.hashValue)"
        }
    }
    
    var isExisting: Bool {
        if case .existing = self {
            return true
        }
        return false
    }
    
    var isNew: Bool {
        if case .new = self {
            return true
        }
        return false
    }
    
    // 获取图片ID（用于后端API）
    var imageId: String? {
        if case .existing(let imageId, _) = self {
            return imageId
        }
        return nil
    }
    
    // 获取图片URL（用于显示）
    var imageUrl: String? {
        if case .existing(_, let imageUrl) = self {
            return imageUrl
        }
        return nil
    }
}

// 图片管理类
class ImageManager: ObservableObject {
    @Published var images: [ImageState] = []
    let maxImageCount = 3
    
    // 初始化方法
    init() {
        print("📸 ImageManager - 初始化")
    }
    
    // 初始化方法，可以传入现有图片
    init(existingImageIds: [String]? = nil, existingImageUrls: [String]? = nil) {
        print("📸 ImageManager - 初始化")
        print("📸 ImageManager - 图片IDs: \(existingImageIds ?? [])")
        print("📸 ImageManager - 图片URLs: \(existingImageUrls ?? [])")
        
        if let imageIds = existingImageIds, let imageUrls = existingImageUrls, 
           !imageIds.isEmpty && !imageUrls.isEmpty && imageIds.count == imageUrls.count {
            // 同时有ID和URL，创建完整的图片状态
            self.images = zip(imageIds, imageUrls).map { ImageState.existing($0, $1) }
            print("📸 ImageManager - 初始化时加载了 \(imageIds.count) 张图片")
        } else if let imageIds = existingImageIds, !imageIds.isEmpty {
            // 只有ID，使用默认URL构建方式
            self.images = imageIds.map { ImageState.existing($0, "https://emoflow.net.cn/api/images/user_1/\($0).jpg") }
            print("📸 ImageManager - 初始化时加载了 \(imageIds.count) 张图片（仅ID）")
        }
    }
    
    // 添加新图片
    func addNewImage(_ image: UIImage) -> Bool {
        guard images.count < maxImageCount else { return false }
        images.append(.new(image))
        return true
    }
    
    // 删除图片
    func deleteImage(at index: Int) {
        guard index < images.count else { return }
        images.remove(at: index)
    }
    
    // 获取保留的图片ID列表（转换为整数）
    func getKeepImageIds() -> [Int] {
        return images.compactMap { state in
            if case .existing(let id, _) = state {
                return Int(id) // 字符串转整数
            }
            return nil
        }
    }
    
    // 获取新增图片的Base64数据
    func getAddImageData() -> [String] {
        return images.compactMap { state in
            if case .new(let image) = state {
                guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
                let base64String = imageData.base64EncodedString()
                return "data:image/jpeg;base64,\(base64String)"
            }
            return nil
        }
    }
    
    // 检查是否可以添加更多图片
    var canAddMoreImages: Bool {
        return images.count < maxImageCount
    }
    
    // 获取图片总数
    var totalImageCount: Int {
        let count = images.count
        print("📸 ImageManager - totalImageCount: \(count)")
        return count
    }
    
    // 清空所有图片
    func clearAllImages() {
        images.removeAll()
    }
    
    // 从现有图片IDs和URLs初始化
    func loadExistingImages(from imageIds: [String]?, imageUrls: [String]? = nil) {
        print("📸 ImageManager - loadExistingImages 被调用")
        print("📸 ImageManager - 传入的图片IDs: \(imageIds ?? [])")
        print("📸 ImageManager - 传入的图片URLs: \(imageUrls ?? [])")
        
        guard let imageIds = imageIds, !imageIds.isEmpty else { 
            print("📸 ImageManager - 没有现有图片ID，清空图片列表")
            DispatchQueue.main.async {
                self.images.removeAll()
            }
            return 
        }
        
        print("📸 ImageManager - 开始加载 \(imageIds.count) 张现有图片")
        
        // 在主线程更新UI
        DispatchQueue.main.async {
            // 清空现有图片
            self.images.removeAll()
            
            if let imageUrls = imageUrls, !imageUrls.isEmpty && imageIds.count == imageUrls.count {
                // 同时有ID和URL，创建完整的图片状态
                for (imageId, imageUrl) in zip(imageIds, imageUrls) {
                    self.images.append(.existing(imageId, imageUrl))
                    print("📸 ImageManager - 添加现有图片: ID=\(imageId), URL=\(imageUrl)")
                }
            } else {
                // 只有ID，使用默认URL构建方式
                for imageId in imageIds {
                    let defaultUrl = "https://emoflow.net.cn/api/images/user_1/\(imageId).jpg"
                    self.images.append(.existing(imageId, defaultUrl))
                    print("📸 ImageManager - 添加现有图片: ID=\(imageId), URL=\(defaultUrl)")
                }
            }
            
            print("📸 ImageManager - 最终图片数量: \(self.images.count)")
            print("📸 ImageManager - 图片状态: \(self.images.map { $0.id })")
        }
    }
}

// 图片网格视图
struct ImageGridView: View {
    @ObservedObject var imageManager: ImageManager
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImageForPreview: UIImage?
    @State private var showFullScreenImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("图片")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("(\(imageManager.totalImageCount)/\(imageManager.maxImageCount))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 调试按钮
                Button("刷新") {
                    print("🔄 手动刷新图片列表")
                    imageManager.objectWillChange.send()
                }
                .font(.system(size: 12))
                .foregroundColor(.blue)
            }
            .onAppear {
                print("🖼️ ImageGridView appeared - canAddMoreImages: \(imageManager.canAddMoreImages), totalCount: \(imageManager.totalImageCount)")
                print("🖼️ ImageGridView - 图片状态: \(imageManager.images.map { $0.id })")
                
                // 强制刷新UI
                DispatchQueue.main.async {
                    self.imageManager.objectWillChange.send()
                }
            }
            
            // 图片网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                // 显示现有图片
                ForEach(Array(imageManager.images.enumerated()), id: \.element.id) { index, imageState in
                    ImageItemView(
                        imageState: imageState,
                        onDelete: {
                            imageManager.deleteImage(at: index)
                        },
                        onTap: { image in
                            selectedImageForPreview = image
                            showFullScreenImage = true
                        }
                    )
                }
                
                // 添加图片按钮
                if imageManager.canAddMoreImages {
                    Button(action: {
                        showImageSourceActionSheet = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            Text("添加")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: .constant(nil), sourceType: imagePickerSourceType, autoSend: false) { image in
                if let image = image {
                    _ = imageManager.addNewImage(image)
                }
            }
        }
        .actionSheet(isPresented: $showImageSourceActionSheet) {
            ActionSheet(
                title: Text("选择图片"),
                buttons: [
                    .default(Text("拍照")) {
                        imagePickerSourceType = .camera
                        showImagePicker = true
                    },
                    .default(Text("从相册选择")) {
                        imagePickerSourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let selectedImage = selectedImageForPreview {
                FullScreenImageView(image: selectedImage, isPresented: $showFullScreenImage)
            }
        }
    }
}

// 单个图片项视图
struct ImageItemView: View {
    let imageState: ImageState
    let onDelete: () -> Void
    let onTap: (UIImage) -> Void
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // 图片内容
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
                    .onTapGesture {
                        onTap(image)
                    }
            } else if isLoading {
                ProgressView()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else if errorMessage != nil {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("加载失败")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                .frame(width: 80, height: 80)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 状态标识
            VStack {
                HStack {
                    Spacer()
                    if imageState.isExisting {
                        Text("原有")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    } else if imageState.isNew {
                        Text("新增")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                Spacer()
            }
            .padding(4)
            
            // 删除按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(4)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        switch imageState {
        case .existing(let imageId, let imageUrl):
            // 对于existing图片，使用提供的URL
            print("📸 ImageItemView - 加载现有图片: ID=\(imageId), URL=\(imageUrl)")
            
            Task {
                do {
                    let loadedImage = try await ImageService.shared.loadImage(from: imageUrl)
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                        print("📸 ImageItemView - 图片加载成功: ID=\(imageId)")
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        print("📸 ImageItemView - 图片加载失败: ID=\(imageId), error=\(error)")
                    }
                }
            }
        case .new(let uiImage):
            self.image = uiImage
            self.isLoading = false
            print("📸 ImageItemView - 新图片已设置")
        }
    }
}

