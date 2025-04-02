//
//  FSCalendarView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 30/3/2568 BE.
//

#if canImport(UIKit)
import FSCalendar

struct FSCalendarView: View {
    @Binding var selectedDate: Date

    var body: some View {
        FSCalendarWrapper(selectedDate: $selectedDate)
            .frame(height: 400) // Устанавливаем размеры
    }
}

struct FSCalendarWrapper: UIViewRepresentable {
    @Binding var selectedDate: Date

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.select(selectedDate, scrollToDate: true)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var parent: FSCalendarWrapper

        init(parent: FSCalendarWrapper) {
            self.parent = parent
        }

        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            parent.selectedDate = date
        }
    }
}
#else
// Альтернативная реализация для macOS
#endif
