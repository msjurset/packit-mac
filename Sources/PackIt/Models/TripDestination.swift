import Foundation

struct TripDestination: Codable, Hashable, Sendable {
    var name: String
    var latitude: Double
    var longitude: Double
    var country: String?
    var admin1: String?  // state/province

    var displayName: String {
        var parts = [name]
        if let admin1, !admin1.isEmpty { parts.append(admin1) }
        if let country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}
