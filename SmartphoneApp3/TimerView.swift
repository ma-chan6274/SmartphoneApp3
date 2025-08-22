import SwiftUI

struct TimerView: View {
    let selectedDate: Date
    let monthShelf: MonthShelf
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetDuration: TimeInterval = 1800 // 30分
    @State private var currentTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var startTime: Date?
    @State private var showingAlert = false
    @State private var showingTodayRecord = false
    
    private let timeOptions: [TimeInterval] = [900, 1800, 2700, 3600, 5400, 7200]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 開いた本の背景
                openBookBackground
                
                HStack(spacing: 0) {
                    // 左ページ - タイマーと制御
                    leftPage
                    
                    // 本の中央の境界線
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 2)
                    
                    // 右ページ - セッション履歴
                    rightPage
                }
            }
            .navigationTitle("航海時間")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        if isRunning {
                            showingAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("タイマー実行中", isPresented: $showingAlert) {
                Button("停止して戻る", role: .destructive) {
                    stopTimer()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("タイマーを停止しますか？停止すると失敗として記録されます。")
            }
            .onDisappear {
                if isRunning {
                    // アプリ終了時の失敗記録
                    recordFailedSession(reason: .appClosed)
                }
            }
            .sheet(isPresented: $showingTodayRecord) {
                TodayRecordView(
                    selectedDate: selectedDate,
                    monthShelf: monthShelf
                )
            }
        }
    }
    
    private var openBookBackground: some View {
        ZStack {
            // 本の厚み部分
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.85, green: 0.7, blue: 0.5))
                .aspectRatio(0.8, contentMode: .fit) // 縦長に変更
                .offset(x: 3, y: 3)
            
            // 本のカバー外装

            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                .aspectRatio(contentMode: .fit) // 縦長に変更
                //.overlay(
                    // 装飾的な枠
                   // RoundedRectangle(cornerRadius: 14)
                       // .stroke(Color(red: 0.4, green: 0.2, blue: 0.1), lineWidth: 2)
                       // .padding(6)
                //)
                .offset(x: 1.5, y: 1.5)
            
            // 本のページ部分
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                .aspectRatio(0.8, contentMode: .fit) // 縦長に変更
                //.overlay(
                    // 本の中央の境界線強調
                    //Rectangle()
                       // .fill(Color.black.opacity(0.1))
                        //.frame(width: 2)
                //)
        }
        .shadow(color: .black.opacity(0.3), radius: 12, x: 6, y: 6)
    }
    
    private var dateFormatter: DateFormatter {
          let formatter = DateFormatter()
          formatter.dateFormat = "M月d日(E)"
          formatter.locale = Locale(identifier: "ja_JP")
          return formatter
      }
    
    private var leftPage: some View {
        HStack(spacing: 25) { // ← VStack → HStack に変更
            // ページタイトル
            VStack(spacing: 8) {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                
                Divider()
                    .background(Color.brown)
            }
            .frame(width: 100) // 横並び用に幅を指定
            
            // 目標時間選択
            if !isRunning {
                VStack(spacing: 12) {
                    Text("航海予定時間")
                        .font(.headline)
                        .foregroundColor(.brown)
                    
                    Picker("目標時間", selection: $targetDuration) {
                        ForEach(timeOptions, id: \.self) { time in
                            Text(formatTime(time))
                                .tag(time)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
                .frame(width: 120) // 横並びでコンパクトに
            }
            
            // タイマー表示
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .stroke(Color.brown.opacity(0.3), lineWidth: 6)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: min(currentTime / targetDuration, 1.0))
                        .stroke(
                            currentTime >= targetDuration ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: currentTime)
                    
                    VStack(spacing: 6) {
                        Text(formatTime(currentTime))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                        
                        Text("/ \(formatTime(targetDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if currentTime >= targetDuration {
                            Text("達成！")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 制御ボタン
                HStack(spacing: 20) {
                    Button(action: isRunning ? stopTimer : startTimer) {
                        HStack(spacing: 6) {
                            Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            Text(isRunning ? "停止" : "開始")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 36)
                        .background(isRunning ? Color.red : Color.blue)
                        .cornerRadius(18)
                    }
                    
                    if isRunning {
                        Button(action: pauseTimer) {
                            HStack(spacing: 6) {
                                Image(systemName: "pause.fill")
                                Text("一時停止")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 36)
                            .background(Color.orange)
                            .cornerRadius(18)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(pageLines)
    }

    
    private var rightPage: some View {
        VStack(spacing: 20) {
            
            // 冒険記録への移動ボタン
            Button(action: { showingTodayRecord = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                    Text("冒険記録")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.brown)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(pageLines)
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
    

    private func startTimer() {
        isRunning = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime += 1
        }
    }
    
    private func stopTimer() {
        guard let startTime = startTime else { return }
        
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        recordFailedSession(reason: .stopped)
        resetTimer()
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func recordFailedSession(reason: StudySession.EndReason) {
        guard let startTime = startTime else { return }
        
        let session = StudySession(
            startTime: startTime,
            duration: currentTime,
            targetDuration: targetDuration,
            completed: currentTime >= targetDuration,
            endReason: reason
        )
        
        monthShelf.addSession(for: selectedDate, session: session)
    }
    
    private func resetTimer() {
        currentTime = 0
        startTime = nil
    }
    
//    private var timeFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        formatter.locale = Locale(identifier: "ja_JP")
//        return formatter
//    }
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}



#Preview {
    TimerView(
        selectedDate: Date(),
        monthShelf: MonthShelf(month: Date())
    )
}
