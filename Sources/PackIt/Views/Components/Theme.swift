import SwiftUI

// MARK: - Colors

extension Color {
    static let packitTeal = Color(red: 0.10, green: 0.55, blue: 0.55)
    static let packitTealLight = Color(red: 0.15, green: 0.65, blue: 0.65)
    static let packitTealMuted = Color(red: 0.10, green: 0.55, blue: 0.55).opacity(0.12)
    static let packitAmber = Color(red: 0.90, green: 0.65, blue: 0.20)
    static let packitGreen = Color(red: 0.30, green: 0.75, blue: 0.45)
    static let packitRed = Color(red: 0.90, green: 0.30, blue: 0.25)
}

extension ShapeStyle where Self == Color {
    static var packitTeal: Color { .packitTeal }
    static var packitTealLight: Color { .packitTealLight }
    static var packitAmber: Color { .packitAmber }
    static var packitGreen: Color { .packitGreen }
    static var packitRed: Color { .packitRed }

    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .secondary
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .packitRed
        }
    }

    static func statusColor(_ status: TripStatus) -> Color {
        switch status {
        case .planning: return .packitTeal
        case .active: return .packitGreen
        case .completed: return .secondary
        case .archived: return .secondary
        }
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    var isHovered: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background)
                    .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 6 : 3, y: isHovered ? 2 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle(isHovered: Bool = false) -> some View {
        modifier(CardStyle(isHovered: isHovered))
    }
}

// MARK: - Styled Tag

struct StyledTag: View {
    let name: String
    var color: Color = .packitTeal
    var compact: Bool = false

    var body: some View {
        Text(name)
            .font(compact ? .system(size: 9, weight: .medium) : .caption2.weight(.medium))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: Priority

    var body: some View {
        Image(systemName: priority.icon)
            .font(.caption2)
            .foregroundStyle(Color.priorityColor(priority))
    }
}
