import SwiftUI

// MARK: - Reusable Color Extension
extension Color {
    static func from(name: String) -> Color? {
        let colorMap: [String: Color] = [
            "red": .red, "blue": .blue, "green": .green,
            "yellow": .yellow, "orange": .orange, "purple": .purple,
            "black": .black, "white": .white, "gray": .gray,
            "cyan": .cyan,
        ]
        return colorMap[name.lowercased()]
    }
}

// MARK: - Skywards Member Info
struct SkywardsMemberInfo: Equatable {
    let membershipNumber: String
    let tierStatus: String
    let miles: Int
    let tierMiles: Int
    var phoneNumber: String
    var note: String
}

// MARK: - Shared message content
struct SharedMessageContent {
    let message: String
    let color: String
    let size: Int
}

// MARK: - Trip Details
struct Trip {
    let departureCity: String
    let destinationCity: String
    let departureTime: String
    let arrivalTime: String
    let duration: String
    let airline: String
    let flightNumber: String
}

// MARK: - Water Customer Info
// New data model for the water utility customer.
struct WaterCustomerInfo: Equatable {
    let customerName: String
    let contractNumber: String
    let tier: String // e.g., "Residential", "Commercial"
    let usageStatus: String // e.g., "Normal", "High", "Leak Suspected"
    var currentReadingM3: Double // Water usage in cubic meters (m³)
    let lastReadingDate: Date
    var phoneNumber: String
    var note: String
}
