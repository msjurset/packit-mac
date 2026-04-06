import SwiftUI

enum CategoryIcon {
    static func icon(for category: String) -> String {
        switch category.lowercased() {
        // Travel & Documents
        case "documents": return "doc.text.fill"
        case "electronics": return "bolt.fill"
        case "health": return "cross.case.fill"
        case "accessories": return "sparkles"
        case "food": return "fork.knife"

        // Clothing
        case "basics": return "tshirt.fill"
        case "layers": return "cloud.sun.fill"
        case "activity wear": return "figure.run"
        case "footwear": return "shoe.fill"
        case "formal": return "necktie"
        case "clothing": return "tshirt.fill"

        // Toiletries
        case "dental": return "mouth.fill"
        case "hair": return "comb.fill"
        case "body": return "figure.arms.open"
        case "skin": return "sun.max.fill"
        case "skin care": return "leaf.fill"
        case "vision": return "eye.fill"
        case "cosmetics": return "paintbrush.fill"
        case "grooming": return "scissors"
        case "misc": return "ellipsis.circle.fill"

        // Beach & Water
        case "beach gear": return "beach.umbrella.fill"
        case "water sports": return "figure.water.fitness"
        case "entertainment": return "book.fill"
        case "bags": return "bag.fill"

        // Fishing
        case "fishing gear": return "fish.fill"
        case "tools": return "wrench.and.screwdriver.fill"
        case "storage": return "archivebox.fill"
        case "comfort": return "chair.lounge.fill"

        // Camping
        case "shelter": return "tent.fill"
        case "lighting": return "flashlight.on.fill"
        case "cooking": return "frying.pan.fill"
        case "fire": return "flame.fill"
        case "safety": return "shield.checkered"
        case "navigation": return "map.fill"
        case "cleanup": return "leaf.arrow.triangle.circlepath"
        case "water": return "drop.fill"

        default: return "square.grid.2x2.fill"
        }
    }

    static func color(for category: String) -> Color {
        adaptiveColor(for: category.lowercased())
    }

    private static func adaptiveColor(for key: String) -> Color {
        switch key {
        // Light values that need darkening for light mode / brightening for dark mode
        case "electronics":  return adaptive(light: (0.80, 0.65, 0.0), dark: (1.0, 0.85, 0.15))
        case "skin":         return adaptive(light: (0.80, 0.58, 0.0), dark: (1.0, 0.78, 0.15))
        case "lighting":     return adaptive(light: (0.80, 0.70, 0.0), dark: (1.0, 0.92, 0.35))
        case "dental":       return adaptive(light: (0.0, 0.70, 0.65), dark: (0.15, 0.95, 0.85))
        case "body":         return adaptive(light: (0.0, 0.72, 0.48), dark: (0.15, 1.0, 0.68))
        case "skin care":    return adaptive(light: (0.18, 0.72, 0.38), dark: (0.35, 1.0, 0.55))
        case "grooming":     return adaptive(light: (0.35, 0.65, 0.80), dark: (0.60, 0.90, 1.0))
        case "misc":         return adaptive(light: (0.50, 0.50, 0.60), dark: (0.72, 0.72, 0.82))
        case "comfort":      return adaptive(light: (0.45, 0.65, 0.25), dark: (0.68, 0.88, 0.42))
        case "cleanup":      return adaptive(light: (0.25, 0.70, 0.42), dark: (0.42, 0.95, 0.62))
        case "shelter":      return adaptive(light: (0.18, 0.68, 0.18), dark: (0.35, 0.92, 0.35))
        case "bags":         return adaptive(light: (0.62, 0.45, 0.82), dark: (0.85, 0.68, 1.0))

        // Colors that work well in both modes
        case "documents":    return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "health":       return Color(red: 1.0, green: 0.25, blue: 0.35)
        case "accessories":  return Color(red: 0.75, green: 0.35, blue: 1.0)
        case "food":         return Color(red: 1.0, green: 0.55, blue: 0.0)
        case "basics", "clothing": return Color(red: 0.45, green: 0.4, blue: 1.0)
        case "layers":       return Color(red: 0.55, green: 0.5, blue: 1.0)
        case "activity wear": return Color(red: 0.0, green: 0.9, blue: 0.7)
        case "footwear":     return Color(red: 0.6, green: 0.45, blue: 1.0)
        case "formal":       return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "hair":         return Color(red: 0.0, green: 0.85, blue: 0.75)
        case "vision":       return Color(red: 0.0, green: 0.8, blue: 1.0)
        case "cosmetics":    return Color(red: 1.0, green: 0.4, blue: 0.7)
        case "beach gear":   return Color(red: 0.0, green: 0.85, blue: 1.0)
        case "water sports":  return Color(red: 0.0, green: 0.7, blue: 1.0)
        case "entertainment": return Color(red: 1.0, green: 0.5, blue: 0.85)
        case "fishing gear":  return Color(red: 0.0, green: 0.75, blue: 0.55)
        case "tools":        return Color(red: 1.0, green: 0.65, blue: 0.2)
        case "storage":      return Color(red: 0.85, green: 0.55, blue: 0.25)
        case "cooking":      return Color(red: 1.0, green: 0.45, blue: 0.2)
        case "fire":         return Color(red: 1.0, green: 0.35, blue: 0.1)
        case "safety":       return Color(red: 1.0, green: 0.3, blue: 0.3)
        case "navigation":   return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "water":        return Color(red: 0.2, green: 0.7, blue: 1.0)
        default:             return adaptive(light: (0.45, 0.45, 0.55), dark: (0.65, 0.65, 0.75))
        }
    }

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: dark.0, green: dark.1, blue: dark.2, alpha: 1)
                : NSColor(red: light.0, green: light.1, blue: light.2, alpha: 1)
        })
    }
}
