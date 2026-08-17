import SwiftUI

/// Utility view that renders either an SF Symbol or an Emoji based on the string content.
struct FoodIcon: View {
    let symbol: String
    var size: CGFloat = 12
    var color: Color = .packitTeal

    var body: some View {
        if isSystemSymbol(symbol) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(color)
        } else {
            Text(symbol)
                .font(.system(size: size * 1.2)) // Emojis usually need a slight bump to match SF Symbol visual weight
        }
    }

    private func isSystemSymbol(_ name: String) -> Bool {
        // Simple heuristic: SF Symbols use lowercase, dots, and numbers. Emojis are outside ASCII.
        // We also check if NSImage can resolve it to be sure.
        guard let first = name.first else { return false }
        if first.isASCII {
            return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        }
        return false
    }
}
