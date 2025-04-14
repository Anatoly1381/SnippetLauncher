import SwiftUI
import AppKit


struct ApartmentDetailView: View {
    @ObservedObject var apartment: Apartment
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var bookingType: BookingType = .confirmed
    @State private var showOverlapAlert = false
    @State private var isDescriptionExpanded = false
    @State private var showDeleteAllConfirmation = false
    @State private var showYearCalendar = false
    @State private var showImagePicker = false
    @State private var photoToDelete: Int?
    @EnvironmentObject var apartmentVM: ApartmentViewModel
    
    // Для полноэкранного просмотра
    @State private var isFullImageViewPresented = false
    @State private var selectedPhotoIndex: Int = 0
    
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photosSection
                apartmentInfoSection
                descriptionSection
                Divider()
                apartmentSpecsSection
                Divider()
                bookingSection
                existingBookingsSection
            }
            .padding()
        }
        .sheet(isPresented: $showYearCalendar) {
            YearCalendarSheet(
                bookedRanges: apartment.bookingRanges,
                    calendar: calendar
                )
            }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleImageSelection(result: result)
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
        .sheet(isPresented: $isFullImageViewPresented) {
            FullScreenImageView(
                images: apartment.photos,
                currentIndex: $selectedPhotoIndex,
                isPresented: $isFullImageViewPresented
            )
        }
    }
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }

    private func color(for type: BookingType) -> Color {
        switch type {
        case .confirmed:
            return .red
        case .tentative:
            return .orange
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
                .onTapGesture {
                    selectedPhotoIndex = index
                    isFullImageViewPresented = true
                }

            Button(action: {
                apartment.deletePhoto(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
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
            apartment.addPhotos(images)
        } catch {
            print("Ошибка загрузки: \(error.localizedDescription)")
        }
    }

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
                ForEach(BookingType.allCases, id: \.self) { type in
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
        let ranges = apartment.bookingRanges
        return Group {
            if !ranges.isEmpty {
                VStack(spacing: 8) {
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
                    .padding(.horizontal)
                    
                    ForEach(ranges, id: \.id) { range in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(formattedDate(range.startDate)) – \(formattedDate(range.endDate))")
                                    .font(.subheadline)

                                Text("Тип: \(range.type.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(color(for: range.type))
                            }

                            Spacer()

                            Button(action: {
                                apartment.removeBooking(range)
                                
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
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
            
            apartment.updateStatus() // ← Добавь эту строку
            selectedStartDate = nil
            selectedEndDate = nil
        }
    }
}
import SwiftUI


struct FullScreenImageView: View {
    let images: [NSImage]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    
    // Настройки анимации
    enum TransitionDirection {
        case forward
        case backward
    }
    @State private var transitionDirection: TransitionDirection = .forward
    
    // Настройки масштабирования
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Фон
            Color.black.ignoresSafeArea()
            
            // Основное изображение с анимациями
            ZStack {
                ForEach(images.indices, id: \.self) { index in
                    if index == currentIndex {
                        Image(nsImage: images[index])
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(currentScale)
                            .offset(currentOffset)
                            .transition(getTransition())
                            .zIndex(1)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentScale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = currentScale
                                        if currentScale < 1.0 {
                                            resetImageState()
                                        }
                                    }
                            )
                            .simultaneousGesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation {
                                            currentScale = currentScale > 1.0 ? 1.0 : 2.5
                                            lastScale = currentScale
                                        }
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        if currentScale > 1.0 {
                                            currentOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = currentOffset
                                    }
                            )
                    } else {
                        Image(nsImage: images[index])
                            .resizable()
                            .scaledToFit()
                            .hidden()
                            .zIndex(0)
                    }
                }
            }
            
            // Кнопки навигации (вернул предыдущий стиль)
            HStack {
                Button(action: goPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .disabled(currentIndex <= 0)
                .opacity(currentIndex <= 0 ? 0 : 1)
                
                Spacer()
                
                Button(action: goNext) {
                    Image(systemName: "chevron.right")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .disabled(currentIndex >= images.count - 1)
                .opacity(currentIndex >= images.count - 1 ? 0 : 1)
            }
            .padding(.horizontal, 20)
            
            // Верхняя панель управления
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding()
            
            // Нижний индикатор
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(images.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentIndex ? Color.white : Color.gray.opacity(0.5))
                            .frame(width: index == currentIndex ? 20 : 8, height: 8)
                            .onTapGesture {
                                withAnimation {
                                    currentIndex = index
                                }
                            }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if currentScale == 1.0 {
                        if value.translation.width < -50 {
                            goNext()
                        } else if value.translation.width > 50 {
                            goPrevious()
                        }
                    }
                }
        )
    }
    
    private func goPrevious() {
        resetImageState()
        withAnimation(.easeInOut(duration: 0.5)) {
            transitionDirection = .backward
            currentIndex = max(0, currentIndex - 1)
        }
    }
    
    private func goNext() {
        resetImageState()
        withAnimation(.easeInOut(duration: 0.5)) {
            transitionDirection = .forward
            currentIndex = min(images.count - 1, currentIndex + 1)
        }
    }
    
    private func resetImageState() {
        withAnimation {
            currentScale = 1.0
            lastScale = 1.0
            currentOffset = .zero
            lastOffset = .zero
        }
    }
    
    private func getTransition() -> AnyTransition {
        switch transitionDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }
}
