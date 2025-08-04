import SwiftUI

struct JournalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedEmotion: EmotionType
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 创建成功后的回调
    var onJournalCreated: ((Int) -> Void)? = nil
    // 编辑成功后的回调
    var onJournalUpdated: ((Int) -> Void)? = nil
    // 是否为编辑模式
    var isEditMode: Bool = false
    // 编辑时的日记ID
    var editJournalId: Int? = nil
    
    // 情绪选项
    private let emotionOptions: [EmotionType] = [.happy, .happiness, .unhappy, .sad, .peaceful, .angry]
    
    init(initialEmotion: EmotionType = .peaceful, onJournalCreated: ((Int) -> Void)? = nil, isEditMode: Bool = false, editJournalId: Int? = nil, onJournalUpdated: ((Int) -> Void)? = nil, initialTitle: String = "", initialContent: String = "") {
        self._selectedEmotion = State(initialValue: initialEmotion)
        self._title = State(initialValue: initialTitle)
        self._content = State(initialValue: initialContent)
        self.onJournalCreated = onJournalCreated
        self.isEditMode = isEditMode
        self.editJournalId = editJournalId
        self.onJournalUpdated = onJournalUpdated
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 情绪选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(emotionOptions, id: \.self) { emotion in
                        EmotionOptionView(
                            emotion: emotion,
                            isSelected: selectedEmotion == emotion
                        ) {
                            selectedEmotion = emotion
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            
            // 编辑区域
            ScrollView {
                VStack(spacing: 20) {
                    // 标题输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("给这段心情起个标题...", text: $title)
                            .font(.system(size: 18, weight: .medium))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // 内容输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $content)
                            .font(.system(size: 16, weight: .regular))
                            .frame(minHeight: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(isEditMode ? "编辑心情" : "记录心情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveJournal()
                }
                .foregroundColor(.blue)
                .disabled(title.isEmpty || content.isEmpty || isSaving)
            }
        }
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveJournal() {
        isSaving = true
        
        Task {
            do {
                if isEditMode {
                    // 编辑模式：更新日记
                    guard let journalId = editJournalId else {
                        throw NetworkError.invalidResponse
                    }
                    
                    let response = try await JournalUpdateService.shared.updateJournal(
                        journalId: journalId,
                        title: title,
                        content: content,
                        emotion: selectedEmotion
                    )
                    
                    print("✅ 日记更新成功:")
                    print("日记ID: \(response.journal_id)")
                    print("标题: \(response.title)")
                    print("内容: \(response.content)")
                    print("情绪: \(response.emotion)")
                    
                    // 更新成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 调用编辑成功回调
                        onJournalUpdated?(response.journal_id)
                        dismiss()
                    }
                } else {
                    // 创建模式：创建新日记
                    let response = try await JournalCreateService.shared.createJournal(
                        title: title,
                        content: content,
                        emotion: selectedEmotion
                    )
                    
                    print("✅ 日记创建成功:")
                    print("日记ID: \(response.journal_id)")
                    print("标题: \(response.title)")
                    print("内容: \(response.content)")
                    print("情绪: \(response.emotion)")
                    
                    // 创建成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 调用回调，传递新创建的日记ID
                        onJournalCreated?(response.journal_id)
                        // 不调用 dismiss()，让回调处理导航
                    }
                }
            } catch {
                print("❌ 日记操作失败: \(error)")
                
                await MainActor.run {
                    isSaving = false
                    errorMessage = "保存失败，请检查网络连接后重试"
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - 情绪选项视图
struct EmotionOptionView: View {
    let emotion: EmotionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(emotion.iconName)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .opacity(isSelected ? 1.0 : 0.6)
                
                Text(emotion.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? emotion.color : .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? emotion.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? emotion.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    JournalEditView(initialEmotion: .happy)
} 