import Foundation
import PackItKit
import SwiftUI

struct DailyForecast: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let highF: Double
    let lowF: Double
    let currentTempF: Double?
    let feelsLikeHighF: Double
    let feelsLikeLowF: Double
    let weatherCode: Int
    let currentCode: Int?
    let precipitationInches: Double
    let precipitationProbability: Int
    let windSpeedMph: Double
    let windGustMph: Double
    let humidity: Int
    let pressureHpa: Double
    let uvIndex: Double
    let sunrise: Date?
    let sunset: Date?
    let dewPointF: Double
    let isHistorical: Bool

    init(date: Date, highF: Double, lowF: Double, currentTempF: Double? = nil, feelsLikeHighF: Double = 0, feelsLikeLowF: Double = 0, weatherCode: Int, currentCode: Int? = nil, precipitationInches: Double = 0, precipitationProbability: Int = 0, windSpeedMph: Double = 0, windGustMph: Double = 0, humidity: Int = 0, pressureHpa: Double = 0, uvIndex: Double = 0, sunrise: Date? = nil, sunset: Date? = nil, dewPointF: Double = 0, isHistorical: Bool = false) {
        self.date = date
        self.highF = highF
        self.lowF = lowF
        self.currentTempF = currentTempF
        self.feelsLikeHighF = feelsLikeHighF
        self.feelsLikeLowF = feelsLikeLowF
        self.weatherCode = weatherCode
        self.currentCode = currentCode
        self.precipitationInches = precipitationInches
        self.precipitationProbability = precipitationProbability
        self.windSpeedMph = windSpeedMph
        self.windGustMph = windGustMph
        self.humidity = humidity
        self.pressureHpa = pressureHpa
        self.uvIndex = uvIndex
        self.sunrise = sunrise
        self.sunset = sunset
        self.dewPointF = dewPointF
        self.isHistorical = isHistorical
    }

    var condition: String { WeatherCode.description(for: weatherCode) }
    var symbol: String { WeatherCode.sfSymbol(for: weatherCode) }
    var symbolColor: Color { WeatherCode.color(for: weatherCode) }
    var dayAbbrev: String { date.formatted(.dateTime.weekday(.abbreviated)) }
    var dateShort: String { date.formatted(.dateTime.month(.abbreviated).day()) }

    var isLikelyWet: Bool {
        precipitationProbability >= 50 || precipitationInches >= 0.05
    }

    var isWindy: Bool { windSpeedMph >= 12 || windGustMph >= 20 }
    var isFrosty: Bool { lowF <= 32 }
    var isHighUV: Bool { uvIndex >= 8 }
}

struct HourlyForecast: Identifiable, Sendable, Hashable {
    let id: UUID
    let date: Date
    let tempF: Double
    let weatherCode: Int
    let precipitationProbability: Int
    let precipitationInches: Double
    let windSpeedMph: Double
    let windGustMph: Double
    let humidity: Int
    let uvIndex: Double
    let feelsLikeF: Double
    let dewPointF: Double
    let pressureHpa: Double

    init(id: UUID = UUID(), date: Date, tempF: Double, weatherCode: Int, precipitationProbability: Int,
         precipitationInches: Double, windSpeedMph: Double, windGustMph: Double,
         humidity: Int, uvIndex: Double, feelsLikeF: Double, dewPointF: Double, pressureHpa: Double) {
        self.id = id
        self.date = date
        self.tempF = tempF
        self.weatherCode = weatherCode
        self.precipitationProbability = precipitationProbability
        self.precipitationInches = precipitationInches
        self.windSpeedMph = windSpeedMph
        self.windGustMph = windGustMph
        self.humidity = humidity
        self.uvIndex = uvIndex
        self.feelsLikeF = feelsLikeF
        self.dewPointF = dewPointF
        self.pressureHpa = pressureHpa
    }

    var symbol: String { WeatherCode.sfSymbol(for: weatherCode) }
    var symbolColor: Color { WeatherCode.color(for: weatherCode) }
}

struct ForecastResult: Sendable {
    let daily: [DailyForecast]
    let hourly: [HourlyForecast]

    static let empty = ForecastResult(daily: [], hourly: [])
}

struct AirQuality: Sendable {
    let aqi: Int
    let pm25: Double
    let pm10: Double

    var level: String {
        switch aqi {
        case 0...50: "Good"
        case 51...100: "Moderate"
        case 101...150: "Unhealthy (Sensitive)"
        case 151...200: "Unhealthy"
        case 201...300: "Very Unhealthy"
        default: "Hazardous"
        }
    }

    var color: Color {
        switch aqi {
        case 0...50: .green
        case 51...100: .yellow
        case 101...150: .orange
        case 151...200: .red
        case 201...300: .purple
        default: .brown
        }
    }
}

struct TideEvent: Identifiable, Sendable, Hashable {
    enum TideType: String, Sendable {
        case high = "High"
        case low = "Low"
    }

    let id: UUID
    let date: Date
    let type: TideType
    let heightMeters: Double
    let timezoneIdentifier: String

    init(id: UUID = UUID(), date: Date, type: TideType, heightMeters: Double, timezoneIdentifier: String = "UTC") {
        self.id = id
        self.date = date
        self.type = type
        self.heightMeters = heightMeters
        self.timezoneIdentifier = timezoneIdentifier
    }

    var timeLabel: String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
        return date.formatted(style)
    }
    var heightFeet: Double { heightMeters * 3.28084 }

    static func processExtrema(points: [(date: Date, heightMeters: Double)], timezoneIdentifier: String = "UTC") -> [TideEvent] {
        guard points.count >= 3 else { return [] }
        var events: [TideEvent] = []
        for i in 1..<(points.count - 1) {
            let prev = points[i - 1].heightMeters
            let curr = points[i].heightMeters
            let next = points[i + 1].heightMeters
            let date = points[i].date
            
            if curr > prev && curr > next {
                events.append(TideEvent(date: date, type: .high, heightMeters: curr, timezoneIdentifier: timezoneIdentifier))
            } else if curr < prev && curr < next {
                events.append(TideEvent(date: date, type: .low, heightMeters: curr, timezoneIdentifier: timezoneIdentifier))
            }
        }
        return events
    }
}

// MARK: - Weather Service

actor WeatherService {
    static let shared = WeatherService()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func data(from urlString: String) async throws -> Data {
        guard var components = URLComponents(string: urlString) else { throw URLError(.badURL) }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "_t", value: "\(Date().timeIntervalSince1970)"))
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    func fetchForecast(latitude: Double, longitude: Double, startDate: Date, endDate: Date, config: LocalConfig) async throws -> ForecastResult {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let reqStart = cal.startOfDay(for: startDate)
        let reqEnd = cal.startOfDay(for: endDate)
        let maxDays: Int = switch config.weatherProvider {
        case .openMeteo: 15
        case .weatherApi: 13
        case .visualCrossing: 14
        }
        let maxLiveDate = cal.date(byAdding: .day, value: maxDays, to: today)!

        // Case A: Entire trip is in the past (endDate < today)
        if reqEnd < today {
            let histDaily = try await fetchOpenMeteoHistoricalExact(latitude: latitude, longitude: longitude, startDate: reqStart, endDate: reqEnd)
            return ForecastResult(daily: histDaily, hourly: [])
        }

        // Case B: Entire trip is in far future (startDate > maxLiveDate)
        if reqStart > maxLiveDate {
            let histDaily = try await fetchOpenMeteoHistorical(latitude: latitude, longitude: longitude, startDate: reqStart, endDate: reqEnd)
            return ForecastResult(daily: histDaily, hourly: [])
        }

        // Case C: Overlapping date ranges (past / live / future)
        let liveStart = max(reqStart, today)
        let liveEnd = min(reqEnd, maxLiveDate)

        var pastDaily: [DailyForecast] = []
        if reqStart < today {
            let pastEnd = cal.date(byAdding: .day, value: -1, to: today)!
            pastDaily = (try? await fetchOpenMeteoHistoricalExact(latitude: latitude, longitude: longitude, startDate: reqStart, endDate: pastEnd)) ?? []
        }

        var liveResult = ForecastResult(daily: [], hourly: [])
        if liveStart <= liveEnd {
            liveResult = (try? await fetchForecastInRange(latitude: latitude, longitude: longitude, startDate: liveStart, endDate: liveEnd, config: config)) ?? ForecastResult(daily: [], hourly: [])
        }

        var futureDaily: [DailyForecast] = []
        if reqEnd > maxLiveDate {
            let futureStart = cal.date(byAdding: .day, value: 1, to: maxLiveDate)!
            futureDaily = (try? await fetchOpenMeteoHistorical(latitude: latitude, longitude: longitude, startDate: futureStart, endDate: reqEnd)) ?? []
        }

        let combinedDaily = pastDaily + liveResult.daily + futureDaily

        if combinedDaily.isEmpty {
            let fallback = fallbackHistorical(startDate: reqStart, endDate: reqEnd)
            return ForecastResult(daily: fallback, hourly: [])
        }

        return ForecastResult(daily: combinedDaily, hourly: liveResult.hourly)
    }

    private func fetchForecastInRange(latitude: Double, longitude: Double, startDate: Date, endDate: Date, config: LocalConfig) async throws -> ForecastResult {
        switch config.weatherProvider {
        case .openMeteo:
            return try await fetchOpenMeteo(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate)
        case .weatherApi:
            let daily = try await fetchWeatherApi(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate, apiKey: config.weatherApiKey)
            return ForecastResult(daily: daily, hourly: [])
        case .visualCrossing:
            let daily = try await fetchVisualCrossing(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate, apiKey: config.visualCrossingApiKey)
            return ForecastResult(daily: daily, hourly: [])
        }
    }

    func fetchAirQuality(latitude: Double, longitude: Double) async throws -> AirQuality? {
        let url = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(latitude)&longitude=\(longitude)&current=us_aqi,pm2_5,pm10")!
        let data = try await data(from: url.absoluteString)
        let response = try JSONDecoder().decode(AQResponse.self, from: data)
        guard let current = response.current else { return nil }
        return AirQuality(aqi: current.us_aqi ?? 0, pm25: current.pm2_5 ?? 0, pm10: current.pm10 ?? 0)
    }

    func fetchTides(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> [TideEvent] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let fetchStart = Calendar.current.date(byAdding: .day, value: -1, to: startDate)!
        let fetchEnd = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
        let start = df.string(from: fetchStart)
        let end = df.string(from: fetchEnd)
        
        let urlStr = "https://marine-api.open-meteo.com/v1/marine?latitude=\(latitude)&longitude=\(longitude)&hourly=sea_level_height_msl&timezone=auto&start_date=\(start)&end_date=\(end)"
        let data = try await data(from: urlStr)
        let response = try JSONDecoder().decode(TideResponse.self, from: data)
        
        guard let times = response.hourly?.time,
              let heights = response.hourly?.sea_level_height_msl else { return [] }
        
        let timezoneID = response.timezone ?? "UTC"
        let tz = TimeZone(identifier: timezoneID) ?? .current
        
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoFormatter.timeZone = tz
        
        var points: [(date: Date, heightMeters: Double)] = []
        for i in 0..<times.count {
            guard i < heights.count, let h = heights[i], let date = isoFormatter.date(from: times[i]) else { continue }
            points.append((date: date, heightMeters: h))
        }
        
        return TideEvent.processExtrema(points: points, timezoneIdentifier: timezoneID)
    }

    private func fetchOpenMeteo(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> ForecastResult {
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weathercode,precipitation_sum,precipitation_probability_max,windspeed_10m_max,windgusts_10m_max,relative_humidity_2m_mean,surface_pressure_mean,uv_index_max,sunrise,sunset,dew_point_2m_max&hourly=temperature_2m,apparent_temperature,dew_point_2m,surface_pressure,weathercode,precipitation,precipitation_probability,windspeed_10m,windgusts_10m,relative_humidity_2m,uv_index&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto&start_date=\(start)&end_date=\(end)"
        let data = try await data(from: urlStr)
        let r = try JSONDecoder().decode(OMForecastResponse.self, from: data)
        if r.error == true {
            throw WeatherError.apiError(r.reason ?? "Weather service error")
        }
        guard let dailyResponse = r.daily else {
            throw WeatherError.apiError("Forecast data unavailable")
        }
        let daily = parseOpenMeteoDaily(dailyResponse, current: r.current, timezone: r.timezone)
        if daily.isEmpty {
            let histDaily = try await fetchOpenMeteoHistorical(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate)
            return ForecastResult(daily: histDaily, hourly: [])
        }
        let hourly = parseOpenMeteoHourly(r.hourly, timezone: r.timezone)
        return ForecastResult(daily: daily, hourly: hourly)
    }

    private func fetchOpenMeteoHistoricalExact(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> [DailyForecast] {
        do {
            let start = dateFormatter.string(from: startDate)
            let end = dateFormatter.string(from: endDate)
            let urlStr = "https://archive-api.open-meteo.com/v1/archive?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,windspeed_10m_max,windgusts_10m_max&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto&start_date=\(start)&end_date=\(end)"
            let data = try await data(from: urlStr)
            let r = try JSONDecoder().decode(OMForecastResponse.self, from: data)
            guard let daily = r.daily, let times = daily.time, !(daily.temperature_2m_max?.compactMap { $0 } ?? []).isEmpty else {
                return try await fetchOpenMeteoHistorical(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate)
            }
            var forecasts: [DailyForecast] = []
            let tripStart = startDate
            for i in 0..<times.count {
                let date = Calendar.current.date(byAdding: .day, value: i, to: tripStart)!
                forecasts.append(DailyForecast(
                    date: date,
                    highF: val(daily.temperature_2m_max, i) ?? 70,
                    lowF: val(daily.temperature_2m_min, i) ?? 50,
                    weatherCode: val(daily.weathercode, i) ?? 0,
                    precipitationInches: val(daily.precipitation_sum, i) ?? 0,
                    windSpeedMph: val(daily.windspeed_10m_max, i) ?? 5,
                    windGustMph: val(daily.windgusts_10m_max, i) ?? 8,
                    isHistorical: true
                ))
            }
            return forecasts
        } catch {
            return try await fetchOpenMeteoHistorical(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate)
        }
    }

    private func fetchOpenMeteoHistorical(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> [DailyForecast] {
        do {
            let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: startDate)!
            let lastYearEnd = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
            let start = dateFormatter.string(from: lastYear)
            let end = dateFormatter.string(from: lastYearEnd)
            let urlStr = "https://archive-api.open-meteo.com/v1/archive?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,windspeed_10m_max,windgusts_10m_max&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto&start_date=\(start)&end_date=\(end)"
            let data = try await data(from: urlStr)
            let r = try JSONDecoder().decode(OMForecastResponse.self, from: data)
            guard let daily = r.daily, let times = daily.time else { return fallbackHistorical(startDate: startDate, endDate: endDate) }
            var forecasts: [DailyForecast] = []
            let tripStart = startDate
            for i in 0..<times.count {
                let date = Calendar.current.date(byAdding: .day, value: i, to: tripStart)!
                forecasts.append(DailyForecast(
                    date: date,
                    highF: val(daily.temperature_2m_max, i) ?? 70,
                    lowF: val(daily.temperature_2m_min, i) ?? 50,
                    weatherCode: val(daily.weathercode, i) ?? 0,
                    precipitationInches: val(daily.precipitation_sum, i) ?? 0,
                    windSpeedMph: val(daily.windspeed_10m_max, i) ?? 5,
                    windGustMph: val(daily.windgusts_10m_max, i) ?? 8,
                    isHistorical: true
                ))
            }
            return forecasts
        } catch {
            return fallbackHistorical(startDate: startDate, endDate: endDate)
        }
    }

    private func fallbackHistorical(startDate: Date, endDate: Date) -> [DailyForecast] {
        var forecasts: [DailyForecast] = []
        let cal = Calendar.current
        let days = max(1, (cal.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
        for i in 0..<days {
            let date = cal.date(byAdding: .day, value: i, to: startDate)!
            forecasts.append(DailyForecast(
                date: date,
                highF: 72,
                lowF: 52,
                weatherCode: 1,
                precipitationInches: 0,
                windSpeedMph: 5,
                windGustMph: 10,
                isHistorical: true
            ))
        }
        return forecasts
    }

    private func fetchWeatherApi(latitude: Double, longitude: Double, startDate: Date, endDate: Date, apiKey: String) async throws -> [DailyForecast] {
        guard !apiKey.isEmpty else { throw WeatherError.missingApiKey }
        let days = max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
        let urlStr = "https://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(latitude),\(longitude)&days=\(min(days, 14))&aqi=no"
        let data = try await data(from: urlStr)
        let r = try JSONDecoder().decode(WAResponse.self, from: data)
        return r.forecast.forecastday.compactMap { day in
            guard let date = dateFormatter.date(from: day.date) else { return nil }
            return DailyForecast(
                date: date,
                highF: day.day.maxtemp_f,
                lowF: day.day.mintemp_f,
                feelsLikeHighF: day.day.maxtemp_f,
                feelsLikeLowF: day.day.mintemp_f,
                weatherCode: mapWeatherApiCondition(day.day.condition.code),
                precipitationInches: day.day.totalprecip_in,
                precipitationProbability: day.day.daily_chance_of_rain,
                windSpeedMph: day.day.maxwind_mph,
                windGustMph: day.day.maxwind_mph,
                humidity: day.day.avghumidity,
                uvIndex: day.day.uv
            )
        }
    }

    private func fetchVisualCrossing(latitude: Double, longitude: Double, startDate: Date, endDate: Date, apiKey: String) async throws -> [DailyForecast] {
        guard !apiKey.isEmpty else { throw WeatherError.missingApiKey }
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        let urlStr = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(latitude),\(longitude)/\(start)/\(end)?unitGroup=us&include=days&key=\(apiKey)&contentType=json"
        let data = try await data(from: urlStr)
        let r = try JSONDecoder().decode(VCResponse.self, from: data)
        return r.days.compactMap { day in
            guard let date = dateFormatter.date(from: day.datetime) else { return nil }
            return DailyForecast(
                date: date,
                highF: day.tempmax,
                lowF: day.tempmin,
                feelsLikeHighF: day.feelslikemax,
                feelsLikeLowF: day.feelslikemin,
                weatherCode: mapVCIcon(day.icon),
                precipitationInches: day.precip,
                precipitationProbability: Int(day.precipprob),
                windSpeedMph: day.windspeed,
                windGustMph: day.windgust ?? day.windspeed,
                humidity: Int(day.humidity),
                pressureHpa: day.pressure,
                uvIndex: day.uvindex
            )
        }
    }

    private func val<T>(_ array: [T?]?, _ index: Int) -> T? {
        guard let array, index >= 0, index < array.count else { return nil }
        return array[index]
    }

    private func parseOpenMeteoDaily(_ daily: OMDaily, current: OMCurrent? = nil, timezone: String? = nil) -> [DailyForecast] {
        let validTemps = daily.temperature_2m_max?.compactMap { $0 } ?? []
        if validTemps.isEmpty {
            return []
        }
        var forecasts: [DailyForecast] = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let tz = timezone.flatMap { TimeZone(identifier: $0) } ?? .current
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoFormatter.timeZone = tz
        
        for i in 0..<(daily.time?.count ?? 0) {
            guard let dateStr = daily.time?[i], let date = dateFormatter.date(from: dateStr) else { continue }
            
            let isToday = cal.startOfDay(for: date) == today
            let sunriseDate = val(daily.sunrise, i).flatMap { isoFormatter.date(from: $0) }
            let sunsetDate = val(daily.sunset, i).flatMap { isoFormatter.date(from: $0) }
            
            forecasts.append(DailyForecast(
                date: date,
                highF: val(daily.temperature_2m_max, i) ?? 0,
                lowF: val(daily.temperature_2m_min, i) ?? 0,
                currentTempF: isToday ? current?.temperature_2m : nil,
                feelsLikeHighF: val(daily.apparent_temperature_max, i) ?? 0,
                feelsLikeLowF: val(daily.apparent_temperature_min, i) ?? 0,
                weatherCode: val(daily.weathercode, i) ?? 0,
                currentCode: isToday ? current?.weather_code : nil,
                precipitationInches: val(daily.precipitation_sum, i) ?? 0,
                precipitationProbability: val(daily.precipitation_probability_max, i) ?? 0,
                windSpeedMph: val(daily.windspeed_10m_max, i) ?? 0,
                windGustMph: val(daily.windgusts_10m_max, i) ?? 0,
                humidity: val(daily.relative_humidity_2m_mean, i) ?? 0,
                pressureHpa: val(daily.surface_pressure_mean, i) ?? 0,
                uvIndex: val(daily.uv_index_max, i) ?? 0,
                sunrise: sunriseDate,
                sunset: sunsetDate,
                dewPointF: val(daily.dew_point_2m_max, i) ?? 0
            ))
        }
        return forecasts
    }

    private func parseOpenMeteoHourly(_ hourly: OMHourly?, timezone: String? = nil) -> [HourlyForecast] {
        guard let hourly else { return [] }
        let tz = timezone.flatMap { TimeZone(identifier: $0) } ?? .current
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoFormatter.timeZone = tz
        
        var forecasts: [HourlyForecast] = []
        for i in 0..<(hourly.time?.count ?? 0) {
            guard let dateStr = hourly.time?[i], let date = isoFormatter.date(from: dateStr) else { continue }
            forecasts.append(HourlyForecast(
                date: date,
                tempF: val(hourly.temperature_2m, i) ?? 0,
                weatherCode: val(hourly.weathercode, i) ?? 0,
                precipitationProbability: val(hourly.precipitation_probability, i) ?? 0,
                precipitationInches: val(hourly.precipitation, i) ?? 0,
                windSpeedMph: val(hourly.windspeed_10m, i) ?? 0,
                windGustMph: val(hourly.windgusts_10m, i) ?? 0,
                humidity: val(hourly.relative_humidity_2m, i) ?? 0,
                uvIndex: val(hourly.uv_index, i) ?? 0,
                feelsLikeF: val(hourly.apparent_temperature, i) ?? 0,
                dewPointF: val(hourly.dew_point_2m, i) ?? 0,
                pressureHpa: val(hourly.surface_pressure, i) ?? 0
            ))
        }
        return forecasts
    }

    private func mapWeatherApiCondition(_ code: Int) -> Int {
        switch code {
        case 1000: return 0
        case 1003: return 2
        case 1006, 1009: return 3
        case 1030, 1135: return 45
        case 1063, 1150, 1153: return 51
        case 1180, 1183: return 61
        case 1186, 1189: return 63
        case 1192, 1195, 1240, 1243, 1246: return 65
        case 1066, 1210, 1213: return 71
        case 1216, 1219: return 73
        case 1222, 1225, 1255, 1258: return 75
        case 1273, 1276: return 95
        case 1279, 1282: return 96
        default: return 2
        }
    }

    private func mapVCIcon(_ icon: String) -> Int {
        switch icon {
        case "clear-day", "clear-night": return 0
        case "partly-cloudy-day", "partly-cloudy-night": return 2
        case "cloudy": return 3
        case "fog": return 45
        case "rain": return 63
        case "showers-day", "showers-night": return 80
        case "snow", "snow-showers-day", "snow-showers-night": return 73
        case "thunder-rain", "thunder-showers-day", "thunder-showers-night": return 95
        case "wind": return 2
        default: return 2
        }
    }
}

enum WeatherError: Error, LocalizedError {
    case missingApiKey
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey: "API key required. Set it in Settings → Weather."
        case .apiError(let msg): msg
        }
    }
}

private struct OMForecastResponse: Decodable { 
    let current: OMCurrent?
    let daily: OMDaily?
    let hourly: OMHourly?
    let timezone: String?
    let error: Bool?
    let reason: String?
}

private struct OMCurrent: Decodable {
    let temperature_2m: Double?
    let weather_code: Int?
}

private struct OMDaily: Decodable {
    let time: [String]?
    let temperature_2m_max: [Double?]?
    let temperature_2m_min: [Double?]?
    let apparent_temperature_max: [Double?]?
    let apparent_temperature_min: [Double?]?
    let weathercode: [Int?]?
    let precipitation_sum: [Double?]?
    let precipitation_probability_max: [Int?]?
    let windspeed_10m_max: [Double?]?
    let windgusts_10m_max: [Double?]?
    let relative_humidity_2m_mean: [Int?]?
    let surface_pressure_mean: [Double?]?
    let uv_index_max: [Double?]?
    let sunrise: [String?]?
    let sunset: [String?]?
    let dew_point_2m_max: [Double?]?
}

private struct OMHourly: Decodable {
    let time: [String]?
    let temperature_2m: [Double?]?
    let weathercode: [Int?]?
    let precipitation: [Double?]?
    let precipitation_probability: [Int?]?
    let windspeed_10m: [Double?]?
    let windgusts_10m: [Double?]?
    let relative_humidity_2m: [Int?]?
    let uv_index: [Double?]?
    let apparent_temperature: [Double?]?
    let dew_point_2m: [Double?]?
    let surface_pressure: [Double?]?
}

private struct AQResponse: Decodable { let current: AQCurrent? }
private struct AQCurrent: Decodable { let us_aqi: Int?; let pm2_5: Double?; let pm10: Double? }

private struct TideResponse: Decodable {
    let timezone: String?
    let hourly: TideData?
}
private struct TideData: Decodable {
    let time: [String]?
    let sea_level_height_msl: [Double?]?
}

private struct WAResponse: Decodable { let forecast: WAForecast }
private struct WAForecast: Decodable { let forecastday: [WADay] }
private struct WADay: Decodable { let date: String; let day: WADayData }
private struct WADayData: Decodable {
    let maxtemp_f: Double; let mintemp_f: Double
    let totalprecip_in: Double; let daily_chance_of_rain: Int
    let maxwind_mph: Double; let avghumidity: Int; let uv: Double
    let condition: WACondition
}
private struct WACondition: Decodable { let code: Int }

private struct VCResponse: Decodable { let days: [VCDay] }
private struct VCDay: Decodable {
    let datetime: String
    let tempmax: Double; let tempmin: Double
    let feelslikemax: Double; let feelslikemin: Double
    let precip: Double; let precipprob: Double
    let windspeed: Double; let windgust: Double?
    let humidity: Double; let pressure: Double
    let uvindex: Double; let icon: String
}

enum WeatherCode {
    static func sfSymbol(for code: Int) -> String {
        switch code {
        case 0: "sun.max.fill"
        case 1: "sun.min.fill"
        case 2: "cloud.sun.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51, 53, 55: "cloud.drizzle.fill"
        case 56, 57: "cloud.sleet.fill"
        case 61, 63, 65: "cloud.rain.fill"
        case 66, 67: "cloud.sleet.fill"
        case 71, 73, 75: "cloud.snow.fill"
        case 77: "snowflake"
        case 80, 81, 82: "cloud.heavyrain.fill"
        case 85, 86: "cloud.snow.fill"
        case 95: "cloud.bolt.fill"
        case 96, 99: "cloud.bolt.rain.fill"
        default: "questionmark.circle"
        }
    }
    static func description(for code: Int) -> String {
        switch code {
        case 0: "Clear sky"
        case 1: "Mainly clear"
        case 2: "Partly cloudy"
        case 3: "Overcast"
        case 45: "Fog"
        case 48: "Depositing rime fog"
        case 51: "Light drizzle"
        case 53: "Moderate drizzle"
        case 55: "Dense drizzle"
        case 56: "Light freezing drizzle"
        case 57: "Dense freezing drizzle"
        case 61: "Slight rain"
        case 63: "Moderate rain"
        case 65: "Heavy rain"
        case 66: "Light freezing rain"
        case 67: "Heavy freezing rain"
        case 71: "Slight snow"
        case 73: "Moderate snow"
        case 75: "Heavy snow"
        case 77: "Snow grains"
        case 80: "Slight showers"
        case 81: "Moderate showers"
        case 82: "Violent showers"
        case 85: "Slight snow showers"
        case 86: "Heavy snow showers"
        case 95: "Thunderstorm"
        case 96: "Thunderstorm with slight hail"
        case 99: "Thunderstorm with heavy hail"
        default: "Unknown"
        }
    }
    static func color(for code: Int) -> Color {
        switch code {
        case 0, 1: .yellow
        case 2, 3: .gray
        case 45, 48: .secondary
        case 51...57: .cyan
        case 61...67: .blue
        case 71...77, 85, 86: .white
        case 80...82: .blue
        case 95...99: .purple
        default: .secondary
        }
    }
}
