import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let autoSend: Bool
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: ((UIImage?) -> Void)?
    
    init(selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType, autoSend: Bool = false, onImageSelected: ((UIImage?) -> Void)? = nil) {
        self._selectedImage = selectedImage
        self.sourceType = sourceType
        self.autoSend = autoSend
        self.onImageSelected = onImageSelected
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let selectedImage: UIImage?
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            } else {
                selectedImage = nil
            }
            
            parent.selectedImage = selectedImage
            parent.onImageSelected?(selectedImage)
            
            parent.presentationMode.wrappedValue.dismiss()
            
            // 如果启用自动发送，延迟一点时间让图片设置完成后再发送
            if parent.autoSend {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 通过NotificationCenter发送通知，让ChatView知道需要自动发送
                    NotificationCenter.default.post(name: .autoSendImage, object: nil)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
