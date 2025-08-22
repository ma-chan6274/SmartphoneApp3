import SwiftUI

struct TodayRecordView: View {
    let selectedDate: Date
    let monthShelf: MonthShelf
    @Environment(\.dismiss) private var dismiss
    
    private var todayRecord: DayRecord? {
        monthShelf.records.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private var todaySessions: [StudySession] {
        todayRecord?.sessions.sorted { $0.startTime > $1.startTime } ?? []
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 開いた本の背景
                openBookBackground
                
                HStack(spacing: 0) {
                    // 左ページ - 今日の統計
                    leftPage
                    
                    // 本の中央の境界線
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 2)
                    
                    // 右ページ - セッション詳細
                    rightPage
                }
            }
            .navigationTitle("冒険記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var openBookBackground: some View {
        ZStack {
            // 本の厚み部分
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.85, green: 0.7, blue: 0.5))
                .aspectRatio(0.8, contentMode: .fit)
                .offset(x: 3, y: 3)
            
            // 本のカバー外装
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                .aspectRatio(0.8, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.4, green: 0.2, blue: 0.1), lineWidth: 2)
                        .padding(6)
                )
                .offset(x: 1.5, y: 1.5)
            
            // 本のページ部分
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                .aspectRatio(0.8, contentMode: .fit)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 2)
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 12, x: 6, y: 6)
    }
    
    private var leftPage: some View {
        VStack(spacing: 25) {
            // ページタイトル
            VStack(spacing: 8) {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                
                Divider()
                    .background(Color.brown)
            }
            
            // 達成状況
            achievementStatusView
            
            // 統計カード
            statisticsCardsView
            
            // 今日の進捗グラフ
            progressChartView
            
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
                Text("冒険の記録")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                
                Divider()
                    .background(Color.brown)
            }
            
            // セッション履歴
            if !todaySessions.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(todaySessions.indices, id: \.self) { index in
                            let session = todaySessions[index]
                            detailedSessionRow(session: session, index: index + 1)
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.brown.opacity(0.6))
                    
                    Text("今日はまだ\nセッションがありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(pageLines)
    }
    
    private var achievementStatusView: some View {
        VStack(spacing: 12) {
            if let record = todayRecord {
                if record.isAchieved {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        
                        Text("目標達成！")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        
                        Text("継続中...")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((todayRecord?.isAchieved == true) ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((todayRecord?.isAchieved == true) ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var statisticsCardsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    title: "総時間",
                    value: formatTime(todayRecord?.studyTime ?? 0),
                    color: .blue
                )
                
                statCard(
                    title: "目標時間",
                    value: formatTime(todayRecord?.requiredTime ?? 1800),
                    color: .gray
                )
            }
            
            HStack(spacing: 12) {
                statCard(
                    title: "成功",
                    value: "\(todaySessions.filter { $0.completed }.count)",
                    color: .green
                )
                
                statCard(
                    title: "失敗",
                    value: "\(todaySessions.filter { !$0.completed }.count)",
                    color: .red
                )
            }
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var progressChartView: some View {
        VStack(spacing: 12) {
            Text("進捗")
                .font(.headline)
                .foregroundColor(.brown)
            
            if let record = todayRecord {
                ZStack {
                    Circle()
                        .stroke(Color.brown.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: min(record.studyTime / record.requiredTime, 1.0))
                        .stroke(
                            record.isAchieved ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: record.studyTime)
                    
                    Text("\(Int((record.studyTime / record.requiredTime) * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(record.isAchieved ? .green : .blue)
                }
            }
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
    
    private func detailedSessionRow(session: StudySession, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("セッション \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                
                Spacer()
                
                statusBadge(for: session)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("開始:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeFormatter.string(from: session.startTime))
                        .font(.caption)
                }
                
                HStack {
                    Text("時間:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(session.duration))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("目標:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(session.targetDuration))
                        .font(.caption)
                }
            }
            
            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(session.completed ? Color.green : Color.orange)
                        .frame(
                            width: geometry.size.width * min(session.duration / session.targetDuration, 1.0),
                            height: 4
                        )
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            session.completed ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func statusBadge(for session: StudySession) -> some View {
        Group {
            if session.completed {
                Text("成功")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(4)
            } else {
                HStack(spacing: 2) {
                    Text("失敗")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    
                    Text(endReasonText(session.endReason))
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red)
                .cornerRadius(4)
            }
        }
    }
    
    private func endReasonText(_ reason: StudySession.EndReason) -> String {
        switch reason {
        case .completed:
            return ""
        case .stopped:
            return "(停止)"
        case .appClosed:
            return "(終了)"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
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
    TodayRecordView(
        selectedDate: Date(),
        monthShelf: MonthShelf(month: Date())
    )
}