import SwiftUI
import Foundation

struct DateRangePickerView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedRanges: [BookingRange]
    let calendar: Calendar

    @State private var currentMonth: Date = Date()

    var body: some View {
        VStack(spacing: 12) {
            monthNavigation

            LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 36)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)

                    DayView(
                        date: date,
                        startDate: $startDate,
                        endDate: $endDate,
                        bookedRanges: bookedRanges,
                        currentMonth: currentMonth,
                        calendar: calendar,
                        isCurrentMonth: isCurrentMonth
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 16)
        .background(Color.blue.opacity(0.07))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .onAppear {
            currentMonth = calendar.startOfDay(for: currentMonth)
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .padding(12)
                    .contentShape(Rectangle())
            }

            Text(currentMonthTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .padding(12)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? []
        let shift = (calendar.firstWeekday - 1 + 7) % 7
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    private var daysInMonth: [Date] {
        guard calendar.dateInterval(of: .month, for: currentMonth) != nil else { return [] }
        var dates: [Date] = []
        
        // Генерация дат с явным указанием времени 00:00:00
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }
        
        let weekdayOffset = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7
        
        // Даты предыдущего месяца
        if weekdayOffset > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
            let prevMonthDays = calendar.range(of: .day, in: .month, for: prevMonth)!.count
            for day in (prevMonthDays - weekdayOffset + 1)...prevMonthDays {
                let date = calendar.date(bySetting: .day, value: day, of: prevMonth)!
                dates.append(calendar.startOfDay(for: date))
            }
        }
        
        // Даты текущего месяца
        for day in 1...calendar.range(of: .day, in: .month, for: firstOfMonth)!.count {
            let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth)!
            dates.append(calendar.startOfDay(for: date))
        }
        
        // Даты следующего месяца (до 42 ячеек)
        let remaining = 42 - dates.count
        if remaining > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
            for day in 1...remaining {
                let date = calendar.date(bySetting: .day, value: day, of: nextMonth)!
                dates.append(calendar.startOfDay(for: date))
            }
        }
        
        return dates
    }

    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
    }

    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
    }
}
let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "ru_RU")
    calendar.firstWeekday = 2 // Понедельник
    calendar.timeZone = TimeZone(identifier: "Asia/Bangkok")! // ⚠️ Важно!
    return calendar
}()
