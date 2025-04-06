import Foundation
import CoreLocation
import PhotosUI

let mockApartments: [Apartment] = [
    Apartment(
        id: "apt001",
        title: "Уютная студия в Laguna Bay 1",
        description: "28 м², 6 этаж, вид на сад. Полностью меблирована, быстрый интернет, бассейн, спортзал, 5 мин до пляжа.",
        coordinate: CLLocationCoordinate2D(latitude: 12.9111787, longitude: 100.8611543),
        address: "Laguna Bay 1, Pratumnak Soi 5",
        area: 28,
        floor: 6,
        status: .available
    ),
    Apartment(
        id: "apt002",
        title: "Kieng Talay",
        description: "40 м², 3 этаж, вид на бассейн и море. Мебель, кухня, интернет, 400 м до моря.",
        coordinate: CLLocationCoordinate2D(latitude: 12.9091375, longitude: 100.86110781),
        address: "Pratumnak 6",
        area: 40,
        floor: 3,
        status: .available
    ),
    Apartment(
        id: "apt003",
        title: "Jomtien Beach Condo A3",
        description: "Уютная студия площадью 28 м², полностью меблирована и оснащена всем необходимым для комфортного проживания. В квартире есть кондиционер, телевизор, кухня с холодильником, а также доступ к бассейну и тренажёрному залу.Коммунальные услуги оплачиваются отдельно — электричество и вода не включены в стоимость аренды. Также предусмотрен депозит в размере 5 000 бат и финальная уборка за 500 бат. Высокоскоростной интернет по оптоволокну доступен за 600 бат в месяц. Отличное расположение — всего 500 метров до моря и ближайших магазинов.",
        coordinate: CLLocationCoordinate2D(latitude: 12.8913521, longitude: 100.8793023),
        address: "Jomtien Second Road",
        area: 28,
        floor: 9,
        status: .available
    )
]
