import SwiftUI

struct BookshelfView: View {
    @StateObject private var monthShelf = MonthShelf(month: Date())
    @StateObject private var weeklyManager = WeeklyManager()
    @State private var currentMonth = Date()
    @State private var showFailedBooks = true
    @State private var requiredTime: TimeInterval = 1800
    @State private var showingSettings = false
    @State private var selectedDate: Date?
    @State private var showingTimer = false
    @State private var selectedRecord: DayRecord?
    @State private var showingDetail = false
    @State private var showingWeeklyGoal = false
    @State private var showingWeeklyReflection = false
    @State private var selectedTab: Int = 0
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                bookshelfTabView
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("本棚")
                    }
                    .tag(0)
                
                graphTabView
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("グラフ")
                    }
                    .tag(1)
            }
            .navigationTitle(selectedTab == 0 ? "読書記録" : "月別グラフ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("設定") { showingSettings = true }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(showFailedBooks: $showFailedBooks, requiredTime: $requiredTime)
            }
            .sheet(isPresented: $showingTimer) {
                if let selectedDate = selectedDate {
                    TimerView(selectedDate: selectedDate, monthShelf: monthShelf)
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let selectedRecord = selectedRecord {
                    DayDetailView(dayRecord: selectedRecord)
                }
            }
            .sheet(isPresented: $showingWeeklyGoal) {
                if let selectedDate = selectedDate {
                    WeeklyGoalView(selectedDate: selectedDate, weeklyManager: weeklyManager, monthShelf: monthShelf)
                }
            }
            .sheet(isPresented: $showingWeeklyReflection) {
                if let selectedDate = selectedDate {
                    WeeklyReflectionPagesView(selectedDate: selectedDate, weeklyManager: weeklyManager, monthShelf: monthShelf)
                }
            }
        }
    }
    
    // MARK: - タブビュー
    private var bookshelfTabView: some View {
        VStack(spacing: 20) {
            monthHeader
            bookshelfGrid
            statisticsView
            Spacer()
        }
        .padding()
    }
    
    private var graphTabView: some View {
        monthlyGraphView
    }
    
    // MARK: - 月別グラフ表示
    private var monthlyGraphView: some View {
        VStack(spacing: 20) {
            monthHeader
            graphContentView
            Spacer()
        }
        .padding()
    }
    
    private var graphContentView: some View {
        VStack(spacing: 16) {
            Text("月別集中時間")
                .font(.headline)
                .foregroundColor(.brown)
            
            monthlyChart
            graphStatisticsView
        }
        .padding()
        .background(graphBackground)
        .padding(.horizontal)
    }
    
    private var graphBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.brown.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brown.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var graphStatisticsView: some View {
        VStack(spacing: 12) {
            HStack {
                graphStatCard(title: "総時間", value: formatTime(monthShelf.totalStudyTime), color: .blue)
                graphStatCard(title: "平均/日", value: formatTime(monthShelf.totalStudyTime / Double(max(monthShelf.records.count, 1))), color: .green)
            }
            HStack {
                graphStatCard(title: "達成日数", value: "\(monthShelf.records.filter { $0.isAchieved }.count)日", color: .orange)
                graphStatCard(title: "達成率", value: String(format: "%.1f%%", Double(monthShelf.records.filter { $0.isAchieved }.count) / max(Double(monthShelf.records.count), 1) * 100), color: .purple)
            }
        }
    }
    
    // グラフ描画
    private var monthlyChart: some View {
        let maxTime: TimeInterval = 20 * 3600 // 20時間をY軸の最大値とする
        let records = monthShelf.records.sorted { $0.date < $1.date }
        
        return ZStack {
            // グリッド線
            VStack(spacing: 0) {
                ForEach(0..<5) { i in
                    HStack {
                        Text("\(20 - i * 4)h")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 25, alignment: .trailing)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 0.5)
                    }
                    .frame(height: 40)
                }
            }
            
            // データプロット
            GeometryReader { geometry in
                let chartWidth = geometry.size.width - 30
                let chartHeight = geometry.size.height
                
                Path { path in
                    if !records.isEmpty {
                        for (index, record) in records.enumerated() {
                            let x = 30 + (chartWidth / CGFloat(max(records.count - 1, 1))) * CGFloat(index)
                            let y = chartHeight - (chartHeight * CGFloat(min(record.studyTime / maxTime, 1.0)))
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // データポイント
                ForEach(records.indices, id: \.self) { index in
                    let record = records[index]
                    let x = 30 + (chartWidth / CGFloat(max(records.count - 1, 1))) * CGFloat(index)
                    let y = chartHeight - (chartHeight * CGFloat(min(record.studyTime / maxTime, 1.0)))
                    
                    Circle()
                        .fill(record.isAchieved ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(height: 200)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func graphStatCard(title: String, value: String, color: Color) -> some View {
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
    
    // MARK: - 月表示
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            Spacer()
            Text(monthFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 曜日ラベル付きグリッド
    private var bookshelfGrid: some View {
        let dates = generateDatesForMonth(currentMonth)
        
        // 前後月のデータも取得
        let previousMonthShelf = MonthShelf(month: Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!)
        let nextMonthShelf = MonthShelf(month: Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!)
        let allRecords = previousMonthShelf.records + monthShelf.records + nextMonthShelf.records
        
        return VStack(spacing: 4) {
            // 曜日ラベル（日曜日左端、土曜日右端）
            HStack(spacing: 0) {
                let weekdays = ["日","月","火","水","木","金","土"]
                ForEach(0..<weekdays.count, id: \.self) { index in
                    Text(weekdays[index])
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(index == 0 ? .red : (index == 6 ? .blue : .black))
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    
                    if let record = allRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                        BookCell(record: record, showFailedBooks: showFailedBooks) {
                            selectedRecord = record
                            showingDetail = true
                        }
                        .onTapGesture {
                            selectedDate = date
                            let weekday = calendar.component(.weekday, from: date)
                            if weekday == 2 { showingWeeklyGoal = true }
                            else if weekday == 1 { showingWeeklyReflection = true }
                            else { showingTimer = true }
                        }
                        .opacity(isCurrentMonth ? 1.0 : 0.3) // 前後月は半透明
                    } else {
                        Rectangle()
                            .fill(isCurrentMonth ? Color.brown.opacity(0.1) : Color.gray.opacity(0.1))
                            .frame(height: 60)
                            .cornerRadius(4)
                            .opacity(isCurrentMonth ? 1.0 : 0.3)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brown.opacity(0.1))
                    .padding(-8)
            )
        }
    }
    
    // MARK: - 統計表示
    private var statisticsView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今月の総集中時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(monthShelf.totalStudyTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("連続達成日数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(monthShelf.consecutiveDays)日")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - 日付操作
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            let newShelf = MonthShelf(month: currentMonth)
            monthShelf.records = newShelf.records
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            let newShelf = MonthShelf(month: currentMonth)
            monthShelf.records = newShelf.records
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }
}

// MARK: - カレンダー日付生成（日曜始まり）
func generateDatesForMonth(_ month: Date) -> [Date] {
    var calendar = Calendar.current
    calendar.firstWeekday = 1 // 日曜始まりに設定
    
    // その月の最初と最後の日を取得
    guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
          let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
    
    let lastDay = calendar.date(byAdding: .day, value: range.count - 1, to: firstDay)!
    
    // --- startOfWeek（日曜に補正）---
    let firstWeekday = calendar.component(.weekday, from: firstDay)
    let daysToSubtract = firstWeekday - 1   // 日曜=1 → 0日戻す, 月曜=2 → 1日戻す
    let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDay)!
    
    // --- endOfWeek（土曜に補正）---
    let lastWeekday = calendar.component(.weekday, from: lastDay)
    let daysToAdd = 7 - lastWeekday        // 土曜=7 → 0日進める, 金曜=6 → 1日進める
    let endOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: lastDay)!
    
    // --- 日付リストを生成 ---
    var dates: [Date] = []
    var current = startOfWeek
    while current <= endOfWeek {
        dates.append(current)
        current = calendar.date(byAdding: .day, value: 1, to: current)!
    }
    return dates
}
