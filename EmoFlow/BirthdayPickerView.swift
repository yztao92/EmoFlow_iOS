import SwiftUI

struct BirthdayPickerView: View {
    @Binding var selectedDate: Date
    let onSave: (Date) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("选择生日")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                // 日期选择器
                DatePicker(
                    "生日",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 12) {
                    Button(action: {
                        onSave(selectedDate)
                    }) {
                        Text("保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onCancel) {
                        Text("取消")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    BirthdayPickerView(
        selectedDate: .constant(Date()),
        onSave: { _ in },
        onCancel: { }
    )
}
