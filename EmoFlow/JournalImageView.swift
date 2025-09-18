//
//  JournalImageView.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/1/27.
//

import SwiftUI

struct JournalImageView: View {
    let imageURL: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showFullScreen = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 300)
                    .cornerRadius(12)
                    .onTapGesture {
                        showFullScreen = true
                    }
            } else if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 300, height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("加载中...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 300, height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text(errorMessage ?? "加载失败")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .task {
            await loadImage()
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let image = image {
                FullScreenImageView(image: image, isPresented: $showFullScreen)
            }
        }
    }
    
    private func loadImage() async {
        do {
            let loadedImage = try await ImageService.shared.loadImage(from: imageURL)
            await MainActor.run {
                self.image = loadedImage
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

struct JournalImagesView: View {
    let imageURLs: [String]
    
    var body: some View {
        if !imageURLs.isEmpty {
            VStack(spacing: 16) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    JournalImageView(imageURL: url)
                }
            }
            .padding(.horizontal, 16)
        } else {
            Color.clear
        }
    }
}
