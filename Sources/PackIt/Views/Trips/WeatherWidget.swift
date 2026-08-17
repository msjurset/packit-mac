import SwiftUI
import PackItKit

// MARK: - Tide Chart Extensions

extension TideEvent {
    static func interpolatedHeight(at date: Date, in events: [TideEvent]) -> Double? {
        let sorted = events.sorted(by: { $0.date < $1.date })
        guard let first = sorted.first, let last = sorted.last, sorted.count >= 2 else { return nil }
        
        if date < first.date || date > last.date { return nil }
        
        for i in 0..<(sorted.count - 1) {
            let e1 = sorted[i]
            let e2 = sorted[i+1]
            if date >= e1.date && date <= e2.date {
                let range = e2.date.timeIntervalSince(e1.date)
                let t = date.timeIntervalSince(e1.date) / range
                let sineT = 0.5 - 0.5 * cos(.pi * t)
                return e1.heightMeters + (e2.heightMeters - e1.heightMeters) * sineT
            }
        }
        return nil
    }
}

struct TideTooltip: View {
    let date: Date
    let heightFeet: Double
    let timezoneIdentifier: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            let style: Date.FormatStyle = {
                var s = Date.FormatStyle.dateTime.weekday(.abbreviated).hour().minute()
                s.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
                return s
            }()
            Text(date.formatted(style))
                .font(.system(size: 7, weight: .bold))
            Text(String(format: "%.2f ft", heightFeet))
                .font(.system(size: 7))
                .foregroundStyle(.packitTeal)
        }
        .padding(4)
        .background(.background.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.separator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

// MARK: - Weather Widget Component

struct WeatherWidget: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var forecasts: [DailyForecast] = []
    @State private var hourlyForecasts: [HourlyForecast] = []
    @State private var airQuality: AirQuality?
    @State private var tideEvents: [TideEvent] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showDetail = false
    @State private var showTideDetail = false
    @State private var isCollapsed = false
    @State private var mode: WidgetMode = .weather
    @State private var hoverDate: Date?

    enum WidgetMode {
        case weather
        case tides
    }

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
                        Label(mode == .weather ? "Weather" : "Tides", systemImage: mode == .weather ? "cloud.sun.fill" : "waveform.path.ecg")
                            .font(.headline)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                
                Spacer()
                
                if !isCollapsed {
                    HStack(spacing: 12) {
                        if !tideEvents.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    mode = (mode == .weather ? .tides : .weather)
                                }
                            } label: {
                                Image(systemName: mode == .weather ? "waveform.path.ecg" : "cloud.sun")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.packitTeal)
                                    .padding(4)
                                    .background(.packitTeal.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                            .focusable(false)
                            .help(mode == .weather ? "Show tide chart" : "Show weather forecast")
                        }

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
                            .focusable(false)
                            .help("Refresh forecast")
                        }
                    }
                }
            }

            if !isCollapsed {
                if let dest = trip.destination {
                    if mode == .weather {
                        weatherView(dest: dest)
                    } else {
                        Button { showTideDetail = true } label: {
                            tideView
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .popover(isPresented: $showTideDetail, arrowEdge: .bottom) {
                            TideDetailView(events: tideEvents, uniqueDays: uniqueDays)
                        }
                    }
                } else {
                    Text("Set destination to see forecast")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            }
        }
        .task {
            fetchWeather()
        }
        .sheet(isPresented: $showDetail) {
            WeatherDetailSheet(
                trip: trip,
                forecasts: forecasts,
                hourlyForecasts: hourlyForecasts,
                airQuality: airQuality,
                onRefresh: fetchWeather
            )
        }
    }

    @ViewBuilder
    private func weatherView(dest: TripDestination) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.packitTeal)
                    Text(dest.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let currentTemp = forecasts.compactMap(\.currentTempF).first {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    HStack(spacing: 4) {
                        let currentCode = forecasts.compactMap(\.currentCode).first ?? forecasts.first?.weatherCode ?? 0
                        Image(systemName: WeatherCode.sfSymbol(for: currentCode))
                            .font(.system(size: 10))
                            .foregroundStyle(WeatherCode.color(for: currentCode))
                        
                        Text("\(Int(currentTemp))°")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                }
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
                
                if !captions.isEmpty {
                    actionableCaption
                }
                
                Button { showDetail = true } label: {
                    compactForecast
                }
                .buttonStyle(.plain)
                .focusable(false)
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
        }
    }

    private var actionableCaption: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(captions, id: \.self) { line in
                HStack(spacing: 6) {
                    Image(systemName: line.icon)
                        .font(.caption)
                        .foregroundStyle(line.tint)
                        .frame(width: 14)
                    Text(line.text)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private struct Caption: Hashable {
        let icon: String
        let tint: Color
        let text: String
    }

    private var captions: [Caption] {
        var lines: [Caption] = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        if let wetDay = forecasts.first(where: { $0.isLikelyWet }) {
            let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: wetDay.date)).day ?? 0
            let when: String = switch days {
            case ...0: "today"
            case 1: "tomorrow"
            default: wetDay.date.formatted(.dateTime.weekday(.wide))
            }
            lines.append(Caption(
                icon: "drop.fill",
                tint: .cyan,
                text: "Rain expected: \(when) (\(wetDay.precipitationProbability)% — \(String(format: "%.2f", wetDay.precipitationInches))\")"
            ))
        } else if !forecasts.isEmpty {
            lines.append(Caption(icon: "sun.max.fill", tint: .yellow,
                                 text: "Clear weather: No heavy rain forecast during trip"))
        }

        if let frost = forecasts.first(where: { $0.isFrosty }) {
            let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: frost.date)).day ?? 0
            let when: String = switch days {
            case ...0: "tonight"
            case 1: "tomorrow night"
            default: frost.date.formatted(.dateTime.weekday(.wide))
            }
            lines.append(Caption(
                icon: "snowflake",
                tint: .cyan,
                text: "Frost risk \(when) (low \(Int(frost.lowF))°F)"
            ))
        }

        if let uv = forecasts.first(where: { $0.isHighUV }) {
            let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: uv.date)).day ?? 0
            if days <= 7 {
                let when = days <= 0 ? "today" : (days == 1 ? "tomorrow" : uv.date.formatted(.dateTime.weekday(.wide)))
                lines.append(Caption(
                    icon: "sun.max.trianglebadge.exclamationmark.fill",
                    tint: .orange,
                    text: "Very high UV \(when) (\(Int(uv.uvIndex)))"
                ))
            }
        }

        return lines
    }

    private var tideView: some View {
        let dayWidth: CGFloat = 110
        let totalWidth = max(200, CGFloat(uniqueDays.count) * dayWidth)
        let cal = destinationCalendar
        
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                TideChart(events: tideEvents, dayMarkers: uniqueDays, hoverDate: $hoverDate, timezoneIdentifier: tideEvents.first?.timezoneIdentifier ?? "UTC")
                    .frame(width: totalWidth, height: 75)
                
                if let firstDay = uniqueDays.first {
                    let minTime = firstDay.timeIntervalSinceReferenceDate
                    let maxTime = cal.date(byAdding: .day, value: 1, to: uniqueDays.last!)!.timeIntervalSinceReferenceDate
                    let timeRange = maxTime - minTime
                    
                    VStack(alignment: .leading, spacing: 2) {
                        ZStack(alignment: .leading) {
                            ForEach(uniqueDays, id: \.self) { day in
                                let x = CGFloat((day.timeIntervalSinceReferenceDate - minTime) / timeRange) * totalWidth
                                Text(day.formatted(.dateTime.weekday(.abbreviated).day()))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .offset(x: x + 4)
                            }
                        }
                        .frame(width: totalWidth, height: 12, alignment: .leading)
                        
                        ZStack(alignment: .leading) {
                            ForEach(tideEvents.filter { $0.type == .high }) { event in
                                let x = CGFloat((event.date.timeIntervalSinceReferenceDate - minTime) / timeRange) * totalWidth
                                tideLabel(event: event)
                                    .offset(x: x)
                            }
                        }
                        .frame(width: totalWidth, height: 12, alignment: .leading)
                        
                        ZStack(alignment: .leading) {
                            ForEach(tideEvents.filter { $0.type == .low }) { event in
                                let x = CGFloat((event.date.timeIntervalSinceReferenceDate - minTime) / timeRange) * totalWidth
                                tideLabel(event: event)
                                    .offset(x: x)
                            }
                        }
                        .frame(width: totalWidth, height: 12, alignment: .leading)
                    }
                }
            }
            .padding(8)
        }
        .background(.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
    }

    private func tideLabel(event: TideEvent) -> some View {
        let isProximate: Bool = {
            guard let hoverDate else { return false }
            return abs(event.date.timeIntervalSince(hoverDate)) < 1800
        }()
        let iconSize: CGFloat = isProximate ? 10 : 8
        return HStack(spacing: 2) {
            Image(systemName: event.type == .high ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(event.type == .high ? .packitTeal : .secondary)
                .shadow(color: .packitTeal.opacity(isProximate ? 0.6 : 0), radius: 3)
            Text(event.timeLabel)
                .font(.system(size: isProximate ? 9 : 7.5, weight: isProximate ? .bold : .medium).monospacedDigit())
            Text(String(format: "%.0f'", event.heightFeet))
                .font(.system(size: isProximate ? 8 : 6.5))
                .foregroundStyle(isProximate ? .primary : .tertiary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1.5)
        .background(isProximate ? .packitTeal.opacity(0.15) : .secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .scaleEffect(isProximate ? 1.15 : 1.0)
        .offset(x: -(4 + iconSize/2)) 
    }

    private var destinationCalendar: Calendar {
        var cal = Calendar.current
        if let timezoneID = tideEvents.first?.timezoneIdentifier {
            cal.timeZone = TimeZone(identifier: timezoneID) ?? .current
        }
        return cal
    }

    private var uniqueDays: [Date] {
        let cal = destinationCalendar
        let days = Set(tideEvents.map { cal.startOfDay(for: $0.date) })
        return days.sorted()
    }

    private var paddedForecasts: [DayCell] {
        let cal = Calendar.current
        let lastTripDay = trip.returnDate ?? trip.departureDate
        let real = forecasts.map { f -> DayCell in
            let isPostTrip = cal.startOfDay(for: f.date) > cal.startOfDay(for: lastTripDay)
            return DayCell.real(f, isPostTrip: isPostTrip)
        }
        let target = max(7, forecasts.count)
        let needed = target - real.count
        guard needed > 0 else { return real }
        let lastDate = forecasts.last?.date ?? trip.departureDate
        let placeholders: [DayCell] = (1...needed).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: lastDate) ?? lastDate
            return .placeholder(date: date)
        }
        return real + placeholders
    }

    private var compactForecast: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(paddedForecasts) { cell in
                    dayColumn(cell)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .background(.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func dayColumn(_ cell: DayCell) -> some View {
        let isPlaceholder = cell.forecast == nil
        VStack(spacing: 3) {
            Text(cell.dayAbbrev)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isPlaceholder ? .tertiary : .secondary)
            Image(systemName: cell.forecast?.symbol ?? "minus")
                .font(.system(size: 13))
                .foregroundStyle(isPlaceholder ? AnyShapeStyle(.tertiary) : AnyShapeStyle(cell.forecast!.symbolColor))
                .frame(height: 16)
            Text(cell.forecast.map { "\(Int($0.highF))°" } ?? "—")
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundStyle(isPlaceholder ? .tertiary : .primary)
            Text(cell.forecast.map { "\(Int($0.lowF))°" } ?? " ")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.tertiary)
            HStack(spacing: 1) {
                if let f = cell.forecast, f.precipitationProbability > 20 {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.cyan)
                    Text("\(f.precipitationProbability)%")
                        .font(.system(size: 7).monospacedDigit())
                        .foregroundStyle(.cyan)
                } else {
                    Text(" ")
                        .font(.system(size: 7).monospacedDigit())
                }
            }
            .frame(height: 10)
        }
        .frame(width: 38)
        .opacity(cell.isFaded ? 0.45 : 1.0)
    }

    private func fetchWeather() {
        guard let dest = trip.destination else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let cal = Calendar.current
                let startDate = cal.startOfDay(for: trip.departureDate)
                let baseEnd = trip.returnDate ?? cal.date(byAdding: .day, value: 6, to: startDate) ?? startDate
                let tripDayCount = (cal.dateComponents([.day], from: startDate, to: baseEnd).day ?? 0) + 1
                let extra = max(0, 7 - tripDayCount)
                let endDate = cal.date(byAdding: .day, value: extra, to: baseEnd) ?? baseEnd
                
                let result = try await WeatherService.shared.fetchForecast(
                    latitude: dest.latitude,
                    longitude: dest.longitude,
                    startDate: startDate,
                    endDate: endDate,
                    config: store.localConfig
                )
                let aq = try? await WeatherService.shared.fetchAirQuality(
                    latitude: dest.latitude,
                    longitude: dest.longitude
                )
                let tides = try? await WeatherService.shared.fetchTides(
                    latitude: dest.latitude,
                    longitude: dest.longitude,
                    startDate: startDate,
                    endDate: endDate
                )
                await MainActor.run {
                    forecasts = result.daily
                    hourlyForecasts = result.hourly
                    airQuality = aq
                    tideEvents = tides ?? []
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

// MARK: - Tide Chart Component

struct TideChart: View {
    let events: [TideEvent]
    let dayMarkers: [Date]
    var axis: Axis = .horizontal
    @Binding var hoverDate: Date?
    let timezoneIdentifier: String
    
    @State private var internalHoverPoint: CGPoint?
    
    private var cal: Calendar {
        var c = Calendar.current
        c.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
        return c
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawChart(in: context, size: size)
                }
                
                if let info = currentHoverInfo(size: size) {
                    Circle()
                        .fill(Color.packitTeal)
                        .frame(width: 6, height: 6)
                        .position(info.point)
                        .shadow(radius: 2)
                    
                    TideTooltip(date: info.date, heightFeet: info.heightMeters * 3.28084, timezoneIdentifier: timezoneIdentifier)
                        .position(x: min(size.width - 40, max(40, info.point.x)), y: min(size.height - 20, max(20, info.point.y - 30)))
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let p):
                    internalHoverPoint = p
                    if let info = hoverInfo(at: p, size: size) {
                        hoverDate = info.date
                    }
                case .ended:
                    internalHoverPoint = nil
                    hoverDate = nil
                }
            }
        }
    }

    private func currentHoverInfo(size: CGSize) -> (date: Date, heightMeters: Double, point: CGPoint)? {
        if let p = internalHoverPoint {
            return hoverInfo(at: p, size: size)
        }
        return nil
    }

    private func drawChart(in context: GraphicsContext, size: CGSize) {
        guard events.count >= 2, let firstDay = dayMarkers.first else { return }
        let minTime = firstDay.timeIntervalSinceReferenceDate
        let maxTime = cal.date(byAdding: .day, value: 1, to: dayMarkers.last!)!.timeIntervalSinceReferenceDate
        let timeRange = maxTime - minTime
        let minHeight = events.map(\.heightMeters).min() ?? 0
        let maxHeight = events.map(\.heightMeters).max() ?? 1
        let heightRange = maxHeight - minHeight
        
        func point(for date: Date, height: Double) -> CGPoint {
            let t = timeRange == 0 ? 0.5 : CGFloat((date.timeIntervalSinceReferenceDate - minTime) / timeRange)
            let h = heightRange == 0 ? 0.5 : CGFloat((height - minHeight) / heightRange)
            return CGPoint(x: t * size.width, y: size.height - (h * size.height))
        }

        for (idx, dayStart) in dayMarkers.enumerated() {
            let pStart = point(for: dayStart, height: minHeight)
            let nextDay = cal.date(byAdding: .day, value: 1, to: dayStart)!
            let pEnd = point(for: nextDay, height: minHeight)
            if idx.isMultiple(of: 2) {
                context.fill(Path(CGRect(x: pStart.x, y: 0, width: pEnd.x - pStart.x, height: size.height)), with: .color(.secondary.opacity(0.04)))
            }
            var line = Path()
            line.move(to: CGPoint(x: pStart.x, y: 0))
            line.addLine(to: CGPoint(x: pStart.x, y: size.height))
            context.stroke(line, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
        }
        
        var path = Path()
        var fillPath = Path()
        let sorted = events.sorted(by: { $0.date < $1.date })
        for i in 0..<(sorted.count - 1) {
            let e1 = sorted[i]
            let e2 = sorted[i+1]
            let p1 = point(for: e1.date, height: e1.heightMeters)
            if i == 0 {
                path.move(to: p1)
                fillPath.move(to: CGPoint(x: p1.x, y: size.height))
                fillPath.addLine(to: p1)
            }
            let steps = 15
            for step in 1...steps {
                let t = Double(step) / Double(steps)
                let date = e1.date.addingTimeInterval(e2.date.timeIntervalSince(e1.date) * t)
                let sineT = 0.5 - 0.5 * cos(.pi * t)
                let height = e1.heightMeters + (e2.heightMeters - e1.heightMeters) * sineT
                let p = point(for: date, height: height)
                path.addLine(to: p)
                fillPath.addLine(to: p)
            }
        }
        let lastP = point(for: sorted.last!.date, height: sorted.last!.heightMeters)
        fillPath.addLine(to: CGPoint(x: lastP.x, y: size.height))
        fillPath.closeSubpath()
        context.fill(fillPath, with: .linearGradient(Gradient(colors: [.packitTeal.opacity(0.2), .packitTeal.opacity(0.02)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        context.stroke(path, with: .linearGradient(Gradient(colors: [.packitTeal, .packitTeal.opacity(0.7)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 1.5)
        for event in events {
            let p = point(for: event.date, height: event.heightMeters)
            context.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3)), with: .color(.packitTeal))
        }

        let now = Date()
        if now >= firstDay && now <= cal.date(byAdding: .day, value: 1, to: dayMarkers.last!)!,
           let height = TideEvent.interpolatedHeight(at: now, in: events) {
            let p = point(for: now, height: height)
            context.stroke(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(.red.opacity(0.3)), lineWidth: 1)
            context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(.red))
        }
    }
    
    private func hoverInfo(at point: CGPoint, size: CGSize) -> (date: Date, heightMeters: Double, point: CGPoint)? {
        guard events.count >= 2, let firstDay = dayMarkers.first else { return nil }
        let minTime = firstDay.timeIntervalSinceReferenceDate
        let maxTime = cal.date(byAdding: .day, value: 1, to: dayMarkers.last!)!.timeIntervalSinceReferenceDate
        let t: CGFloat = point.x / size.width
        let date = Date(timeIntervalSinceReferenceDate: minTime + Double(t) * (maxTime - minTime))
        guard let height = TideEvent.interpolatedHeight(at: date, in: events) else { return nil }
        let minHeight = events.map(\.heightMeters).min() ?? 0
        let maxHeight = events.map(\.heightMeters).max() ?? 1
        let hRatio = CGFloat((height - minHeight) / (maxHeight - minHeight))
        return (date, height, CGPoint(x: point.x, y: size.height - (hRatio * size.height)))
    }
}

private struct DayCell: Identifiable {
    let id: String
    let dayAbbrev: String
    let forecast: DailyForecast?
    let isFaded: Bool
    static func real(_ f: DailyForecast, isPostTrip: Bool) -> DayCell {
        DayCell(id: f.id.uuidString, dayAbbrev: f.dayAbbrev, forecast: f, isFaded: isPostTrip)
    }
    static func placeholder(date: Date) -> DayCell {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return DayCell(id: "ph-\(date.timeIntervalSinceReferenceDate)", dayAbbrev: fmt.string(from: date), forecast: nil, isFaded: true)
    }
}

struct WeatherDetailSheet: View {
    let trip: TripInstance
    let forecasts: [DailyForecast]
    let hourlyForecasts: [HourlyForecast]
    let airQuality: AirQuality?
    var onRefresh: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var popoverDay: DailyForecast?
    @State private var popoverMetric: HourlyWeatherView.WeatherMetric = .temperature

    private func hourlyFor(day: DailyForecast) -> [HourlyForecast] {
        let cal = Calendar.current
        return hourlyForecasts.filter { cal.isDate($0.date, inSameDayAs: day.date) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weather Forecast").font(.headline)
                    if let dest = trip.destination {
                        Text(dest.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { onRefresh() } label: {
                    Label("Refresh", systemImage: "arrow.clockwise").font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .focusable(false)
            }
            .padding()

            Divider()

            ScrollView {
                Group {
                    VStack(spacing: 0) {
                        ForEach(Array(forecasts.enumerated()), id: \.element.id) { index, day in
                            HStack(spacing: 12) {
                                // Day & Condition
                                Button {
                                    popoverMetric = .temperature
                                    popoverDay = day
                                } label: {
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
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .focusable(false)
                                .frame(width: 160, alignment: .leading)
                                .popover(item: Binding(
                                    get: { (popoverDay?.id == day.id && popoverMetric == .temperature) ? popoverDay : nil },
                                    set: { if $0 == nil { popoverDay = nil } }
                                ), arrowEdge: .top) { day in
                                    HourlyWeatherView(
                                        day: day,
                                        hourly: hourlyFor(day: day),
                                        metric: .temperature
                                    )
                                }

                                // Temperature
                                Button {
                                    popoverMetric = .temperature
                                    popoverDay = day
                                } label: {
                                    VStack(spacing: 1) {
                                        Text("\(Int(day.highF))°/\(Int(day.lowF))°")
                                            .font(.callout.weight(.semibold).monospacedDigit())
                                        Text("Feels \(Int(day.feelsLikeHighF))°/\(Int(day.feelsLikeLowF))°")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .focusable(false)
                                .frame(width: 90)
                                .popover(item: Binding(
                                    get: { (popoverDay?.id == day.id && popoverMetric == .temperature) ? popoverDay : nil },
                                    set: { if $0 == nil { popoverDay = nil } }
                                ), arrowEdge: .top) { day in
                                    HourlyWeatherView(
                                        day: day,
                                        hourly: hourlyFor(day: day),
                                        metric: .temperature
                                    )
                                }

                                // Precipitation
                                Button {
                                    popoverMetric = .precipitation
                                    popoverDay = day
                                } label: {
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
                                        } else {
                                            Text("0.00\"")
                                                .font(.caption2)
                                                .foregroundStyle(.clear)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .focusable(false)
                                .frame(width: 60)
                                .popover(item: Binding(
                                    get: { (popoverDay?.id == day.id && popoverMetric == .precipitation) ? popoverDay : nil },
                                    set: { if $0 == nil { popoverDay = nil } }
                                ), arrowEdge: .top) { day in
                                    HourlyWeatherView(
                                        day: day,
                                        hourly: hourlyFor(day: day),
                                        metric: .precipitation
                                    )
                                }

                                // Wind
                                Button {
                                    popoverMetric = .wind
                                    popoverDay = day
                                } label: {
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
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .focusable(false)
                                .frame(width: 60)
                                .popover(item: Binding(
                                    get: { (popoverDay?.id == day.id && popoverMetric == .wind) ? popoverDay : nil },
                                    set: { if $0 == nil { popoverDay = nil } }
                                ), arrowEdge: .top) { day in
                                    HourlyWeatherView(
                                        day: day,
                                        hourly: hourlyFor(day: day),
                                        metric: .wind
                                    )
                                }

                                // Humidity & UV
                                Button {
                                    popoverMetric = .humidityUV
                                    popoverDay = day
                                } label: {
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
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .focusable(false)
                                .frame(width: 60)
                                .popover(item: Binding(
                                    get: { (popoverDay?.id == day.id && popoverMetric == .humidityUV) ? popoverDay : nil },
                                    set: { if $0 == nil { popoverDay = nil } }
                                ), arrowEdge: .top) { day in
                                    HourlyWeatherView(
                                        day: day,
                                        hourly: hourlyFor(day: day),
                                        metric: .humidityUV
                                    )
                                }

                                // Pressure & Dew Point
                                Button {
                                    popoverMetric = .dewPointPressure
                                    popoverDay = day
                                } label: {
                                    VStack(spacing: 1) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "barometer")
                                                .font(.caption2)
                                            Text("\(Int(day.pressureHpa))")
                                                .font(.caption.monospacedDigit())
                                        }
                                        Text("dew \(Int(day.dewPointF))°")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .focusable(false)
                                .frame(width: 60)
                                .popover(item: Binding(
                                    get: { (popoverDay?.id == day.id && popoverMetric == .dewPointPressure) ? popoverDay : nil },
                                    set: { if $0 == nil { popoverDay = nil } }
                                ), arrowEdge: .top) { day in
                                    HourlyWeatherView(
                                        day: day,
                                        hourly: hourlyFor(day: day),
                                        metric: .dewPointPressure
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.04) : .clear)
                        }
                    }
                }
                .focusEffectDisabled()
            }

            if let aq = airQuality {
                Divider()
                HStack(spacing: 12) {
                    Circle().fill(aq.color).frame(width: 10, height: 10)
                    Text("Air Quality: \(aq.level) (AQI \(aq.aqi))").font(.caption)
                    Spacer()
                    Text("PM2.5: \(String(format: "%.1f", aq.pm25)) · PM10: \(String(format: "%.1f", aq.pm10))").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            HStack {
                Text("Powered by Open-Meteo")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .focusable(false)
            }
            .padding()
        }
        .frame(width: 720, height: 480)
    }
}

struct TideDetailView: View {
    let events: [TideEvent]
    let uniqueDays: [Date]
    @State private var hoverDate: Date?
    @State private var scrolledDay: Date?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Tide Details", systemImage: "waveform.path.ecg").font(.headline)
                Spacer()
                Text(uniqueDays.count > 1 ? "\(uniqueDays.count) Day Forecast" : "1 Day Forecast").font(.caption).foregroundStyle(.secondary)
            }
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        TideChart(events: events, dayMarkers: uniqueDays, hoverDate: $hoverDate, timezoneIdentifier: events.first?.timezoneIdentifier ?? "UTC").frame(width: max(400, CGFloat(uniqueDays.count) * 200), height: 160)
                        HStack(spacing: 0) {
                            ForEach(uniqueDays, id: \.self) { day in
                                Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).frame(width: 200, alignment: .leading).padding(.leading, 4).id(day)
                            }
                        }
                    }.padding()
                }.background(.secondary.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: hoverDate) { _, newValue in
                    if let date = newValue { scrolledDay = Calendar.current.startOfDay(for: date) }
                }
            }
            ScrollViewReader { listProxy in
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(uniqueDays, id: \.self) { day in
                            Section {
                                let dayEvents = events.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.sorted(by: { $0.date < $1.date })
                                VStack(spacing: 0) {
                                    ForEach(dayEvents) { event in
                                        let isProximate = hoverDate != nil && abs(event.date.timeIntervalSince(hoverDate!)) < 1800
                                        HStack(spacing: 16) {
                                            Image(systemName: event.type == .high ? "arrow.up.circle.fill" : "arrow.down.circle.fill").foregroundStyle(event.type == .high ? .packitTeal : .secondary).font(isProximate ? .title : .title2).frame(width: 30).shadow(color: .packitTeal.opacity(isProximate ? 0.6 : 0), radius: 4)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(event.type.rawValue + " Tide").font(isProximate ? .headline : .subheadline.weight(.semibold))
                                                Text(event.timeLabel).font(isProximate ? .subheadline : .caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(String(format: "%.2f ft", event.heightFeet)).font(isProximate ? .title2.monospacedDigit() : .title3.monospacedDigit()).foregroundStyle(isProximate ? .packitTeal : .primary)
                                        }.padding(.vertical, isProximate ? 14 : 10).padding(.horizontal, 12).background(isProximate ? Color.packitTeal.opacity(0.1) : Color.clear).clipShape(RoundedRectangle(cornerRadius: 8)).animation(.spring(response: 0.3), value: isProximate)
                                        if event.id != dayEvents.last?.id { Divider().padding(.leading, 50) }
                                    }
                                }.background(.background.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 8))
                            } header: {
                                HStack {
                                    Text(day.formatted(.dateTime.weekday(.wide).month(.wide).day())).font(.caption.bold()).foregroundStyle(.secondary).textCase(.uppercase)
                                    Spacer()
                                }.padding(.top, 16).padding(.bottom, 8).padding(.horizontal, 4).id("list-\(day.timeIntervalSinceReferenceDate)")
                            }
                        }
                    }.padding(.horizontal)
                }.onChange(of: scrolledDay) { _, newValue in
                    if let day = newValue { withAnimation { listProxy.scrollTo("list-\(day.timeIntervalSinceReferenceDate)", anchor: .top) } }
                }
            }
        }.padding().frame(width: 550, height: 650)
    }
}
