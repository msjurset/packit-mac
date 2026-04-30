import SwiftUI
import PackItKit

struct StatisticsView: View {
    @Environment(PackItStore.self) private var store

    private var finishedTrips: [TripInstance] {
        store.trips.filter { $0.status == .completed || $0.status == .archived }
    }

    private var allTrips: [TripInstance] { store.trips }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Trip Statistics")
                    .font(.title2.bold())

                if allTrips.isEmpty {
                    ContentUnavailableView("No Trips Yet", systemImage: "chart.bar", description: Text("Create some trips to see statistics here."))
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    overviewCards

                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            topItemsSection
                            adHocInsightsSection
                            tagUsageSection
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 16) {
                            topCategoriesSection
                            templatePopularitySection
                            packingEfficiencySection
                        }
                        .frame(maxWidth: .infinity)
                    }

                    tripTimelineSection
                }
            }
            .padding()
        }
        .navigationTitle("Statistics")
    }

    // MARK: - Overview Cards

    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)], spacing: 12) {
            StatCard(title: "Total Trips", value: "\(allTrips.count)", icon: "suitcase.fill", color: .packitTeal)
            StatCard(title: "Items Packed", value: "\(totalItemsPacked)", icon: "checkmark.circle.fill", color: .packitGreen)
            StatCard(title: "Completion Rate", value: completionRate, icon: "percent", color: .blue)
            StatCard(title: "Templates", value: "\(store.templates.count)", icon: "doc.on.doc.fill", color: .packitAmber)
            StatCard(title: "Avg Items/Trip", value: avgItemsPerTrip, icon: "list.bullet", color: .purple)
            StatCard(title: "Ad-Hoc Items", value: "\(totalAdHocItems)", icon: "sparkles", color: .orange)
        }
    }

    private var totalItemsPacked: Int {
        allTrips.reduce(0) { $0 + $1.packedCount }
    }

    private var totalAdHocItems: Int {
        allTrips.reduce(0) { $0 + $1.adHocItems.count }
    }

    private var completionRate: String {
        let finished = finishedTrips
        guard !finished.isEmpty else { return "—" }
        let avg = finished.reduce(0.0) { $0 + $1.progress } / Double(finished.count)
        return "\(Int(avg * 100))%"
    }

    private var avgItemsPerTrip: String {
        guard !allTrips.isEmpty else { return "—" }
        let avg = Double(allTrips.reduce(0) { $0 + $1.totalItems }) / Double(allTrips.count)
        return String(format: "%.0f", avg)
    }

    // MARK: - Top Items

    private var topItemsSection: some View {
        let counts = itemFrequency()
        let top = counts.prefix(10)

        return Group {
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Most Packed Items", systemImage: "star.fill")
                        .font(.headline)

                    VStack(spacing: 2) {
                        ForEach(Array(top.enumerated()), id: \.element.name) { index, entry in
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                Text(entry.name)
                                    .font(.callout)
                                Spacer()
                                Text("\(entry.count) trips")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                BarSegment(value: Double(entry.count), max: Double(top.first?.count ?? 1))
                                    .frame(width: 80)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.03) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Top Categories

    private var topCategoriesSection: some View {
        let counts = categoryFrequency()
        let top = counts.prefix(8)

        return Group {
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Top Categories", systemImage: "folder.fill")
                        .font(.headline)

                    VStack(spacing: 2) {
                        ForEach(Array(top.enumerated()), id: \.element.name) { index, entry in
                            HStack(spacing: 10) {
                                Image(systemName: CategoryIcon.icon(for: entry.name))
                                    .font(.caption)
                                    .foregroundStyle(CategoryIcon.color(for: entry.name))
                                    .frame(width: 16)
                                Text(entry.name)
                                    .font(.callout)
                                Spacer()
                                Text("\(entry.count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                BarSegment(value: Double(entry.count), max: Double(top.first?.count ?? 1))
                                    .frame(width: 80)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.03) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Ad-Hoc Insights

    private var adHocInsightsSection: some View {
        let counts = adHocFrequency()
        let top = counts.prefix(5)

        return Group {
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Frequently Added Ad-Hoc", systemImage: "lightbulb.fill")
                        .font(.headline)

                    Text("These items are often added during trips. Consider adding them to a template.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 2) {
                        ForEach(Array(top.enumerated()), id: \.element.name) { index, entry in
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                                Text(entry.name)
                                    .font(.callout)
                                Spacer()
                                Text("\(entry.count)x")
                                    .font(.caption.bold())
                                    .foregroundStyle(.purple)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(index.isMultiple(of: 2) ? Color.purple.opacity(0.03) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding()
                .background(.purple.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Trip Timeline

    private var tripTimelineSection: some View {
        let sorted = allTrips.sorted { $0.departureDate > $1.departureDate }

        return VStack(alignment: .leading, spacing: 10) {
            Label("Trip Timeline", systemImage: "calendar")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, trip in
                    HStack(spacing: 12) {
                        // Timeline dot and line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Color.statusColor(trip.status))
                                .frame(width: 10, height: 10)
                            if index < sorted.count - 1 {
                                Rectangle()
                                    .fill(.secondary.opacity(0.2))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 10)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(trip.name)
                                    .font(.callout.weight(.medium))
                                Spacer()
                                Text(trip.status.label)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.statusColor(trip.status).opacity(0.12))
                                    .foregroundStyle(Color.statusColor(trip.status))
                                    .clipShape(Capsule())
                            }
                            HStack(spacing: 12) {
                                Text(trip.departureDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(trip.totalItems) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if trip.progress > 0 {
                                    Text("\(Int(trip.progress * 100))% packed")
                                        .font(.caption)
                                        .foregroundStyle(trip.progress >= 1.0 ? Color.packitGreen : Color.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .background(.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Tag Usage

    private var tagUsageSection: some View {
        let counts = tagFrequency()
        let top = counts.prefix(10)

        return Group {
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tag Usage", systemImage: "tag.fill")
                        .font(.headline)

                    VStack(spacing: 2) {
                        ForEach(Array(top.enumerated()), id: \.element.name) { index, entry in
                            HStack(spacing: 10) {
                                StyledTag(name: entry.name, compact: true)
                                Spacer()
                                Text("\(entry.count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                BarSegment(value: Double(entry.count), max: Double(top.first?.count ?? 1))
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 10)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.03) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Template Popularity

    private var templatePopularitySection: some View {
        let counts = templateUsage()
        let top = counts.prefix(8)

        return Group {
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Template Popularity", systemImage: "doc.on.doc.fill")
                        .font(.headline)

                    Text("How often each template is used as a trip source.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 2) {
                        ForEach(Array(top.enumerated()), id: \.element.name) { index, entry in
                            HStack(spacing: 10) {
                                Text(entry.name)
                                    .font(.callout)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(entry.count) trips")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                BarSegment(value: Double(entry.count), max: Double(top.first?.count ?? 1))
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.03) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Packing Efficiency

    private var packingEfficiencySection: some View {
        let efficiencies = categoryEfficiency()

        return Group {
            if !efficiencies.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Packing Rate by Category", systemImage: "chart.bar.fill")
                        .font(.headline)

                    Text("How completely each category gets packed across trips.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 2) {
                        ForEach(Array(efficiencies.enumerated()), id: \.element.name) { index, entry in
                            HStack(spacing: 10) {
                                Image(systemName: CategoryIcon.icon(for: entry.name))
                                    .font(.caption)
                                    .foregroundStyle(CategoryIcon.color(for: entry.name))
                                    .frame(width: 16)
                                Text(entry.name)
                                    .font(.callout)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(entry.count)%")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(entry.count >= 80 ? Color.packitGreen : entry.count >= 50 ? Color.packitTeal : Color.secondary)
                                BarSegment(value: Double(entry.count), max: 100)
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.03) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Data Helpers

    private struct FrequencyEntry {
        let name: String
        let count: Int
    }

    private func itemFrequency() -> [FrequencyEntry] {
        var counts: [String: Int] = [:]
        for trip in allTrips {
            for item in trip.items {
                counts[item.name, default: 0] += 1
            }
        }
        return counts.map { FrequencyEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func categoryFrequency() -> [FrequencyEntry] {
        var counts: [String: Int] = [:]
        for trip in allTrips {
            for item in trip.items {
                let cat = item.category ?? "Uncategorized"
                counts[cat, default: 0] += 1
            }
        }
        return counts.map { FrequencyEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func tagFrequency() -> [FrequencyEntry] {
        var counts: [String: Int] = [:]
        for template in store.templates {
            for tag in template.contextTags {
                counts[tag, default: 0] += template.itemCount
            }
            for item in template.items {
                for tag in item.contextTags {
                    counts[tag, default: 0] += 1
                }
            }
        }
        return counts.map { FrequencyEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func templateUsage() -> [FrequencyEntry] {
        var counts: [String: Int] = [:]
        let templateMap = Dictionary(uniqueKeysWithValues: store.templates.map { ($0.id, $0.name) })
        for trip in allTrips {
            for tid in trip.sourceTemplateIDs {
                if let name = templateMap[tid] {
                    counts[name, default: 0] += 1
                }
            }
        }
        return counts.map { FrequencyEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func categoryEfficiency() -> [FrequencyEntry] {
        var packed: [String: Int] = [:]
        var total: [String: Int] = [:]
        for trip in finishedTrips {
            for item in trip.items {
                let cat = item.category ?? "Uncategorized"
                total[cat, default: 0] += 1
                if item.isPacked { packed[cat, default: 0] += 1 }
            }
        }
        // Also include active trips for more data
        for trip in allTrips where trip.status == .active {
            for item in trip.items {
                let cat = item.category ?? "Uncategorized"
                total[cat, default: 0] += 1
                if item.isPacked { packed[cat, default: 0] += 1 }
            }
        }
        return total.map { cat, count in
            let pct = count > 0 ? (packed[cat, default: 0] * 100) / count : 0
            return FrequencyEntry(name: cat, count: pct)
        }
        .sorted { $0.count > $1.count }
        .prefix(10).map { $0 }
    }

    private func adHocFrequency() -> [FrequencyEntry] {
        var counts: [String: Int] = [:]
        for trip in allTrips {
            for item in trip.adHocItems {
                counts[item.name, default: 0] += 1
            }
        }
        return counts.filter { $0.value >= 2 }
            .map { FrequencyEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title.bold().monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Bar Segment

struct BarSegment: View {
    let value: Double
    let max: Double

    private var fraction: Double {
        guard max > 0 else { return 0 }
        return value / max
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.secondary.opacity(0.1))
                RoundedRectangle(cornerRadius: 3)
                    .fill(.packitTeal.opacity(0.6))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
    }
}
