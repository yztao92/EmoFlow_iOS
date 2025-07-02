//
//  TodoView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//

// TodoView.swift
import SwiftUI

struct TodoView: View {
    @State private var items: [String] = []
    @State private var newItem = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("添加新待办")) {
                    HStack {
                        TextField("新任务...", text: $newItem)
                        Button("添加") {
                            guard !newItem.isEmpty else { return }
                            items.append(newItem)
                            newItem = ""
                            saveItems()
                        }
                    }
                }

                Section(header: Text("待办列表")) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                    }
                    .onDelete { idx in
                        items.remove(atOffsets: idx)
                        saveItems()
                    }
                }
            }
            .toolbar {
                EditButton()
            }
            .onAppear {
                loadItems()
            }
        }
    }
    
    private func saveItems() {
        UserDefaults.standard.set(items, forKey: "todo_items")
    }
    
    private func loadItems() {
        items = UserDefaults.standard.stringArray(forKey: "todo_items") ?? []
    }
}

