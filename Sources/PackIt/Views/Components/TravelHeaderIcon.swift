import SwiftUI

/// Travel-mode icon used in the trip header departure/return rows. Adds a
/// subtle horizontal bob to imply motion and flips ground/water/cycle modes
/// to the correct heading: departure points right (away from home), arrival
/// points left (homeward). Plane uses its own directional `.departure` /
/// `.arrival` SF Symbols so no flipping is needed.
struct TravelHeaderIcon: View {
    enum Direction { case departure, arrival }

    let mode: TravelMode
    let direction: Direction
    var animated: Bool = true

    @State private var bobbing = false

    var body: some View {
        let symbol = direction == .departure ? mode.departureSymbol : mode.arrivalSymbol
        let needsFlip = mode.flipsForDeparture && direction == .departure

        Image(systemName: symbol)
            .scaleEffect(x: needsFlip ? -1 : 1, y: 1)
            .offset(x: animated ? (bobbing ? 1 : -1) : 0)
            .onAppear {
                guard animated else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    bobbing = true
                }
            }
    }
}

extension TravelMode {
    /// True when the symbol points "homeward" (left) by SF Symbols convention,
    /// meaning the departure variant needs a horizontal flip to face right.
    /// Plane is excluded — its `.departure`/`.arrival` symbols are already
    /// correctly oriented.
    var flipsForDeparture: Bool {
        switch self {
        case .plane: false
        case .car, .train, .bus, .rv, .boat, .bicycle, .walking: true
        }
    }
}
