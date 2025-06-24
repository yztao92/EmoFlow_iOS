//
//  ChatHistoryView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct ChatHistoryView: View {
    @State private var records: [ChatRecord] = []
    @State private var selectedRecord: ChatRecord?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                        Button {
                            selectedRecord = record
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(record.safeEmotion.iconName)
                                        .resizable()
                                        .frame(width: 20, height: 20)

                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Spacer()
                                }

                                Text(record.summary)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(4)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("记录")
            .sheet(item: $selectedRecord) { record in
                ChatRecordDetailView(record: record)
            }
            .onAppear {
                records = RecordManager.loadAll()
            }
        }
    }
}
