import SwiftUI

struct ChatHistoryView: View {
    @State private var records: [ChatRecord] = []

    /// 按“月/日”分组，同时保留该组的最大日期用于排序；组内再按照 record.date 降序
    private var groupedRecords: [GroupedRecord] {
        // 先按字符串分组
        let dict = Dictionary(grouping: records) { record in
            record.date.formatted(.dateTime.month().day()) // "6/24"
        }

        // 变成带 Date 值的分组
        let groups: [GroupedRecord] = dict.map { key, items in
            // 先把组内 items 按 date 降序（最新条目在前）
            let sortedItems = items.sorted { $0.date > $1.date }
            // 用组内最新那条的 date 作为组的排序依据
            let maxDate = sortedItems.first!.date
            return GroupedRecord(
                id: key,
                dateString: key,
                dateValue: maxDate,
                items: sortedItems
            )
        }

        // 最后把所有组按 dateValue 降序（最新的组在前）
        return groups.sorted { $0.dateValue > $1.dateValue }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedRecords) { section in
                    Section(header:
                        Text(section.dateString)  // 比如 "6/24"
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .textCase(.none)
                    ) {
                        ForEach(section.items) { record in
                            NavigationLink(value: record) {
                                HStack(spacing: 12) {
                                    Image(record.safeEmotion.iconName)
                                        .resizable()
                                        .frame(width: 32, height: 32)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.summary)
                                            .font(.body)
                                            .lineLimit(1)
                                        Text(record.date.formatted(.dateTime.hour().minute()))
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("记录")
            .navigationDestination(for: ChatRecord.self) { record in
                ChatRecordDetailView(record: record)
            }
            .onAppear {
                records = RecordManager.loadAll()
            }
        }
    }

    private func delete(_ record: ChatRecord) {
        RecordManager.delete(record)
        records.removeAll { $0.id == record.id }
    }
}

// 把 dateValue（Date）也带进来，方便排序
fileprivate struct GroupedRecord: Identifiable {
    let id: String              // 分组 key，比如 "6/24"
    let dateString: String      // 同上，用于显示
    let dateValue: Date         // 用于排序
    let items: [ChatRecord]

    var identity: String { id }
    var itemCount: Int { items.count }
    // Identifiable:
    var hashValue: Int { id.hashValue }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GroupedRecord, rhs: GroupedRecord) -> Bool {
        lhs.id == rhs.id
    }
}
