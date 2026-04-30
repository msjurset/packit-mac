import SwiftUI
import PackItKit

struct SharedBadge: View {
    let author: String?
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "person.crop.circle.badge.checkmark")
            if !compact {
                if let author, !author.isEmpty {
                    Text("Shared by \(author)")
                } else {
                    Text("Shared")
                }
            }
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(Color.packitTeal)
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, 2)
        .background(Color.packitTeal.opacity(0.12))
        .clipShape(Capsule())
        .help(author.map { "Shared by \($0)" } ?? "Shared with you")
    }
}

/// Indicator for resources YOU are sharing out (in the shared folder).
struct SharingOutBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "person.2.fill")
            if !compact {
                Text("Shared")
            }
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(Color.packitGreen)
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, 2)
        .background(Color.packitGreen.opacity(0.14))
        .clipShape(Capsule())
        .help("You're sharing this in the shared folder")
    }
}
