import Foundation

struct WeeklyGoal {
    let week: Date // その週の始まりの日
    var targetHours: TimeInterval // 週の目標時間
    var reflection: String = "" // 振り返り
    var positiveChecklist: [String] = [] // 追い風（良かったこと）のチェック項目
    var challengeChecklist: [String] = [] // 嵐（課題）のチェック項目
    
    var weekNumber: Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: week)
    }
    
    var weekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: week)!
        return week...endOfWeek
    }
}

class WeeklyManager: ObservableObject {
    @Published var weeklyGoals: [WeeklyGoal] = []
    
    private func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 月曜日を週の始まりに設定
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return startOfWeek
    }
    
    func getWeeklyGoal(for date: Date) -> WeeklyGoal? {
        let startOfWeek = startOfWeek(for: date)
        return weeklyGoals.first { Calendar.current.isDate($0.week, inSameDayAs: startOfWeek) }
    }
    
    func setWeeklyGoal(for date: Date, targetHours: TimeInterval) {
        let startOfWeek = startOfWeek(for: date)
        
        if let index = weeklyGoals.firstIndex(where: { Calendar.current.isDate($0.week, inSameDayAs: startOfWeek) }) {
            weeklyGoals[index].targetHours = targetHours
        } else {
            weeklyGoals.append(WeeklyGoal(week: startOfWeek, targetHours: targetHours))
        }
    }
    
    func updateReflection(for date: Date, reflection: String) {
        let startOfWeek = startOfWeek(for: date)
        
        if let index = weeklyGoals.firstIndex(where: { Calendar.current.isDate($0.week, inSameDayAs: startOfWeek) }) {
            weeklyGoals[index].reflection = reflection
        }
    }
    
    func updateChecklist(for date: Date, positive: [String], challenge: [String]) {
        let startOfWeek = startOfWeek(for: date)
        
        if let index = weeklyGoals.firstIndex(where: { Calendar.current.isDate($0.week, inSameDayAs: startOfWeek) }) {
            weeklyGoals[index].positiveChecklist = positive
            weeklyGoals[index].challengeChecklist = challenge
        } else {
            var newGoal = WeeklyGoal(week: startOfWeek, targetHours: 0)
            newGoal.positiveChecklist = positive
            newGoal.challengeChecklist = challenge
            weeklyGoals.append(newGoal)
        }
    }
    
    func getWeeklyProgress(for date: Date, monthShelf: MonthShelf) -> (current: TimeInterval, target: TimeInterval, percentage: Double) {
        guard let goal = getWeeklyGoal(for: date) else {
            return (0, 0, 0)
        }
        
        let calendar = Calendar.current
        let weekRange = goal.weekRange
        
        let weeklyTotal = monthShelf.records
            .filter { weekRange.contains($0.date) && $0.date != Date.distantPast }
            .reduce(0) { $0 + $1.studyTime }
        
        let percentage = goal.targetHours > 0 ? (weeklyTotal / goal.targetHours) * 100 : 0
        
        return (weeklyTotal, goal.targetHours, percentage)
    }
}

struct StudySession {
    let startTime: Date
    let duration: TimeInterval
    let targetDuration: TimeInterval
    let completed: Bool
    let endReason: EndReason
    
    enum EndReason {
        case completed
        case stopped
        case appClosed
    }
}

struct DayRecord {
    let date: Date
    var studyTime: TimeInterval // 集中時間（秒単位）
    let requiredTime: TimeInterval // 達成基準時間（秒単位）
    var sessions: [StudySession] = []
    
    var isAchieved: Bool {
        return studyTime >= requiredTime
    }
    
    var failureRate: Double {
        guard !sessions.isEmpty else { return 0.0 }
        let failedSessions = sessions.filter { !$0.completed }.count
        return Double(failedSessions) / Double(sessions.count)
    }
    
    var shouldShowBook: Bool {
        return failureRate < 1.0 && !sessions.isEmpty
    }
    
    var bookType: BookType {
        if !shouldShowBook {
            return .none
        } else if !isAchieved {
            return .none
        } else if studyTime >= 7200 { // 2時間以上
            return .golden
        } else if studyTime >= 3600 { // 1時間以上
            return .luxury
        } else {
            return .normal
        }
    }
}

enum BookType {
    case none        // 未達成
    case normal      // 30分-1時間
    case luxury      // 1-2時間
    case golden      // 2時間以上
}

class MonthShelf: ObservableObject {
    @Published var records: [DayRecord] = []
    let month: Date
    
    init(month: Date) {
        self.month = month
        generateMonthRecords()
    }
    
    private func generateMonthRecords() {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        
        records = (1...range.count).map { day in
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = day
            let date = calendar.date(from: components)!
            
            return DayRecord(
                date: date,
                studyTime: 0,
                requiredTime: 1800 // デフォルト30分
            )
        }
        
        // 28日に満たない場合は空のセルで埋める
        while records.count < 28 {
            records.append(DayRecord(
                date: Date.distantPast,
                studyTime: 0,
                requiredTime: 1800
            ))
        }
    }
    
    var totalStudyTime: TimeInterval {
        return records.reduce(0) { $0 + $1.studyTime }
    }
    
    var consecutiveDays: Int {
        var count = 0
        let sortedRecords = records.filter { $0.date != Date.distantPast }.sorted { $0.date < $1.date }
        
        for record in sortedRecords.reversed() {
            if record.isAchieved {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    func updateRecord(for date: Date, studyTime: TimeInterval) {
        if let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            records[index].studyTime = studyTime
        }
    }
    
    func addSession(for date: Date, session: StudySession) {
        if let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            records[index].sessions.append(session)
            if session.completed {
                records[index].studyTime += session.duration
            }
        }
    }
}