import SwiftUI

struct TripEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trip: TripInstance

    @State private var name: String = ""
    @State private var departureDate: Date = .now
    @State private var returnDate: Date = .now
    @State private var hasReturnDate = false
    @State private var scratchNotes: String = ""
    @State private var status: TripStatus = .planning

    var body: some View {
        FormSheet(width: 500, height: 500) {
            Section("Trip Details") {
                LeadingTextField(label: "Name", text: $name)
                DatePicker("Departure", selection: $departureDate, displayedComponents: .date)
                Toggle("Return Date", isOn: $hasReturnDate)
                if hasReturnDate {
                    DatePicker("Return", selection: $returnDate, displayedComponents: .date)
                }
                Picker("Status", selection: $status) {
                    ForEach(TripStatus.allCases, id: \.self) { s in
                        Label(s.label, systemImage: s.icon).tag(s)
                    }
                }
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
            departureDate = trip.departureDate
            returnDate = trip.returnDate ?? .now
            hasReturnDate = trip.returnDate != nil
            scratchNotes = trip.scratchNotes
            status = trip.status
        }
    }

    private func save() {
        var updated = trip
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.departureDate = departureDate
        updated.returnDate = hasReturnDate ? returnDate : nil
        updated.scratchNotes = scratchNotes
        updated.status = status
        store.updateTrip(updated)
        dismiss()
    }
}
