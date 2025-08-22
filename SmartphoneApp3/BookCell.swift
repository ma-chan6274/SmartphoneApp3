import SwiftUI

struct BookCell: View {
    let record: DayRecord
    let showFailedBooks: Bool // 設定：未達成日に倒れた本を表示するか
    let onLongPress: (() -> Void)?
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 木の棚の背景
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.5, green: 0.3, blue: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 65)
                .overlay(
                    // 木目のテクスチャ
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.4, green: 0.2, blue: 0.1), lineWidth: 2)
                )
                .overlay(
                    // 木の棚の溝
                    HStack {
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 1)
                        Spacer()
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 1)
                    }
                    .padding(.horizontal, 8)
                )
            
            if record.date != Date.distantPast {
                if record.shouldShowBook {
                    // 本を表示（失敗率に応じて崩れ具合を変える）
                    bookViewWithFailure
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                isAnimating = true
                            }
                        }
                } else if showFailedBooks && !record.sessions.isEmpty {
                    // 100%失敗の場合は空の棚を表示
                    EmptyView()
                }
            }
        }
        .onLongPressGesture {
            if record.date != Date.distantPast && !record.sessions.isEmpty {
                onLongPress?()
            }
        }
    }
    //waaaa
    private var bookViewWithFailure: some View {
        let failureRate = record.failureRate
        let tiltAngle = failureRate * 45.0 // 最大45度まで傾斜
        let opacity = 1.0 - (failureRate * 0.5) // 失敗率50%で半透明
        
        return bookView
            .rotationEffect(.degrees(tiltAngle), anchor: .bottom)
            .opacity(opacity)
            .offset(y: failureRate * 10) // 失敗率に応じて下にずらす
    }
    
    private var bookView: some View {
        ZStack {
            // 本の背表紙
            RoundedRectangle(cornerRadius: 4)
                .fill(bookGradient)
                .frame(width: 32, height: 48)
                .overlay(
                    // 本の背表紙の装飾
                    VStack(spacing: 3) {
                        // 上部の装飾ライン
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 24, height: 2)
                        
                        Spacer()
                        
                        // タイトル部分の模擬ライン
                        VStack(spacing: 1) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 20, height: 1)
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 16, height: 1)
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 18, height: 1)
                        }
                        
                        Spacer()
                        
                        // 下部の装飾ライン
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 20, height: 1)
                    }
                    .padding(.vertical, 6)
                )
            
            // 本の厚み（3D効果）
            RoundedRectangle(cornerRadius: 4)
                .fill(bookGradient.opacity(0.7))
                .frame(width: 34, height: 50)
                .offset(x: -2, y: 2)
                .zIndex(-1)
        }
        .shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 2)
    }
    
    private var failedBookView: some View {
        ZStack {
            // 倒れた本の背表紙
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.gradient)
                .frame(width: 32, height: 48)
                .overlay(
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 24, height: 2)
                        
                        Spacer()
                        
                        VStack(spacing: 1) {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 20, height: 1)
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 16, height: 1)
                        }
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 20, height: 1)
                    }
                    .padding(.vertical, 6)
                )
            
            // 倒れた本の厚み
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.gradient.opacity(0.5))
                .frame(width: 34, height: 50)
                .offset(x: -2, y: 2)
                .zIndex(-1)
        }
        .opacity(0.7)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
    }
    
    private var bookGradient: LinearGradient {
        switch record.bookType {
        case .none:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        case .normal:
            return LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .luxury:
            return LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .golden:
            return LinearGradient(
                colors: [Color.yellow, Color.orange],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    HStack {
        BookCell(
            record: DayRecord(date: Date(), studyTime: 0, requiredTime: 1800),
            showFailedBooks: true,
            onLongPress: nil
        )
        
        BookCell(
            record: DayRecord(date: Date(), studyTime: 2000, requiredTime: 1800),
            showFailedBooks: true,
            onLongPress: nil
        )
        
        BookCell(
            record: DayRecord(date: Date(), studyTime: 4000, requiredTime: 1800),
            showFailedBooks: true,
            onLongPress: nil
        )
        
        BookCell(
            record: DayRecord(date: Date(), studyTime: 8000, requiredTime: 1800),
            showFailedBooks: true,
            onLongPress: nil
        )
    }
    .padding()
}
