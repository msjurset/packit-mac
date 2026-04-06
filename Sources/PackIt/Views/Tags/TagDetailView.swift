import SwiftUI

struct TagDetailView: View {
    @Environment(PackItStore.self) private var store
    let tag: ContextTag

    private var templateMatches: [PackingTemplate] {
        store.templates.filter { $0.contextTags.contains(tag.name) }
    }

    private var itemMatches: [(template: PackingTemplate, item: TemplateItem)] {
        var results: [(PackingTemplate, TemplateItem)] = []
        for template in store.templates {
            for item in template.items where item.contextTags.contains(tag.name) {
                results.append((template, item))
            }
        }
        return results
    }

    private var tripMatches: [TripInstance] {
        store.trips.filter { trip in
            trip.items.contains { $0.name.lowercased() == tag.name.lowercased() } ||
            templateMatches.contains { trip.sourceTemplateIDs.contains($0.id) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    StyledTag(name: tag.name)
                        .font(.title3)
                    Spacer()
                }

                // Summary
                HStack(spacing: 20) {
                    Label("\(templateMatches.count) templates", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(itemMatches.count) tagged items", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Templates using this tag
                if !templateMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Templates")
                            .font(.headline)

                        VStack(spacing: 2) {
                            ForEach(templateMatches) { template in
                                Button {
                                    navigateToTemplate(template)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "doc.on.doc.fill")
                                            .font(.caption)
                                            .foregroundStyle(.packitTeal)
                                            .frame(width: 16)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name)
                                                .font(.callout.weight(.medium))
                                                .foregroundStyle(.primary)
                                            Text("\(template.itemCount) items")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(Color.primary.opacity(0.001))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(10)
                        .background(.secondary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Items tagged with this tag
                if !itemMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tagged Items")
                            .font(.headline)

                        let grouped = Dictionary(grouping: itemMatches, by: { $0.template.name })
                        let sortedKeys = grouped.keys.sorted()

                        ForEach(sortedKeys, id: \.self) { templateName in
                            VStack(alignment: .leading, spacing: 4) {
                                Button {
                                    if let template = grouped[templateName]?.first?.template {
                                        navigateToTemplate(template)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(templateName.uppercased())
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .buttonStyle(.plain)

                                ForEach(grouped[templateName] ?? [], id: \.item.id) { match in
                                    HStack(spacing: 8) {
                                        PriorityBadge(priority: match.item.priority)
                                        Text(match.item.name)
                                            .font(.callout)
                                        if match.item.quantity > 1 {
                                            Text("×\(match.item.quantity)")
                                                .font(.caption2.bold().monospacedDigit())
                                                .foregroundStyle(.packitTeal)
                                        }
                                        Spacer()
                                        if let cat = match.item.category {
                                            Text(cat)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 10)
                                }
                            }
                            .padding(10)
                            .background(.secondary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                // No usage
                if templateMatches.isEmpty && itemMatches.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tag.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("This tag isn't used by any templates or items yet.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
        .accessibilityIdentifier("tagDetail")
        .navigationTitle("Tag")
    }

    private func navigateToTemplate(_ template: PackingTemplate) {
        store.selectedTemplateID = template.id
        store.navigation = .templateDetail(template.id)
    }
}
