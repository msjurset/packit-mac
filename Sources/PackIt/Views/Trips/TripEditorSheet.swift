import SwiftUI

struct TripEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trip: TripInstance

    @State private var name: String = ""
    @State private var icon: TripIcon = .suitcase
    @State private var destination: TripDestination?
    @State private var departureDate: Date = .now
    @State private var returnDate: Date = .now
    @State private var scratchNotes: String = ""
    @State private var status: TripStatus = .planning
    @State private var members: [String] = []
    @State private var travelMode: TravelMode = .plane

    var body: some View {
        FormSheet(width: 500, height: 500) {
            Section("Trip Details") {
                HStack(spacing: 12) {
                    TripIconPicker(selection: $icon)
                    LeadingTextField(label: "Name", text: $name)
                }
                LabeledContent("Departure") {
                    HStack(spacing: 6) {
                        StepperDateField(selection: $departureDate)
                            .onChange(of: departureDate) { _, newStart in
                                if returnDate < newStart {
                                    returnDate = Calendar.current.date(byAdding: .day, value: 7, to: newStart) ?? newStart
                                }
                            }
                        CalendarPopoverButton(selection: $departureDate)
                    }
                }
                LabeledContent("Return") {
                    HStack(spacing: 6) {
                        StepperDateField(selection: $returnDate, minDate: departureDate)
                        CalendarPopoverButton(selection: $returnDate, minDate: departureDate)
                    }
                }
                DestinationField(destination: $destination)
                Picker("Travel Mode", selection: $travelMode) {
                    ForEach(TravelMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.symbol).tag(mode)
                    }
                }
                Picker("Status", selection: $status) {
                    ForEach(TripStatus.allCases, id: \.self) { s in
                        Label(s.label, systemImage: s.icon).tag(s)
                    }
                }
            }

            Section("Members") {
                Text("Each member can own packing items. Items with no owner are shared.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MemberListEditor(members: $members)
            }

            Section("Notes") {
                TextEditor(text: $scratchNotes)
                    .frame(minHeight: 100)
            }
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Save") { save() }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear {
            name = trip.name
            icon = trip.icon
            destination = trip.destination
            departureDate = trip.departureDate
            returnDate = trip.returnDate ?? Calendar.current.date(byAdding: .day, value: 7, to: trip.departureDate) ?? trip.departureDate
            scratchNotes = trip.scratchNotes
            status = trip.status
            members = trip.members
            travelMode = trip.travelMode
        }
    }

    private func save() {
        var updated = trip
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.icon = icon
        updated.destination = destination
        updated.departureDate = departureDate
        updated.returnDate = returnDate
        updated.scratchNotes = scratchNotes
        updated.status = status
        updated.members = members
        updated.travelMode = travelMode
        store.updateTrip(updated)
        dismiss()
    }
}
