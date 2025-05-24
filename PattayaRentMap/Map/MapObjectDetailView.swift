import SwiftUI
import MapKit
import AppKit
import UniformTypeIdentifiers
import PhotosUI

let photoManager = PhotoFileManager()

struct MapObjectDetailView: View {
    @Binding var object: MapObject
    @ObservedObject var viewModel: MapViewModel
    
    @State private var images: [NSImage] = []
    @State private var showImagePicker = false
    @State private var showYearCalendar = false
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var bookingType: BookingType = .confirmed
    @State private var showOverlapAlert = false
    @State private var isDescriptionExpanded = false
    @State private var resolvedAddress: String = ""
    @State private var isFullImageViewPresented = false
    @State private var selectedPhotoIndex: Int = 0
    @State private var draggedItem: Int?
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }()
    
    var body: some View {
        ScrollView {
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                // Левая колонка
                VStack(alignment: .leading) {
                    titleAndAddressSection
                    mapSection
                        .alignmentGuide(.firstTextBaseline) { d in d[.top] }
                    photosSection
                    descriptionSection
                }

                // Правая колонка
                VStack(alignment: .leading) {
                    calendarButtonSection
                    bookingSection
                    existingBookingsSection
                }
                .frame(minWidth: 520, maxWidth: .infinity)
                .alignmentGuide(.top) { d in d[.top] }
            }
            .padding(.top, 30)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            resolveAddress(from: object.coordinate.clLocation)
            images = object.photoPaths.compactMap { photoManager.loadPhoto(from: $0) }
        }
        .onDisappear {
            viewModel.saveObjects()
        }
        .sheet(isPresented: $showYearCalendar) {
            YearCalendarSheet(bookedRanges: object.bookingRanges, calendar: calendar)
        }
        .sheet(isPresented: $isFullImageViewPresented) {
            FullScreenImageView(
                images: images,
                currentIndex: $selectedPhotoIndex,
                isPresented: $isFullImageViewPresented
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        }
        .fileImporter(isPresented: $showImagePicker, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
            handleImageImport(result)
        }
        .alert("Конфликт бронирования", isPresented: $showOverlapAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Выбранные даты пересекаются с существующим бронированием")
        }
    }

    // MARK: - Photos Section with Drag & Drop
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if images.isEmpty {
                DropZoneView(
                    object: $object,
                    images: $images,
                    viewModel: viewModel,
                    action: { showImagePicker = true }
                )
                .frame(height: 160)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            photoView(for: index, image: image)
                                .frame(width: 164, height: 164)
                        }

                        DropZoneView(
                            object: $object,
                            images: $images,
                            viewModel: viewModel,
                            action: { showImagePicker = true }
                        )
                        .frame(width: 160, height: 160)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 180)
            }

            // Кнопка "Выбрать из галереи" — внизу, едина для обоих случаев
            PhotosPicker(selection: $photoPickerItems,
                         matching: .images,
                         photoLibrary: .shared()) {
                Label("Выбрать из галереи", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .onChange(of: photoPickerItems) { oldValue, newValue in
                handlePhotoPickerSelection(newValue)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Photo Picker Handler
    private func handlePhotoPickerSelection(_ items: [PhotosPickerItem]) {
        Task {
            var newPhotoPaths: [String] = []
            var newImages: [NSImage] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = NSImage(data: data),
                   let savedPath = photoManager.savePhoto(from: image) {
                    newPhotoPaths.append(savedPath)
                    newImages.append(image)
                }
            }
            
            DispatchQueue.main.async {
                object.photoPaths.append(contentsOf: newPhotoPaths)
                images.append(contentsOf: newImages)
                viewModel.saveObjects()
                photoPickerItems.removeAll()
            }
        }
    }

    // MARK: - Drop Zone View
    struct DropZoneView: View {
        @Binding var object: MapObject
        @Binding var images: [NSImage]
        var viewModel: MapViewModel
        var action: () -> Void
        @State private var isDragOver = false

        var body: some View {
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isDragOver ? .accentColor : .secondary)
                Text("Перетащите фото сюда")
                    .font(.caption)
                    .foregroundColor(isDragOver ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isDragOver ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
            .onDrop(of: [.fileURL, .image], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
            .onTapGesture(perform: action)
            .animation(.easeInOut, value: isDragOver)
        }

        private func handleDrop(providers: [NSItemProvider]) -> Bool {
            let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif", "webp", "bmp", "tiff", "tif", "gif", "dng"]
            
            for provider in providers {
                // Обработка файлов из Finder
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil),
                              supportedExtensions.contains(url.pathExtension.lowercased())
                        else { return }

                        DispatchQueue.main.async {
                            if let savedPath = photoManager.savePhoto(from: url),
                               let image = photoManager.loadPhoto(from: savedPath) {
                                object.photoPaths.append(savedPath)
                                images.append(image)
                                viewModel.saveObjects()
                            }
                        }
                    }
                }
                
                // Обработка изображений из галереи
                if provider.hasItemConformingToTypeIdentifier("public.image") {
                    provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, error in
                        guard let url = item as? URL,
                              let image = NSImage(contentsOf: url),
                              let savedPath = photoManager.savePhoto(from: image)
                        else { return }

                        DispatchQueue.main.async {
                            object.photoPaths.append(savedPath)
                            images.append(image)
                            viewModel.saveObjects()
                        }
                    }
                }
            }
            
            return true
        }
    }
    private func photoView(for index: Int, image: NSImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160)
                .clipped()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    openImageWindow(images: images, startIndex: index)
                }

            Button(action: {
                deletePhoto(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .offset(x: 3, y: -3)
        }
    }
    // MARK: - Photo Drop Delegate
    struct PhotoDropDelegate: DropDelegate {
        let currentIndex: Int
        @Binding var draggedItem: Int?
        @Binding var images: [NSImage]
        @Binding var object: MapObject
        let viewModel: MapViewModel
        
        func dropEntered(info: DropInfo) {
            guard let draggedItem = draggedItem else { return }
            if draggedItem != currentIndex {
                viewModel.swapPhotos(for: object.id, from: draggedItem, to: currentIndex)
                object.photoPaths.swapAt(draggedItem, currentIndex)
                images.swapAt(draggedItem, currentIndex)
                self.draggedItem = currentIndex
            }
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }
        
        func performDrop(info: DropInfo) -> Bool {
            draggedItem = nil
            return true
        }
    }

    // MARK: - Title and Address Section
    private var titleAndAddressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Название объекта", text: Binding(
                    get: { object.title },
                    set: { newValue in
                        if let index = viewModel.objects.firstIndex(where: { $0.id == object.id }) {
                            viewModel.objects[index].title = newValue
                            viewModel.saveObjects()
                        }
                    }))
                    .font(.title2.bold())
                    .textFieldStyle(.plain)

                Text(object.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(object.status == .available ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((object.status == .available ? Color.green.opacity(0.1) : Color.red.opacity(0.1)))
                    .cornerRadius(6)
            }
            .padding(.vertical, 4)

            Text(resolvedAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Расположение")
                .font(.headline)
            
            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: object.clCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )) {
                Annotation(object.title, coordinate: object.clCoordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
            }
            .allowsHitTesting(false)
            .frame(height: 150)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.vertical, 8)
            
            Button(action: openInMaps) {
                Label("Открыть в Картах", systemImage: "arrow.triangle.turn.up.right.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isDescriptionExpanded || object.description.count <= 100 {
                TextEditor(text: Binding(
                    get: { object.description },
                    set: { newValue in
                        if let index = viewModel.objects.firstIndex(where: { $0.id == object.id }) {
                            viewModel.objects[index].description = newValue
                            viewModel.saveObjects()
                        }
                    }))
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(8)
                .lineSpacing(6)
            } else {
                Text(object.description.prefix(100) + "…")
                    .font(.body)
            }

            if object.description.count > 100 {
                Button(isDescriptionExpanded ? "Свернуть" : "Показать больше") {
                    isDescriptionExpanded.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Calendar Button Section
    private var calendarButtonSection: some View {
        Button(action: { showYearCalendar.toggle() }) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                Text("Календарь на год")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.top, 0)
    }
    
    // MARK: - Booking Section
    private var bookingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите даты бронирования")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            DateRangePickerView(
                startDate: $selectedStartDate,
                endDate: $selectedEndDate,
                bookedRanges: object.bookingRanges,
                calendar: calendar
            )
            .frame(height: 400)

            HStack(alignment: .center, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { bookingType == .tentative },
                    set: { bookingType = $0 ? .tentative : .confirmed }
                )) {
                    Text("Предварительно")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .frame(width: 180)
                
                Button {
                    confirmBooking()
                } label: {
                    Label("Подтвердить бронирование", systemImage: "checkmark.circle.fill")
                        .font(.system(.body, design: .rounded))
                        .frame(minWidth: 180, maxWidth: 480)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
                .disabled(selectedStartDate == nil || selectedEndDate == nil)
            }
        }
    }

    // MARK: - Existing Bookings Section
    private var existingBookingsSection: some View {
        let ranges = object.bookingRanges
        return Group {
            if !ranges.isEmpty {
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        Text("Текущие бронирования")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Spacer()

                        Button {
                            object.bookingRanges.removeAll()
                            updateStatus()
                            viewModel.saveObjects()
                        } label: {
                            Label("Удалить все", systemImage: "trash")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        .foregroundColor(.red)
                        .buttonStyle(.plain)
                    }

                    ForEach(ranges, id: \.id) { range in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(formattedDate(range.startDate)) – \(formattedDate(range.endDate))")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                                
                                Text("Тип: \(range.type.rawValue)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(color(for: range.type))
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 0) {
                                Button {
                                    if let index = object.bookingRanges.firstIndex(of: range) {
                                        object.bookingRanges.remove(at: index)
                                        updateStatus()
                                        viewModel.saveObjects()
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .offset(y: 8)
                            }
                            .frame(height: 40)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func openInMaps() {
        let coordinate = object.clCoordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = object.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
    
    private func confirmBooking() {
        guard let start = selectedStartDate, let end = selectedEndDate else { return }

        let newRange = BookingRange(
            startDate: calendar.startOfDay(for: start),
            endDate: calendar.startOfDay(for: end),
            type: bookingType
        )

        let hasConflict = object.bookingRanges.contains { existing in
            newRange.startDate <= existing.endDate && newRange.endDate >= existing.startDate
        }

        if hasConflict {
            showOverlapAlert = true
        } else {
            object.bookingRanges.append(newRange)
            updateStatus()
            viewModel.saveObjects()
            selectedStartDate = nil
            selectedEndDate = nil
        }
    }

    private func updateStatus() {
        object.status = object.bookingRanges.isEmpty ? .available : .rented
    }

    private func handleImageImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()

            var newPhotoPaths: [String] = []
            var newImages: [NSImage] = []

            for url in urls {
                guard ["jpg", "jpeg", "png", "dng"].contains(url.pathExtension.lowercased()) else { continue }
                if let savedPath = photoManager.savePhoto(from: url),
                   let image = photoManager.loadPhoto(from: savedPath) {
                    newPhotoPaths.append(savedPath)
                    newImages.append(image)
                }
            }

            object.photoPaths.append(contentsOf: newPhotoPaths)
            images.append(contentsOf: newImages)
            viewModel.saveObjects()
        } catch {
            print("Ошибка импорта изображений: \(error.localizedDescription)")
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
        case .confirmed: return .red
        case .tentative: return .orange
        }
    }
    
    private func resolveAddress(from location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                resolvedAddress = [placemark.name, placemark.locality, placemark.country].compactMap { $0 }.joined(separator: ", ")
            }
        }
    }
    
    private func deletePhoto(at index: Int) {
        let pathToRemove = object.photoPaths[index]
        photoManager.deletePhoto(at: pathToRemove)
        object.photoPaths.remove(at: index)
        images = object.photoPaths.compactMap { photoManager.loadPhoto(from: $0) }
        viewModel.saveObjects()
    }
}

// MARK: - Extension для ViewModel
extension MapViewModel {
    func swapPhotos(for objectId: UUID, from: Int, to: Int) {
        guard let index = objects.firstIndex(where: { $0.id == objectId }),
              objects[index].photoPaths.indices.contains(from),
              objects[index].photoPaths.indices.contains(to) else { return }
        
        objects[index].photoPaths.swapAt(from, to)
        saveObjects()
    }
}
