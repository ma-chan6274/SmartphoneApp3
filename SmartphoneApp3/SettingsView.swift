import SwiftUI

struct SettingsView: View {
    @Binding var showFailedBooks: Bool
    @Binding var requiredTime: TimeInterval
    @Environment(\.dismiss) private var dismiss
    
    private let timeOptions: [TimeInterval] = [900, 1800, 2700, 3600, 5400, 7200] // 15分〜2時間
    
    var body: some View {
        NavigationView {
            Form {
                Section("表示設定") {
                    Toggle("未達成日に倒れた本を表示", isOn: $showFailedBooks)
                        .toggleStyle(SwitchToggleStyle())
                }
                
                Section("達成基準") {
                    Picker("一日の目標時間", selection: $requiredTime) {
                        ForEach(timeOptions, id: \.self) { time in
                            Text(formatTime(time))
                                .tag(time)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("本の種類") {
                    VStack(alignment: .leading, spacing: 12) {
                        bookTypeRow(
                            color: .blue,
                            title: "普通の本",
                            description: "30分〜1時間未満"
                        )
                        
                        bookTypeRow(
                            color: .purple,
                            title: "豪華な本",
                            description: "1時間〜2時間未満"
                        )
                        
                        bookTypeRow(
                            color: .yellow,
                            title: "金色の本",
                            description: "2時間以上"
                        )
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func bookTypeRow(color: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(color.gradient)
                .frame(width: 20, height: 30)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes > 0 ? "\(minutes)分" : "")"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    SettingsView(
        showFailedBooks: .constant(true),
        requiredTime: .constant(1800)
    )
}