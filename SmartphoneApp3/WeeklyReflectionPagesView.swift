import SwiftUI

struct WeeklyReflectionPagesView: View {
    let selectedDate: Date
    let weeklyManager: WeeklyManager
    let monthShelf: MonthShelf
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    @State private var reflection: String = ""
    @State private var selectedPositiveItems: Set<String> = []
    @State private var selectedChallengeItems: Set<String> = []
    @State private var showingSaveAlert = false
    
    // チェックリスト項目
    private let positiveItems = [
        "集中時間が伸びた", "集中の質が良かった（深く入れた）", "気分がよかった",
        "周りに邪魔されなかった", "早起きできた", "始めるまでが早かった",
        "休憩の取り方がうまくいった", "新しい工夫がうまくハマった", "難しい部分を突破できた",
        "気づいたら集中していた", "前よりも長く続けられた", "集中する習慣が定着してきた",
        "ご褒美を楽しめた", "体調がよかった", "気分転換がうまくいった"
    ]
    
    private let challengeItems = [
        "スマホを触ってしまった", "集中が続かなかった", "眠かった／疲れていた",
        "他の予定に流された", "気持ちが乗らなかった", "始めるまでに時間がかかった",
        "同じことを繰り返して飽きた", "休憩が長すぎた", "誘惑に負けた（動画・SNSなど）",
        "雑音や環境に集中を邪魔された", "体調がよくなかった", "優先順位を間違えた", "ゴールがぼやけていた"
    ]
    
    // 日曜始まりの週範囲
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
    
    // 日曜始まりで1週間分のレコード
    private var weeklyDayRecords: [DayRecord] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 日曜始まり
        
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday - 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!
        
        var records: [DayRecord] = []
        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek),
               let record = monthShelf.records.first(where: { calendar.isDate($0.date, inSameDayAs: dayDate) }) {
                records.append(record)
            }
        }
        return records
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                bookBackground
                //              pageContent
            }
            .navigationTitle("週間振り返り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentPage == 4 {
                        //                   Button("保存") { saveAll() }
                    }
                }
            }
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("振り返りを保存しました。")
        }
        .onAppear {
            //       loadExistingData()
        }
    }
    
    // --- 背景 ---
    private var bookBackground: some View {
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
}
    // --- ページ切替 ---
//  @ViewBuilder
      //  private var pageContent: some View {
          // switch currentPage {
          // case 0: achievementPage
    //       // case 1: weeklyRecordsPage
    ////        case 2: navigationRecordPage
    ////        case 3: positivePage
    ////        case 4: challengePage
    ////        default: achievementPage
    //        }
    //    }
    
    // 以下、achievementPage, weeklyRecordsPage, navigationRecordPage, positivePage, challengePage
    // 及び共通コンポーネント・チェックリスト・保存処理は以前のまま
    // ただしweeklyDayRecordsとweekRangeが日曜始まりになったことで、UIも日曜スタートで正しく表示されます。
    //
    //    private func loadExistingData() {
    //        if let existingGoal = weeklyManager.getWeeklyGoal(for: selectedDate) {
    //            reflection = existingGoal.reflection
    //            selectedPositiveItems = Set(existingGoal.positiveChecklist)
    //            selectedChallengeItems = Set(existingGoal.challengeChecklist)
    //        }
    //    }
    //
    //    private func saveAll() {
    //        weeklyManager.updateReflection(for: selectedDate, reflection: reflection)
    //        weeklyManager.updateChecklist(
    //            for: selectedDate,
    //            positive: Array(selectedPositiveItems),
    //            challenge: Array(selectedChallengeItems)
    //        )
    //        showingSaveAlert = true
    //    }
    
    //    private func toggleItem(_ item: String, in set: inout Set<String>) -> Return Type
    
    //        if set.contains(item) { set.remove(item) }
    //        else { set.insert(item) }
    //    }
    //
    //    private var dayFormatter: DateFormatter {
    //        let formatter = DateFormatter()
    //        formatter.dateFormat = "E"
    //        formatter.locale = Locale(identifier: "ja_JP")
    //        return formatter
    //    }
    //
    //    private func formatTime(_ timeInterval: TimeInterval) -> String {
    //        let hours = Int(timeInterval) / 3600
    //        let minutes = (Int(timeInterval) % 3600) / 60
    //        if hours > 0 { return "\(hours)時間\(minutes > 0 ? "\(minutes)分" : "")" }
    //        else { return "\(minutes)分" }
    //    }
    //}
    //
#Preview {
    WeeklyReflectionPagesView(
        selectedDate: Date(),
        weeklyManager: WeeklyManager(),
        monthShelf: MonthShelf(month: Date())
    )
}
