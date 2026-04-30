import Foundation

public struct TripDestination: Codable, Hashable, Sendable {
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var country: String?
    public var admin1: String?  // state/province

    public var displayName: String {
        var parts = [name]
        if let admin1, !admin1.isEmpty { parts.append(admin1) }
        if let country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }

    public init(name: String, latitude: Double, longitude: Double, country: String? = nil, admin1: String? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.admin1 = admin1
    }
}
