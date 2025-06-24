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
            List(records.sorted(by: { $0.date > $1.date })) { record in
                Button {
                    selectedRecord = record
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(record.safeEmotion.iconName)
                                .resizable()
                                .frame(width: 20, height: 20)

                            Text(record.summary)
                                .font(.headline)
                        }

                        Text(record.date.formatted(date: .abbreviated, time: .standard))
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                }
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

struct ChatRecordDetailView: View {
    let record: ChatRecord

    var body: some View {
        VStack(alignment: .leading) {
            Text(record.summary)
                .font(.title2)
                .padding(.bottom)
            ScrollView {
                ForEach(record.messages) { msg in
                    HStack(alignment: .top) {
                        Text(msg.role == .user ? "我:" : "AI:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(msg.content)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
    }
}
