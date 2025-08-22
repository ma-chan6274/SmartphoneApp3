import SwiftUI

struct WeeklyGoalRecordView: View {
    let selectedDate: Date
    let weeklyManager: WeeklyManager
    let monthShelf: MonthShelf
    @Environment(\.dismiss) private var dismiss
    
    @State private var reflection: String = ""
    @State private var showingSaveAlert = false
    
    private var weekProgress: (current: TimeInterval, target: TimeInterval, percentage: Double) {
        weeklyManager.getWeeklyProgress(for: selectedDate, monthShelf: monthShelf)
    }
    
    private var weekRange: String {
        let calendar = Calendar.current
        
        // selectedDate の曜日を取得（日曜=1 ... 土曜=7）
        let weekday = calendar.component(.weekday, from: selectedDate)
        
        // 土曜始まりにするため「選択日から何日前が土曜か」を計算
        let daysToSubtract = weekday == 7 ? 0 : weekday
        let saturdayStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!
        
        // endOfWeek（土曜から6日後 → 金曜）
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: saturdayStart)!
        
        // フォーマッター
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        
        return "\(formatter.string(from: saturdayStart)) - \(formatter.string(from: endOfWeek))"
    }

    private var weeklyDayRecords: [DayRecord] {
        var calendar = Calendar.current
        calendar.firstWeekday = 7 // 土曜始まり

        // selectedDate の曜日を取得（日曜=1 ... 土曜=7）
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday == 7 ? 0 : weekday
        let saturdayStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!
        
        var records: [DayRecord] = []
        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: saturdayStart) {
                if let record = monthShelf.records.first(where: { calendar.isDate($0.date, inSameDayAs: dayDate) }) {
                    records.append(record)
                } else {
                    // 記録がない日も空の DayRecord を作る場合はこちら
                    // records.append(DayRecord(date: dayDate, studyTime: 0, isAchieved: false))
                }
            }
        }
        return records
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 本のページ背景
                pageBackground
                
                HStack(spacing: 0) {
                    // 左ページ - 達成度と統計
                    leftPage
                    
                    // 本の中央の境界線
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 2)
                    
                    // 右ページ - 日別記録と振り返り
                    rightPage
                }
            }
            .navigationTitle("週間記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("振り返りを保存しました。")
        }
        .onAppear {
            if let existingGoal = weeklyManager.getWeeklyGoal(for: selectedDate) {
                reflection = existingGoal.reflection
            }
        }
    }
    
    private var pageBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
            .aspectRatio(1.6, contentMode: .fit) // 横長の本の比率
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    private var leftPage: some View {
        VStack(spacing: 25) {
            // ページタイトル
            VStack(spacing: 8) {
                Text("週間達成度")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                
                Text(weekRange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .background(Color.brown)
            }
            
            // 達成度円グラフ
            achievementCircleView
            
            // 統計情報
            weeklyStatsView
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(pageLines)
    }
    
    private var rightPage: some View {
        VStack(spacing: 20) {
            // ページタイトル
            VStack(spacing: 8) {
                Text("日別記録")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                
                Divider()
                    .background(Color.brown)
            }
            
            // 日別記録一覧
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(weeklyDayRecords, id: \.date) { record in
                        dayRecordRow(record: record)
                    }
                }
            }
            .frame(maxHeight: 180)
            
            // 振り返り入力
            reflectionInputView
            
            // 保存ボタン
            Button(action: saveReflection) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                    Text("振り返り保存")
                }
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color.green)
                .cornerRadius(16)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(pageLines)
    }
    
    private var achievementCircleView: some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                .frame(width: 120, height: 120)
            
            // 進捗の円
            Circle()
                .trim(from: 0, to: min(weekProgress.percentage / 100, 1.0))
                .stroke(
                    weekProgress.percentage >= 100 ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: weekProgress.percentage)
            
            // 中央のパーセンテージ
            VStack(spacing: 4) {
                Text("\(Int(weekProgress.percentage))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(weekProgress.percentage >= 100 ? .green : .blue)
                
                Text("達成")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var weeklyStatsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                statCard(
                    title: "実績",
                    value: formatTime(weekProgress.current),
                    color: .blue
                )
                
                statCard(
                    title: "目標",
                    value: formatTime(weekProgress.target),
                    color: .gray
                )
            }
            
            if weekProgress.target > 0 {
                let remaining = max(0, weekProgress.target - weekProgress.current)
                if remaining > 0 {
                    statCard(
                        title: "残り時間",
                        value: formatTime(remaining),
                        color: .orange
                    )
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func dayRecordRow(record: DayRecord) -> some View {
        HStack(spacing: 8) {
            // 曜日
            Text(dayFormatter.string(from: record.date))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.brown)
                .frame(width: 30, alignment: .leading)
            
            // 日付
            Text(dateFormatter.string(from: record.date))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .leading)
            
            // 時間
            Text(formatTime(record.studyTime))
                .font(.caption)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            // 達成状況
            if record.isAchieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else if record.studyTime > 0 {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else {
                Image(systemName: "minus.circle")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(record.isAchieved ? Color.green.opacity(0.05) : Color.gray.opacity(0.03))
        )
    }
    
    private var reflectionInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("振り返り")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.brown)
            
            TextEditor(text: $reflection)
                .frame(height: 60)
                .padding(6)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    // プレースホルダー
                    Group {
                        if reflection.isEmpty {
                            Text("今週の振り返りを書いてください")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
    
    private var pageLines: some View {
        VStack(spacing: 20) {
            ForEach(0..<15, id: \.self) { _ in
                Rectangle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 20)
        .allowsHitTesting(false)
    }
    
    private func saveReflection() {
        weeklyManager.updateReflection(for: selectedDate, reflection: reflection)
        showingSaveAlert = true
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    WeeklyGoalRecordView(
        selectedDate: Date(),
        weeklyManager: WeeklyManager(),
        monthShelf: MonthShelf(month: Date())
    )
}
