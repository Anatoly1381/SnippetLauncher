

import SwiftUI

struct ApartmentDetailView: View {
    @ObservedObject var apartment: Apartment
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var bookingType: BookingType = .reserved
    @State private var showOverlapAlert = false
    @State private var isDescriptionExpanded = false
    @State private var showDeleteAllConfirmation = false
    @State private var showYearCalendar = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Информация о квартире
                Text(apartment.title)
                    .font(.title2.bold())
                
                Text(apartment.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Описание с кнопкой "Показать больше"
                Group {
                    Text(isDescriptionExpanded ? apartment.description : String(apartment.description.prefix(100)) + "...")
                        .animation(.easeInOut, value: isDescriptionExpanded)
                    
                    if apartment.description.count > 100 {
                        Button(isDescriptionExpanded ? "Свернуть" : "Показать больше") {
                            isDescriptionExpanded.toggle()
                        }
                        .font(.caption)
                    }
                    Button(action: { showYearCalendar.toggle() }) {
                        Label("Календарь на год", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Основные параметры
                HStack {
                    VStack(alignment: .leading) {
                        Text("Площадь: \(apartment.area) м²")
                        Text("Этаж: \(apartment.floor)")
                    }
                    Spacer()
                    Text("Статус: \(apartment.status.rawValue)")
                        .foregroundColor(apartment.status == .available ? .green : .red)
                }
                
                Divider()
                
                // Блок бронирования
                bookingSection
                
                // Список бронирований
                existingBookingsSection
            }
            .padding()
        }
                .sheet(isPresented: $showYearCalendar) {
                    NavigationView {
                        YearCalendarView(
                            bookedRanges: apartment.bookingRanges,
                            calendar: calendar
                        )
                    }
                
        }
        .alert("Конфликт дат", isPresented: $showOverlapAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Выбранные даты пересекаются с существующим бронированием. Пожалуйста, выберите другие даты.")
        }
        .alert("Удалить все бронирования?", isPresented: $showDeleteAllConfirmation) {
            Button("Удалить", role: .destructive) {
                apartment.removeAllBookings()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все бронирования для этой квартиры будут удалены. Это действие нельзя отменить.")
        }
    }
    
    private var bookingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите даты бронирования")
                .font(.headline)
            
            DateRangePickerView(
                startDate: $selectedStartDate,
                endDate: $selectedEndDate,
                bookedRanges: apartment.bookingRanges
            )
            .frame(height: 400)
            
            Picker("Тип бронирования", selection: $bookingType) {
                ForEach(BookingType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            Button(action: confirmBooking) {
                Text("Подтвердить бронирование")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedStartDate == nil || selectedEndDate == nil)
        }
    }
    
    private var existingBookingsSection: some View {
        Group {
            if !apartment.bookingRanges.isEmpty {
                Divider()
                
                HStack {
                    Text("Текущие бронирования")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showDeleteAllConfirmation = true
                    }) {
                        Text("Удалить все")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                ForEach(apartment.bookingRanges) { range in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(range.startDate.formatted(date: .long, time: .omitted)) - \(range.endDate.formatted(date: .long, time: .omitted))")
                            Text("Тип: \(range.type.rawValue)")
                                .foregroundColor(range.type == .reserved ? .red : .orange)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            apartment.removeBooking(range)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func confirmBooking() {
        guard let start = selectedStartDate, let end = selectedEndDate else { return }
        
        let newRange = BookingRange(
            startDate: calendar.startOfDay(for: start),
            endDate: calendar.startOfDay(for: end),
            type: bookingType
        )
        
        let hasConflict = apartment.bookingRanges.contains { existing in
            newRange.startDate <= existing.endDate && newRange.endDate >= existing.startDate
        }
        
        if hasConflict {
            showOverlapAlert = true
        } else {
            apartment.addBooking(from: start, to: end, type: bookingType)
            selectedStartDate = nil
            selectedEndDate = nil
        }
    }
}

struct DateRangePickerView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedRanges: [BookingRange]
    
    @State private var currentMonth: Date = Date()
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ru_RU")
        return cal
    }()
    
    var body: some View {
        VStack {
            monthNavigation
                .padding(.bottom, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(daysInMonth, id: \.self) { date in
                    DayView(
                        date: date,
                        startDate: $startDate,
                        endDate: $endDate,
                        bookedRanges: bookedRanges,
                        currentMonth: currentMonth
                    )
                }
            }
        }
        .environment(\.calendar, calendar)
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .animation(.smooth, value: currentMonth)
    }
    
    private var monthNavigation: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .contentShape(Rectangle())
            }
            
            Text(currentMonth.formatted(.dateTime.year().month(.wide)))
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.shortWeekdaySymbols
    }
    
    private var daysInMonth: [Date] {
        guard let range = calendar.dateInterval(of: .month, for: currentMonth) else {
            print("Error: Could not get date interval for month")
            return []
        }
        
        var dates: [Date] = []
        var current = range.start
        
        let weekday = calendar.component(.weekday, from: current)
        let daysToAdd = (weekday + 5) % 7
        
        if daysToAdd > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: current)!
            let prevMonthDays = calendar.range(of: .day, in: .month, for: prevMonth)!.count
            let startDay = prevMonthDays - daysToAdd + 1
            
            for day in startDay...prevMonthDays {
                if let date = calendar.date(bySetting: .day, value: day, of: prevMonth) {
                    dates.append(date)
                }
            }
        }
        
        while current < range.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return dates
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
    }
    private func isDateBooked(_ date: Date) -> Bool {
            bookedRanges.contains { range in
                calendar.isDate(date, inSameDayAs: range.startDate) ||
                calendar.isDate(date, inSameDayAs: range.endDate) ||
                (range.startDate...range.endDate).contains(date)
            }
        }
}

struct DayView: View {
    let date: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedRanges: [BookingRange]
    let currentMonth: Date
    
    @Environment(\.calendar) private var calendar
    
    var body: some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isBooked = bookedRanges.contains { range in
            calendar.isDate(date, inSameDayAs: range.startDate) ||
            (range.startDate...range.endDate).contains(date)
        }
        let isSelected = isDateSelected(date)
        let isStart = calendar.isDate(date, inSameDayAs: startDate ?? Date.distantPast)
        let isEnd = calendar.isDate(date, inSameDayAs: endDate ?? Date.distantPast)
        
        Text("\(calendar.component(.day, from: date))")
            .frame(width: 32, height: 32)
            .background(background(for: isSelected, isStart: isStart, isEnd: isEnd))
            .foregroundColor(foregroundColor(for: isCurrentMonth, isBooked: isBooked))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(isStart || isEnd ? Color.blue : Color.clear, lineWidth: 2)
                    .animation(.easeInOut, value: isStart || isEnd)
            )
            .onTapGesture {
                selectDate(date)
            }
            .disabled(isBooked)
    }

    private func background(for isSelected: Bool, isStart: Bool, isEnd: Bool) -> some View {
        ZStack {
            if isStart || isEnd {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .shadow(color: .blue.opacity(0.2), radius: 3, x: 0, y: 2)
            } else if isSelected {
                Circle()
                    .fill(Color.blue.opacity(0.1))
            }
        }
    }
    
    private func selectDate(_ date: Date) {
        if startDate == nil {
            startDate = date
            endDate = nil
        } else if let start = startDate, endDate == nil {
            if date > start {
                endDate = date
            } else {
                startDate = date
                endDate = nil
            }
        } else {
            startDate = date
            endDate = nil
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let start = startDate else { return false }
        if let end = endDate {
            return date >= start && date <= end
        }
        return calendar.isDate(date, inSameDayAs: start)
    }
    
    private func foregroundColor(for isCurrentMonth: Bool, isBooked: Bool) -> Color {
        if isBooked {
            return .red
        }
        return isCurrentMonth ? .primary : .secondary
    }
}
