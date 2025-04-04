import SwiftUI
import AppKit

struct ApartmentDetailView: View {
    @ObservedObject var apartment: Apartment
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var bookingType: BookingType = .reserved
    @State private var showOverlapAlert = false
    @State private var isDescriptionExpanded = false
    @State private var showDeleteAllConfirmation = false
    @State private var showYearCalendar = false
    @State private var showImagePicker = false
    @State private var photoToDelete: Int?
    @State private var isFullImageViewPresented = false
    @State private var selectedPhoto: NSImage?

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photosSection        // Секция для фотографий
                apartmentInfoSection // Секция с информацией о квартире
                descriptionSection   // Секция с описанием
                Divider()
                apartmentSpecsSection // Секция с характеристиками квартиры
                Divider()
                bookingSection        // Блок бронирования
                existingBookingsSection // Список бронирований
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
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleImageSelection(result: result) // Обработчик выбора фото
        }
        .alert("Конфликт дат", isPresented: $showOverlapAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Выбранные даты пересекаются с существующим бронированием.")
        }
        .alert("Удалить все бронирования?", isPresented: $showDeleteAllConfirmation) {
            Button("Удалить", role: .destructive) {
                apartment.removeAllBookings()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все бронирования для этой квартиры будут удалены. Это действие нельзя отменить.")
        }
        // Full image view sheet
        .sheet(isPresented: $isFullImageViewPresented) {
            if let selectedPhoto = selectedPhoto {
                VStack {
                    Image(nsImage: selectedPhoto)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Button("Закрыть") {
                        isFullImageViewPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading) {
            Text("Фотографии")
                .font(.headline)

            Button("Добавить фото") {
                showImagePicker.toggle()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 10)

            if apartment.photos.isEmpty {
                Text("Нет фотографий")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(0..<apartment.photos.count, id: \.self) { index in
                            photoView(for: index)
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private func photoView(for index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: apartment.photos[index])
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .cornerRadius(8)

            Button(action: {
                apartment.deletePhoto(at: index) // Удаление фото
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: { showFullImage(photo: apartment.photos[index]) }) {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding([.top, .trailing], 8)
        }
    }

    private func showFullImage(photo: NSImage) {
        selectedPhoto = photo
        isFullImageViewPresented = true
    }

    private func handleImageSelection(result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            let images = urls.compactMap { url -> NSImage? in
                guard ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) else {
                    return nil
                }
                return NSImage(contentsOf: url)
            }
            apartment.addPhotos(images) // Добавляем выбранные фотографии
        } catch {
            print("Ошибка загрузки: \(error.localizedDescription)")
        }
    }

    // Секция с информацией о квартире
    private var apartmentInfoSection: some View {
        VStack(alignment: .leading) {
            Text(apartment.title)
                .font(.title2.bold())
            Text(apartment.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    private var descriptionSection: some View {
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
    }
    // Секция с характеристиками квартиры
    private var apartmentSpecsSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Площадь: \(apartment.area) м²")
                Text("Этаж: \(apartment.floor)")
            }
            Spacer()
            Text("Статус: \(apartment.status.rawValue)")
                .foregroundColor(apartment.status == .available ? .green : .red)
        }
    }

    // Секция для бронирования
    private var bookingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите даты бронирования")
                .font(.headline)

            DateRangePickerView(
                startDate: $selectedStartDate,
                endDate: $selectedEndDate,
                bookedRanges: apartment.bookingRanges,
                calendar: calendar
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

    // Секция с текущими бронированиями
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
