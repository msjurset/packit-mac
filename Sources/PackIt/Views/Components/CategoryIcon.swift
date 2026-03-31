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
        switch category.lowercased() {
        case "documents": return Color(red: 0.2, green: 0.6, blue: 1.0)       // neon blue
        case "electronics": return Color(red: 1.0, green: 0.85, blue: 0.0)    // neon yellow
        case "health": return Color(red: 1.0, green: 0.25, blue: 0.35)        // neon red
        case "accessories": return Color(red: 0.75, green: 0.35, blue: 1.0)   // neon purple
        case "food": return Color(red: 1.0, green: 0.55, blue: 0.0)           // neon orange

        case "basics": return Color(red: 0.45, green: 0.4, blue: 1.0)         // neon indigo
        case "clothing": return Color(red: 0.45, green: 0.4, blue: 1.0)
        case "layers": return Color(red: 0.55, green: 0.5, blue: 1.0)         // lighter indigo
        case "activity wear": return Color(red: 0.0, green: 0.9, blue: 0.7)   // neon teal
        case "footwear": return Color(red: 0.6, green: 0.45, blue: 1.0)
        case "formal": return Color(red: 0.7, green: 0.5, blue: 1.0)

        case "dental": return Color(red: 0.0, green: 0.95, blue: 0.85)        // neon mint
        case "hair": return Color(red: 0.0, green: 0.85, blue: 0.75)
        case "body": return Color(red: 0.0, green: 1.0, blue: 0.65)           // neon green-mint
        case "skin": return Color(red: 1.0, green: 0.75, blue: 0.0)           // neon amber
        case "skin care": return Color(red: 0.3, green: 1.0, blue: 0.5)       // neon green
        case "vision": return Color(red: 0.0, green: 0.8, blue: 1.0)          // neon cyan
        case "cosmetics": return Color(red: 1.0, green: 0.4, blue: 0.7)       // neon pink
        case "grooming": return Color(red: 0.6, green: 0.9, blue: 1.0)        // light neon blue
        case "misc": return Color(red: 0.7, green: 0.7, blue: 0.8)            // soft neon gray

        case "beach gear": return Color(red: 0.0, green: 0.85, blue: 1.0)     // neon sky
        case "water sports": return Color(red: 0.0, green: 0.7, blue: 1.0)    // neon ocean
        case "entertainment": return Color(red: 1.0, green: 0.5, blue: 0.85)  // neon magenta
        case "bags": return Color(red: 0.85, green: 0.65, blue: 1.0)          // neon lavender

        case "fishing gear": return Color(red: 0.0, green: 0.75, blue: 0.55)  // neon sea green
        case "tools": return Color(red: 1.0, green: 0.65, blue: 0.2)          // neon tangerine
        case "storage": return Color(red: 0.85, green: 0.55, blue: 0.25)      // neon bronze
        case "comfort": return Color(red: 0.65, green: 0.85, blue: 0.4)       // neon lime

        case "shelter": return Color(red: 0.3, green: 0.9, blue: 0.3)         // neon green
        case "lighting": return Color(red: 1.0, green: 0.95, blue: 0.3)       // neon bright yellow
        case "cooking": return Color(red: 1.0, green: 0.45, blue: 0.2)        // neon flame
        case "fire": return Color(red: 1.0, green: 0.35, blue: 0.1)           // neon fire
        case "safety": return Color(red: 1.0, green: 0.3, blue: 0.3)          // neon alert red
        case "navigation": return Color(red: 0.2, green: 0.8, blue: 0.4)      // neon map green
        case "cleanup": return Color(red: 0.4, green: 0.95, blue: 0.6)        // neon fresh green
        case "water": return Color(red: 0.2, green: 0.7, blue: 1.0)           // neon water blue

        default: return Color(red: 0.6, green: 0.6, blue: 0.7)
        }
    }
}
