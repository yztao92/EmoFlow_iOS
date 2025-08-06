import SwiftUI

struct JournalDetailContainerView: View {
    let journalId: Int
    @State private var record: ChatRecord?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView("加载中...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("正在加载日记详情...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("加载失败")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let record = record {
                ChatrecordDetailView(
                    record: record, 
                    onSave: { newSummary in
                        // 保存逻辑
                        record.summary = newSummary
                    },
                    navigationPath: $navigationPath
                )
            } else {
                // 添加一个默认状态，防止空白页面
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("日记详情")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("正在准备显示...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("日记详情")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // 隐藏系统默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    // 统一使用 removeLast() 返回
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                }
            }
        }
        .onAppear {
            loadJournalDetail()
        }
    }
    
    private func loadJournalDetail() {
        Task {
            do {
                let detailRecord = try await JournalDetailService.shared.fetchJournalDetail(journalId: journalId)
                await MainActor.run {
                    self.record = detailRecord
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
} 