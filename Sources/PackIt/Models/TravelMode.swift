import Foundation

/// How the user is traveling for a given trip. Drives travel-related icons
/// (prep timeline "Day Of"/"On Return" nodes, trip header date rows, etc.).
/// Persisted on `TripInstance`; defaults to `.plane` for older trips.
enum TravelMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case plane
    case car
    case train
    case bus
    case rv
    case boat
    case bicycle
    case walking

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plane: "Plane"
        case .car: "Car"
        case .train: "Train"
        case .bus: "Bus"
        case .rv: "RV"
        case .boat: "Boat"
        case .bicycle: "Bicycle"
        case .walking: "Walking"
        }
    }

    /// Generic SF Symbol shown in pickers / labels. Side-profile variants
    /// chosen where they exist so the icon reads as moving forward.
    var symbol: String {
        switch self {
        case .plane: "airplane"
        case .car: "car.side.fill"
        case .train: "tram.fill"
        case .bus: "bus.fill"
        case .rv: "bus.doubledecker.fill"
        case .boat: "ferry.fill"
        case .bicycle: "bicycle"
        case .walking: "figure.walk"
        }
    }

    /// True when the symbol shows the vehicle in side profile, so trailing
    /// speed lines visually make sense beside it.
    var isSideProfile: Bool {
        switch self {
        case .car, .train, .boat, .bicycle: true
        case .plane, .bus, .rv, .walking: false
        }
    }

    /// SF Symbol for the "Day Of" / departure step. Plane has a dedicated
    /// directional variant; everything else reuses the generic symbol.
    var departureSymbol: String {
        switch self {
        case .plane: "airplane.departure"
        default: symbol
        }
    }

    /// SF Symbol for the "On Return" / arrival step.
    var arrivalSymbol: String {
        switch self {
        case .plane: "airplane.arrival"
        default: symbol
        }
    }
}
