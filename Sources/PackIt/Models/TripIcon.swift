import SwiftUI

enum TripIcon: String, Codable, CaseIterable, Identifiable, Sendable {
    case suitcase
    case beach
    case mountain
    case city
    case camping
    case tropical
    case snow
    case road
    case cruise
    case fishing
    case hiking
    case resort
    case international
    case family
    case adventure
    case food

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .suitcase: "suitcase.fill"
        case .beach: "beach.umbrella"
        case .mountain: "mountain.2.fill"
        case .city: "building.2.fill"
        case .camping: "tent.fill"
        case .tropical: "leaf.fill"
        case .snow: "snowflake"
        case .road: "car.fill"
        case .cruise: "ferry.fill"
        case .fishing: "fish.fill"
        case .hiking: "figure.hiking"
        case .resort: "wineglass.fill"
        case .international: "globe.americas.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .adventure: "binoculars.fill"
        case .food: "fork.knife"
        }
    }

    var label: String {
        switch self {
        case .suitcase: "General"
        case .beach: "Beach"
        case .mountain: "Mountain"
        case .city: "City"
        case .camping: "Camping"
        case .tropical: "Tropical"
        case .snow: "Winter"
        case .road: "Road Trip"
        case .cruise: "Cruise"
        case .fishing: "Fishing"
        case .hiking: "Hiking"
        case .resort: "Resort"
        case .international: "International"
        case .family: "Family"
        case .adventure: "Adventure"
        case .food: "Food & Wine"
        }
    }

    var color: Color {
        switch self {
        case .suitcase: .packitTeal
        case .beach: .orange
        case .mountain: .brown
        case .city: .indigo
        case .camping: .green
        case .tropical: .mint
        case .snow: .cyan
        case .road: .red
        case .cruise: .blue
        case .fishing: .teal
        case .hiking: .green
        case .resort: .pink
        case .international: .purple
        case .family: .orange
        case .adventure: .yellow
        case .food: .red
        }
    }
}

struct TripIconView: View {
    let icon: TripIcon
    var size: CGFloat = 28
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(icon.color.opacity(0.15))
                    .frame(width: size, height: size)
            }
            Image(systemName: icon.symbol)
                .font(.system(size: size * 0.45))
                .foregroundStyle(icon.color)
        }
        .frame(width: size, height: size)
    }
}
