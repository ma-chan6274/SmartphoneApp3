import SwiftUI

struct WeeklyGoalView: View {
    let selectedDate: Date
    let weeklyManager: WeeklyManager
    let monthShelf: MonthShelf
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetHours: Double = 10.0
    @State private var showingConfirmation = false
    @State private var showingWeeklyRecord = false
    
    private var weekRange: String {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 日曜始まりに明示設定

        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday - calendar.firstWeekday
        let sundayStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!

        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: sundayStart)!

        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")

        return "\(formatter.string(from: sundayStart)) - \(formatter.string(from: endOfWeek))"
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Text("週間目標設定")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.brown)
                        
                        Text(weekRange)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 目標時間設定
                    VStack(spacing: 20) {
                        Text("今週の目標時間")
                            .font(.headline)
                            .foregroundColor(.brown)
                        
                        VStack(spacing: 12) {
                            Text("\(Int(targetHours))時間")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            
                            Slider(
                                value: $targetHours,
                                in: 1...50,
                                step: 1
                            ) {
                                Text("目標時間")
                            }
                            .tint(.blue)
                            .padding(.horizontal)
                        }
                        
                        Text("1日平均: \(String(format: "%.1f", targetHours / 7))時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // 設定ボタン
                    Button(action: setWeeklyGoal) {
                        HStack {
                            Image(systemName: "target")
                            Text("目標を設定")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                    
                    // 週間記録ボタン
                    Button(action: { showingWeeklyRecord = true }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("週間記録を見る")
                        }
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                }
                .padding()
            }
            .background(pageBackground)
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("目標を設定しました", isPresented: $showingConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("今週の目標時間を\(Int(targetHours))時間に設定しました。")
            }
            .onAppear {
                if let existingGoal = weeklyManager.getWeeklyGoal(for: selectedDate) {
                    targetHours = existingGoal.targetHours / 3600
                }
            }
            .sheet(isPresented: $showingWeeklyRecord) {
                WeeklyGoalRecordView(
                    selectedDate: selectedDate,
                    weeklyManager: weeklyManager,
                    monthShelf: monthShelf
                )
            }
        }
    }
    
    private var pageBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.85, green: 0.7, blue: 0.5))
                .aspectRatio(0.8, contentMode: .fit)
                .offset(x: 3, y: 3)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                .aspectRatio(0.8, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.4, green: 0.2, blue: 0.1), lineWidth: 2)
                        .padding(6)
                )
                .offset(x: 1.5, y: 1.5)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                .aspectRatio(0.8, contentMode: .fit)
            
            VStack(spacing: 24) {
                ForEach(0..<15, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 40)
            
            HStack {
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 1)
                    .padding(.leading, 30)
                Spacer()
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 12, x: 6, y: 6)
    }
    
    private func setWeeklyGoal() {
        weeklyManager.setWeeklyGoal(for: selectedDate, targetHours: targetHours * 3600)
        showingConfirmation = true
    }
}

#Preview {
    WeeklyGoalView(
        selectedDate: Date(),
        weeklyManager: WeeklyManager(),
        monthShelf: MonthShelf(month: Date())
    )
}
