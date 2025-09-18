import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 背景
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    print("🔍 点击背景关闭")
                    isPresented = false
                }
            
            VStack {
                Spacer()
                
                // 图片内容
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
                    .cornerRadius(12)
                    .onTapGesture {
                        print("🔍 点击图片")
                        // 点击图片不关闭
                    }
                
                Spacer()
            }
            
            // 关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        print("🔍 点击关闭按钮")
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            print("🔍 FullScreenImageView 出现")
            print("🔍 图片尺寸: \(image.size)")
        }
    }
}
