// ChatRecordDetailView.swift
import SwiftUI

struct ChatRecordDetailView: View {
    let record: ChatRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(record.safeEmotion.iconName)
                    .resizable()
                    .frame(width: 28, height: 28)
                Text("心情日记")
                    .font(.title2).bold()
            }
            Text(record.summary)
                .font(.body)
            Spacer()
        }
        .padding()
    }
}
