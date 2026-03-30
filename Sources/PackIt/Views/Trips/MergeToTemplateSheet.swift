import SwiftUI

struct MergeToTemplateSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trip: TripInstance

    @State private var selectedItemIDs: Set<UUID> = []
    @State private var targetTemplateID: UUID?

    private var adHocItems: [TripItem] {
        trip.items.filter(\.isAdHoc)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Ad-Hoc Items to Merge") {
                    if adHocItems.isEmpty {
                        Text("No ad-hoc items to merge.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(adHocItems) { item in
                            Toggle(isOn: Binding(
                                get: { selectedItemIDs.contains(item.id) },
                                set: { isOn in
                                    if isOn { selectedItemIDs.insert(item.id) }
                                    else { selectedItemIDs.remove(item.id) }
                                }
                            )) {
                                HStack {
                                    Text(item.name)
                                    if let cat = item.category {
                                        Text(cat)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        Button("Select All") {
                            selectedItemIDs = Set(adHocItems.map(\.id))
                        }
                    }
                }

                Section("Target Template") {
                    if store.templates.isEmpty {
                        Text("No templates available. Create a template first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Template", selection: $targetTemplateID) {
                            Text("Select a template...").tag(nil as UUID?)
                            ForEach(store.templates) { template in
                                Text(template.name).tag(template.id as UUID?)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Merge") {
                    guard let templateID = targetTemplateID else { return }
                    store.promoteItems(Array(selectedItemIDs), from: trip.id, to: templateID)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedItemIDs.isEmpty || targetTemplateID == nil)
            }
            .padding()
        }
        .frame(width: 500, height: 500)
        .onAppear {
            selectedItemIDs = Set(adHocItems.map(\.id))
            if let firstSource = trip.sourceTemplateIDs.first {
                targetTemplateID = firstSource
            }
        }
    }
}
