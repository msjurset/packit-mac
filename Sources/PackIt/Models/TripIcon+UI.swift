import SwiftUI
import PackItKit

extension TripIcon {
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
        case .backpack: .teal
        case .map: .blue
        case .business: .gray
        case .photo: .purple
        case .festival: .pink
        case .concert: .purple
        case .couple: .pink
        case .solo: .teal
        case .pets: .brown
        case .ocean: .blue
        case .lake: .cyan
        case .sailing: .blue
        case .surfing: .teal
        case .pool: .cyan
        case .forest: .green
        case .desert: .orange
        case .skiing: .blue
        case .snowboard: .indigo
        case .iceSkating: .cyan
        case .climbing: .red
        case .biking: .teal
        case .running: .orange
        case .golf: .green
        case .landmark: .purple
        case .hotel: .teal
        case .coffee: .brown
        case .airplane: .blue
        case .train: .teal
        case .rv: .green
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
