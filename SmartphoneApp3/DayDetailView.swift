import SwiftUI

struct DayDetailView: View {
    let dayRecord: DayRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 日付とサマリー
                    headerView
                    
                    // セッション一覧
                    if !dayRecord.sessions.isEmpty {
                        sessionListView
                    } else {
                        emptyStateView
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("詳細記録")
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
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateFormatter.string(from: dayRecord.date))
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("総集中時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(dayRecord.studyTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(dayRecord.isAchieved ? .green : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("目標時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(dayRecord.requiredTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(dayRecord.isAchieved ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            )
            
            if dayRecord.isAchieved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("目標達成！")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var sessionListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("セッション履歴")
                .font(.headline)
            
            ForEach(dayRecord.sessions.sorted { $0.startTime > $1.startTime }.indices, id: \.self) { index in
                let session = dayRecord.sessions.sorted { $0.startTime > $1.startTime }[index]
                sessionRowView(session: session)
            }
        }
    }
    
    private func sessionRowView(session: StudySession) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("開始: \(timeFormatter.string(from: session.startTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("実時間: \(formatTime(session.duration))")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("目標: \(formatTime(session.targetDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    statusBadge(for: session)
                    
                    if session.duration >= session.targetDuration {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("完了")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(session.completed ? Color.green : Color.orange)
                        .frame(
                            width: geometry.size.width * min(session.duration / session.targetDuration, 1.0),
                            height: 6
                        )
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            } else {
                HStack(spacing: 4) {
                    Text("失敗")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(endReasonText(session.endReason))
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .cornerRadius(8)
            }
        }
    }
    
    private func endReasonText(_ reason: StudySession.EndReason) -> String {
        switch reason {
        case .completed:
            return ""
        case .stopped:
            return "（停止）"
        case .appClosed:
            return "（終了）"
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("まだセッションがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("本をタップしてタイマーを開始しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
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
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    let sampleRecord = DayRecord(
        date: Date(),
        studyTime: 3600,
        requiredTime: 1800,
        sessions: [
            StudySession(
                startTime: Date().addingTimeInterval(-7200),
                duration: 1800,
                targetDuration: 1800,
                completed: true,
                endReason: .completed
            ),
            StudySession(
                startTime: Date().addingTimeInterval(-3600),
                duration: 900,
                targetDuration: 1800,
                completed: false,
                endReason: .stopped
            )
        ]
    )
    
    DayDetailView(dayRecord: sampleRecord)
}