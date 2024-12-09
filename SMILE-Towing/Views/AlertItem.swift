import Foundation

// MARK: - Alert Item
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
