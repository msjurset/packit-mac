import SwiftUI

struct WeatherWidget: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var forecasts: [DailyForecast] = []
    @State private var airQuality: AirQuality?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showDetail = false
    @State private var isCollapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { isCollapsed.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                            .frame(width: 8)
                        Label("Weather", systemImage: "cloud.sun.fill")
                            .font(.headline)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                if !isCollapsed {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button { fetchWeather() } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Refresh forecast")
                    }
                }
            }

            if isCollapsed { } else {

            if let dest = trip.destination {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.packitTeal)
                    Text(dest.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.packitRed)
                } else if forecasts.isEmpty && !isLoading {
                    Text("No forecast data")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else if !forecasts.isEmpty {
                    if forecasts.first?.isHistorical == true {
                        Text("Based on last year's weather for these dates")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    // Compact daily forecast row
                    Button { showDetail = true } label: {
                        compactForecast
                    }
                    .buttonStyle(.plain)
                    .help("Click for detailed forecast")
                }

                if let aq = airQuality {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(aq.color)
                            .frame(width: 6, height: 6)
                        Text("AQI \(aq.aqi) — \(aq.level)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Set destination to see forecast")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
            } // end if !isCollapsed
        }
        .task {
            fetchWeather()
        }
        .sheet(isPresented: $showDetail) {
            WeatherDetailSheet(trip: trip, forecasts: forecasts, airQuality: airQuality, onRefresh: fetchWeather)
        }
    }

    private var compactForecast: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(forecasts) { day in
                    VStack(spacing: 3) {
                        Text(day.dayAbbrev)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Image(systemName: day.symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(day.symbolColor)
                            .frame(height: 16)
                        Text("\(Int(day.highF))°")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.primary)
                        Text("\(Int(day.lowF))°")
                            .font(.system(size: 9).monospacedDigit())
                            .foregroundStyle(.tertiary)
                        if day.precipitationProbability > 20 {
                            HStack(spacing: 1) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.cyan)
                                Text("\(day.precipitationProbability)%")
                                    .font(.system(size: 7).monospacedDigit())
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }
                    .frame(width: 38)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .background(.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func fetchWeather() {
        guard let dest = trip.destination else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let endDate = trip.returnDate ?? Calendar.current.date(byAdding: .day, value: 7, to: trip.departureDate)!
                let result = try await WeatherService.shared.fetchForecast(
                    latitude: dest.latitude,
                    longitude: dest.longitude,
                    startDate: trip.departureDate,
                    endDate: endDate,
                    config: store.localConfig
                )
                let aq = try? await WeatherService.shared.fetchAirQuality(
                    latitude: dest.latitude,
                    longitude: dest.longitude
                )
                await MainActor.run {
                    forecasts = result
                    airQuality = aq
                    isLoading = false
                }
            } catch let err as WeatherError {
                await MainActor.run {
                    self.error = err.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Unable to load forecast: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Weather Detail Sheet

struct WeatherDetailSheet: View {
    let trip: TripInstance
    let forecasts: [DailyForecast]
    let airQuality: AirQuality?
    var onRefresh: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weather Forecast")
                        .font(.headline)
                    if let dest = trip.destination {
                        Text(dest.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { onRefresh() } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Daily breakdown
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(forecasts.enumerated()), id: \.element.id) { index, day in
                        HStack(spacing: 12) {
                            // Date + condition
                            VStack(alignment: .leading, spacing: 2) {
                                Text(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.callout.weight(.medium))
                                HStack(spacing: 4) {
                                    Image(systemName: day.symbol)
                                        .foregroundStyle(day.symbolColor)
                                        .font(.callout)
                                    Text(day.condition)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 160, alignment: .leading)

                            // Temps
                            VStack(spacing: 1) {
                                Text("\(Int(day.highF))°/\(Int(day.lowF))°")
                                    .font(.callout.weight(.semibold).monospacedDigit())
                                Text("Feels \(Int(day.feelsLikeHighF))°/\(Int(day.feelsLikeLowF))°")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 90)

                            // Precip
                            VStack(spacing: 1) {
                                HStack(spacing: 2) {
                                    Image(systemName: "drop.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.cyan)
                                    Text("\(day.precipitationProbability)%")
                                        .font(.caption.monospacedDigit())
                                }
                                if day.precipitationInches > 0 {
                                    Text(String(format: "%.2f\"", day.precipitationInches))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 55)

                            // Wind
                            VStack(spacing: 1) {
                                HStack(spacing: 2) {
                                    Image(systemName: "wind")
                                        .font(.caption2)
                                    Text("\(Int(day.windSpeedMph))")
                                        .font(.caption.monospacedDigit())
                                }
                                Text("gust \(Int(day.windGustMph))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 60)

                            // Humidity + UV
                            VStack(spacing: 1) {
                                HStack(spacing: 2) {
                                    Image(systemName: "humidity.fill")
                                        .font(.caption2)
                                    Text("\(day.humidity)%")
                                        .font(.caption.monospacedDigit())
                                }
                                Text("UV \(Int(day.uvIndex))")
                                    .font(.caption2)
                                    .foregroundStyle(day.uvIndex >= 6 ? .orange : .secondary)
                            }
                            .frame(width: 55)

                            // Pressure
                            VStack(spacing: 1) {
                                Text(String(format: "%.0f", day.pressureHpa))
                                    .font(.caption.monospacedDigit())
                                Text("hPa")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 45)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.04) : .clear)
                    }
                }
            }

            // Air quality
            if let aq = airQuality {
                Divider()
                HStack(spacing: 12) {
                    Circle()
                        .fill(aq.color)
                        .frame(width: 10, height: 10)
                    Text("Air Quality: \(aq.level) (AQI \(aq.aqi))")
                        .font(.caption)
                    Spacer()
                    Text("PM2.5: \(String(format: "%.1f", aq.pm25)) · PM10: \(String(format: "%.1f", aq.pm10))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 620, height: 450)
    }
}
