//
//  ChatrecordingView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//

import SwiftUI

struct ChatRecordDetailView: View {
    let record: ChatRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(record.safeEmotion.iconName)
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("心情日记")
                        .font(.title2)
                        .bold()
                }

                Text(record.summary)
                    .font(.body)

                Text(record.date.formatted(date: .abbreviated, time: .standard))
                    .foregroundColor(.gray)
                    .font(.footnote)

                Spacer()
            }
            .padding()
        }
    }
}
