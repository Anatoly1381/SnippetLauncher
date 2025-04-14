import SwiftUI

// Основная вьюшка для отображения и редактирования данных нового объекта на карте
struct MapObjectDetailView: View {
    @Binding var object: MapObject
    @ObservedObject var viewModel: MapViewModel

    @State private var showYearCalendar = false
    @State private var selectedRange: ClosedRange<Date>?
    @State private var selectedBookingType: BookingType = .confirmed

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // 🔹 Заголовок (название объекта)
                TextField("Название объекта", text: Binding(
                    get: { object.title },
                    set: { newValue in
                        viewModel.updateTitle(for: object, with: newValue)
                    }
                ))
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .textFieldStyle(.roundedBorder)

                // 🔹 Описание (редактируемое поле)
                TextEditor(text: Binding(
                    get: { object.description },
                    set: { newValue in
                        viewModel.updateDescription(for: object, with: newValue)
                    })
                )
                .frame(minHeight: 120)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )
                .padding(.horizontal)

                Divider()

                // 🔹 Кнопка вызова годового календаря
                Button {
                    showYearCalendar = true
                } label: {
                    Label("Календарь на год", systemImage: "calendar")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                // 🔹 Основной календарь на месяц
                SingleMonthCalendarView(
                    selectedRange: $selectedRange,
                    bookingType: $selectedBookingType
                )
                .frame(height: 300)
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
        // 🔹 Годовой календарь открывается в отдельном окне
        .sheet(isPresented: $showYearCalendar) {
            YearCalendarView(
                bookedRanges: [], // TODO: позже подставить object.bookings
                calendar: Calendar.current
            )
        }
    }
}
