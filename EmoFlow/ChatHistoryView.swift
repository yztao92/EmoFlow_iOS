//
//  ChatHistoryView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/23.
//

import SwiftUI

struct ChatHistoryView: View {
    var body: some View {
        VStack {
            Text("聊天记录")
                .font(.title)
                .padding()

            List {
                // 示例静态数据，后面你可以用实际聊天记录替换
                Text("😢 今天有点难过")
                Text("😊 下午喝了咖啡，感觉好多了")
                Text("😡 早上被同事误会了")
            }
        }
    }
}
