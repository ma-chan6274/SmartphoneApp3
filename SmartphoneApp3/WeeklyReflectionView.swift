import SwiftUI

struct WeeklyReflectionView: View {
    let selectedDate: Date
    let weeklyManager: WeeklyManager
    let monthShelf: MonthShelf
    @Environment(\.dismiss) private var dismiss
    
    @State private var reflection: String = ""
    @State private var showingSaveAlert = false
    @State private var selectedPositiveItems: Set<String> = []
    @State private var selectedChallengeItems: Set<String> = []
    
    // チェックリスト項目
    private let positiveItems = [
        "集中時間が伸びた",
        "集中の質が良かった（深く入れた）",
        "気分がよかった",
        "周りに邪魔されなかった",
        "早起きできた",
        "始めるまでが早かった",
        "休憩の取り方がうまくいった",
        "新しい工夫がうまくハマった",
        "難しい部分を突破できた",
        "気づいたら集中していた",
        "前よりも長く続けられた",
        "集中する習慣が定着してきた",
        "ご褒美を楽しめた",
        "体調がよかった",
        "気分転換がうまくいった"
    ]
    
    private let challengeItems = [
        "スマホを触ってしまった",
        "集中が続かなかった",
        "眠かった／疲れていた",
        "他の予定に流された",
        "気持ちが乗らなかった",
        "始めるまでに時間がかかった",
        "同じことを繰り返して飽きた",
        "休憩が長すぎた",
        "誘惑に負けた（動画・SNSなど）",
        "雑音や環境に集中を邪魔された",
        "体調がよくなかった",
        "優先順位を間違えた",
        "ゴールがぼやけていた"
    ]
    
    private var weekProgress: (current: TimeInterval, target: TimeInterval, percentage: Double) {
        weeklyManager.getWeeklyProgress(for: selectedDate, monthShelf: monthShelf)
    }
    
    private var weekRange: String {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 日曜始まり
        
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday - 1
        let sundayStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!
        
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: sundayStart)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        
        return "\(formatter.string(from: sundayStart)) - \(formatter.string(from: endOfWeek))"
    }

    
    var body: some View {
        NavigationView {
            ZStack {
                // 本のページ背景（2ページ目）
                pageBackground
                
                ScrollView {
                    VStack(spacing: 25) {
                        // ヘッダー
                        VStack(spacing: 8) {
                            Text("週間振り返り")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.brown)
                            
                            Text(weekRange)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // 達成度円グラフ
                        achievementCircleView
                        
                        // 統計情報
                        weeklyStatsView
                        
                        // チェックリスト
                        checklistView
                        
                        // 振り返り入力
                        reflectionInputView
                        
                        // 保存ボタン
                        Button(action: saveReflection) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("振り返りを保存")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(25)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("週間振り返り")
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
                selectedPositiveItems = Set(existingGoal.positiveChecklist)
                selectedChallengeItems = Set(existingGoal.challengeChecklist)
            }
        }
    }
    
    private var pageBackground: some View {
        ZStack {
            // ページの背景（右ページ）
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                .aspectRatio(1.6, contentMode: .fit) // 横長の本の比率
                .shadow(color: .black.opacity(0.1), radius: 5, x: -2, y: 2)
            
            // ページの線
            VStack(spacing: 24) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 40)
            
            // 右端のマージン線
            HStack {
                Spacer()
                
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 1)
                    .padding(.trailing, 30)
            }
        }
    }
    
    private var achievementCircleView: some View {
        VStack(spacing: 16) {
            Text("週間達成度")
                .font(.headline)
                .foregroundColor(.brown)
            
            ZStack {
                // 背景の円
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // 進捗の円
                Circle()
                    .trim(from: 0, to: min(weekProgress.percentage / 100, 1.0))
                    .stroke(
                        weekProgress.percentage >= 100 ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: weekProgress.percentage)
                
                // 中央のパーセンテージ
                VStack(spacing: 4) {
                    Text("\(Int(weekProgress.percentage))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(weekProgress.percentage >= 100 ? .green : .blue)
                    
                    Text("達成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var weeklyStatsView: some View {
        VStack(spacing: 16) {
            Text("今週の記録")
                .font(.headline)
                .foregroundColor(.brown)
            
            HStack(spacing: 20) {
                statCard(
                    title: "実績時間",
                    value: formatTime(weekProgress.current),
                    color: .blue
                )
                
                statCard(
                    title: "目標時間",
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
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var checklistView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 追い風（良かったこと）
            VStack(alignment: .leading, spacing: 8) {
                Text("追い風（良かったこと）")
                    .font(.headline)
                    .foregroundColor(.green)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(positiveItems, id: \.self) { item in
                        checklistRow(
                            item: item,
                            isSelected: selectedPositiveItems.contains(item),
                            color: .green
                        ) {
                            if selectedPositiveItems.contains(item) {
                                selectedPositiveItems.remove(item)
                            } else {
                                selectedPositiveItems.insert(item)
                            }
                        }
                    }
                }
            }
            
            // 嵐（課題）
            VStack(alignment: .leading, spacing: 8) {
                Text("嵐（課題）")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(challengeItems, id: \.self) { item in
                        checklistRow(
                            item: item,
                            isSelected: selectedChallengeItems.contains(item),
                            color: .orange
                        ) {
                            if selectedChallengeItems.contains(item) {
                                selectedChallengeItems.remove(item)
                            } else {
                                selectedChallengeItems.insert(item)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func checklistRow(item: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? color : .gray)
                    .font(.system(size: 14))
                
                Text(item)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var reflectionInputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の振り返り")
                .font(.headline)
                .foregroundColor(.brown)
            
            TextEditor(text: $reflection)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    // プレースホルダー
                    Group {
                        if reflection.isEmpty {
                            Text("今週の学習はどうでしたか？\n良かった点や改善点を書いてみましょう。")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
    
    private func saveReflection() {
        weeklyManager.updateReflection(for: selectedDate, reflection: reflection)
        weeklyManager.updateChecklist(
            for: selectedDate,
            positive: Array(selectedPositiveItems),
            challenge: Array(selectedChallengeItems)
        )
        showingSaveAlert = true
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
    WeeklyReflectionView(
        selectedDate: Date(),
        weeklyManager: WeeklyManager(),
        monthShelf: MonthShelf(month: Date())
    )
}
