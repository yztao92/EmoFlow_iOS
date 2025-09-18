import SwiftUI

struct JournalContentView: View {
    let emotion: EmotionType?
    let title: String?
    let content: String
    let date: Date
    let originalTimeString: String?
    let imageURLs: [String]?
    
    init(emotion: EmotionType?, title: String?, content: String, date: Date, originalTimeString: String? = nil, imageURLs: [String]? = nil) {
        self.emotion = emotion
        self.title = title
        self.content = content
        self.date = date
        self.originalTimeString = originalTimeString
        self.imageURLs = imageURLs
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // 情绪图标 - 页面居中显示
                VStack(spacing: 0) {
                    Image(emotion?.iconName ?? "Happy")
                        .resizable()
                        .frame(width: 128, height: 128)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.top, 0)
                

                
                // 内容显示 - 居中，移除滚动限制
                VStack(spacing: 36) {
                    // 使用纯文本显示
                    Text(content)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 200) // 移除maxHeight限制
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    // 图片显示区域
                    if let imageURLs = imageURLs, !imageURLs.isEmpty {
                        JournalImagesView(imageURLs: imageURLs)
                    } else {
                        Color.clear
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 50) // 添加底部间距，确保内容完全可见
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    private func formatDisplayTime() -> String {
        // 如果有原始时间字符串，优先使用它
        if let originalTime = originalTimeString {
            // 使用与JournalDetailService相同的时间解析逻辑
            let parsedDate = parseBackendTime(originalTime)
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.timeZone = TimeZone.current
            return displayFormatter.string(from: parsedDate)
        }
        
        // 如果没有原始时间字符串，使用传入的date
        return formatDate(date)
    }
    
    private func parseBackendTime(_ timeString: String) -> Date {
        // 尝试多种时间格式，直接解析为本地时间
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone.current // 直接使用本地时区
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        
        // 如果所有格式都失败，返回当前时间
        print("⚠️ 无法解析时间格式: \(timeString)，使用当前时间")
        return Date()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current // 使用本地时区
        return formatter.string(from: date)
    }
} 