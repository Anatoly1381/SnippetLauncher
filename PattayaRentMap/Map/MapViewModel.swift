import Foundation
import MapKit

class MapViewModel: ObservableObject {
    @Published var objects: [MapObject] = []
    @Published var selectedObject: MapObject?

    private let saveKey = "savedMapObjects"

    init() {
        loadObjects()
    }

    // Добавить объект на карту
    func startCreatingObject(at coordinate: CLLocationCoordinate2D) {
        let newObject = MapObject(
            title: "",
            description: "",
            coordinate: MapObject.Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude),
            photoURLs: []
        )
        objects.append(newObject)
        selectedObject = newObject
        saveObjects()
    }

    // Обновить заголовок
    func updateTitle(for object: MapObject, with newTitle: String) {
        guard let index = objects.firstIndex(where: { $0.id == object.id }) else { return }
        objects[index].title = newTitle
        saveObjects()
    }

    // Обновить описание
    func updateDescription(for object: MapObject, with newDescription: String) {
        guard let index = objects.firstIndex(where: { $0.id == object.id }) else { return }
        objects[index].description = newDescription
        saveObjects()
    }

    // Удаление всех пользовательских объектов
    func resetUserObjects() {
        print("🗑 Удаление всех пользовательских объектов и сброс UserDefaults")
        objects.removeAll()
        selectedObject = nil
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    // Сохранение объектов в память
    private func saveObjects() {
        if let encoded = try? JSONEncoder().encode(objects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            print("✅ Сохранение выполнено — \(objects.count) объектов")
        } else {
            print("❌ Ошибка при кодировании объектов")
        }
    }

    // Загрузка объектов из памяти
    private func loadObjects() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let decoded = try JSONDecoder().decode([MapObject].self, from: data)
                objects = decoded
            } catch {
                print("❌ Не удалось декодировать объекты:", error)
                objects = []
            }
        } else {
            print("ℹ️ Нет сохранённых объектов")
            objects = []
        }
    }
}
