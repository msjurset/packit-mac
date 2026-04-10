import SwiftUI

struct DestinationField: View {
    @Binding var destination: TripDestination?
    @State private var searchText = ""
    @State private var suggestions: [TripDestination] = []
    @State private var isFocused = false
    @State private var showSuggestions = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                LeadingTextField(
                    label: "Destination",
                    text: $searchText,
                    prompt: "City or place name",
                    isFocused: $isFocused
                )
                if destination != nil {
                    Button {
                        destination = nil
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onChange(of: searchText) {
                if destination != nil && searchText != destination?.displayName {
                    destination = nil
                }
                debouncedSearch()
            }
            .onChange(of: isFocused) {
                if !isFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showSuggestions = false
                    }
                }
            }

            if showSuggestions && !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions, id: \.self) { place in
                            Button {
                                destination = place
                                searchText = place.displayName
                                showSuggestions = false
                            } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(place.name)
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                    if let admin1 = place.admin1, let country = place.country {
                                        Text("\(admin1), \(country)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 0.5))
                .padding(.top, 2)
            }
        }
        .onAppear {
            if let dest = destination {
                searchText = dest.displayName
            }
        }
    }

    private func debouncedSearch() {
        searchTask?.cancel()
        let query = searchText
        guard query.count >= 2, destination == nil else {
            showSuggestions = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let results = try await GeocodingService.shared.search(query: query)
                await MainActor.run {
                    suggestions = results
                    showSuggestions = !results.isEmpty && isFocused
                }
            } catch {
                // Silently fail — user can retry
            }
        }
    }
}
