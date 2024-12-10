import Foundation

struct Vehicle: Identifiable, Codable {
    let id: String // Firestore document ID or UUID
    var name: String
    var licensePlate: String
    var type: String

    init(id: String = UUID().uuidString, name: String, licensePlate: String, type: String) {
        self.id = id
        self.name = name
        self.licensePlate = licensePlate
        self.type = type
    }
}
