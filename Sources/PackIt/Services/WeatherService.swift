import Foundation
import SwiftUI

struct DailyForecast: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let highF: Double
    let lowF: Double
    let feelsLikeHighF: Double
    let feelsLikeLowF: Double
    let weatherCode: Int
    let precipitationInches: Double
    let precipitationProbability: Int
    let windSpeedMph: Double
    let windGustMph: Double
    let humidity: Int
    let pressureHpa: Double
    let uvIndex: Double
    let isHistorical: Bool

    init(date: Date, highF: Double, lowF: Double, feelsLikeHighF: Double = 0, feelsLikeLowF: Double = 0, weatherCode: Int, precipitationInches: Double = 0, precipitationProbability: Int = 0, windSpeedMph: Double = 0, windGustMph: Double = 0, humidity: Int = 0, pressureHpa: Double = 0, uvIndex: Double = 0, isHistorical: Bool = false) {
        self.date = date
        self.highF = highF
        self.lowF = lowF
        self.feelsLikeHighF = feelsLikeHighF
        self.feelsLikeLowF = feelsLikeLowF
        self.weatherCode = weatherCode
        self.precipitationInches = precipitationInches
        self.precipitationProbability = precipitationProbability
        self.windSpeedMph = windSpeedMph
        self.windGustMph = windGustMph
        self.humidity = humidity
        self.pressureHpa = pressureHpa
        self.uvIndex = uvIndex
        self.isHistorical = isHistorical
    }

    var condition: String { WeatherCode.description(for: weatherCode) }
    var symbol: String { WeatherCode.sfSymbol(for: weatherCode) }
    var symbolColor: Color { WeatherCode.color(for: weatherCode) }
    var dayAbbrev: String { date.formatted(.dateTime.weekday(.abbreviated)) }
    var dateShort: String { date.formatted(.dateTime.month(.abbreviated).day()) }
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

// MARK: - Weather Service

actor WeatherService {
    static let shared = WeatherService()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Fetch forecast using the configured provider with automatic historical fallback.
    func fetchForecast(latitude: Double, longitude: Double, startDate: Date, endDate: Date, config: LocalConfig) async throws -> [DailyForecast] {
        let daysOut = Calendar.current.dateComponents([.day], from: .now, to: startDate).day ?? 0
        let maxDays: Int = switch config.weatherProvider {
        case .openMeteo: 15
        case .weatherApi: 13
        case .visualCrossing: 14
        }

        if daysOut > maxDays {
            // Beyond forecast range — use historical data from same dates last year
            return try await fetchOpenMeteoHistorical(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate)
        }

        switch config.weatherProvider {
        case .openMeteo:
            return try await fetchOpenMeteo(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate)
        case .weatherApi:
            return try await fetchWeatherApi(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate, apiKey: config.weatherApiKey)
        case .visualCrossing:
            return try await fetchVisualCrossing(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate, apiKey: config.visualCrossingApiKey)
        }
    }

    func fetchAirQuality(latitude: Double, longitude: Double) async throws -> AirQuality? {
        let url = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(latitude)&longitude=\(longitude)&current=us_aqi,pm2_5,pm10")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AQResponse.self, from: data)
        guard let current = response.current else { return nil }
        return AirQuality(aqi: current.us_aqi ?? 0, pm25: current.pm2_5 ?? 0, pm10: current.pm10 ?? 0)
    }

    // MARK: - Open-Meteo Forecast

    private func fetchOpenMeteo(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> [DailyForecast] {
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weathercode,precipitation_sum,precipitation_probability_max,windspeed_10m_max,windgusts_10m_max,relative_humidity_2m_mean,surface_pressure_mean,uv_index_max&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto&start_date=\(start)&end_date=\(end)"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlStr)!)
        let r = try JSONDecoder().decode(OMForecastResponse.self, from: data)
        return parseOpenMeteoDaily(r.daily)
    }

    // MARK: - Open-Meteo Historical (same dates last year)

    private func fetchOpenMeteoHistorical(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> [DailyForecast] {
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: startDate)!
        let lastYearEnd = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        let start = dateFormatter.string(from: lastYear)
        let end = dateFormatter.string(from: lastYearEnd)
        let urlStr = "https://archive-api.open-meteo.com/v1/archive?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,windspeed_10m_max,windgusts_10m_max&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto&start_date=\(start)&end_date=\(end)"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlStr)!)
        let r = try JSONDecoder().decode(OMForecastResponse.self, from: data)
        // Map dates back to this year's trip dates
        let daily = r.daily
        var forecasts: [DailyForecast] = []
        let tripStart = startDate
        for i in 0..<(daily.time?.count ?? 0) {
            let date = Calendar.current.date(byAdding: .day, value: i, to: tripStart)!
            forecasts.append(DailyForecast(
                date: date,
                highF: daily.temperature_2m_max?[i] ?? 0,
                lowF: daily.temperature_2m_min?[i] ?? 0,
                weatherCode: daily.weathercode?[i] ?? 0,
                precipitationInches: daily.precipitation_sum?[i] ?? 0,
                windSpeedMph: daily.windspeed_10m_max?[i] ?? 0,
                windGustMph: daily.windgusts_10m_max?[i] ?? 0,
                isHistorical: true
            ))
        }
        return forecasts
    }

    // MARK: - WeatherAPI.com

    private func fetchWeatherApi(latitude: Double, longitude: Double, startDate: Date, endDate: Date, apiKey: String) async throws -> [DailyForecast] {
        guard !apiKey.isEmpty else { throw WeatherError.missingApiKey }
        let days = max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
        let urlStr = "https://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(latitude),\(longitude)&days=\(min(days, 14))&aqi=no"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlStr)!)
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

    // MARK: - Visual Crossing

    private func fetchVisualCrossing(latitude: Double, longitude: Double, startDate: Date, endDate: Date, apiKey: String) async throws -> [DailyForecast] {
        guard !apiKey.isEmpty else { throw WeatherError.missingApiKey }
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        let urlStr = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(latitude),\(longitude)/\(start)/\(end)?unitGroup=us&include=days&key=\(apiKey)&contentType=json"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlStr)!)
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

    // MARK: - Helpers

    private func parseOpenMeteoDaily(_ daily: OMDaily) -> [DailyForecast] {
        var forecasts: [DailyForecast] = []
        for i in 0..<(daily.time?.count ?? 0) {
            guard let dateStr = daily.time?[i], let date = dateFormatter.date(from: dateStr) else { continue }
            forecasts.append(DailyForecast(
                date: date,
                highF: daily.temperature_2m_max?[i] ?? 0,
                lowF: daily.temperature_2m_min?[i] ?? 0,
                feelsLikeHighF: daily.apparent_temperature_max?[i] ?? 0,
                feelsLikeLowF: daily.apparent_temperature_min?[i] ?? 0,
                weatherCode: daily.weathercode?[i] ?? 0,
                precipitationInches: daily.precipitation_sum?[i] ?? 0,
                precipitationProbability: daily.precipitation_probability_max?[i] ?? 0,
                windSpeedMph: daily.windspeed_10m_max?[i] ?? 0,
                windGustMph: daily.windgusts_10m_max?[i] ?? 0,
                humidity: daily.relative_humidity_2m_mean?[i] ?? 0,
                pressureHpa: daily.surface_pressure_mean?[i] ?? 0,
                uvIndex: daily.uv_index_max?[i] ?? 0
            ))
        }
        return forecasts
    }

    private func mapWeatherApiCondition(_ code: Int) -> Int {
        // WeatherAPI condition codes → WMO weather codes (approximate)
        switch code {
        case 1000: return 0       // Clear
        case 1003: return 2       // Partly cloudy
        case 1006, 1009: return 3 // Cloudy/Overcast
        case 1030, 1135: return 45 // Fog
        case 1063, 1150, 1153: return 51 // Light drizzle/rain
        case 1180, 1183: return 61 // Light rain
        case 1186, 1189: return 63 // Moderate rain
        case 1192, 1195, 1240, 1243, 1246: return 65 // Heavy rain
        case 1066, 1210, 1213: return 71 // Light snow
        case 1216, 1219: return 73 // Moderate snow
        case 1222, 1225, 1255, 1258: return 75 // Heavy snow
        case 1273, 1276: return 95 // Thunderstorm
        case 1279, 1282: return 96 // Thunderstorm with hail
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

    var errorDescription: String? {
        switch self {
        case .missingApiKey: "API key required. Set it in Settings → Weather."
        }
    }
}

// MARK: - Open-Meteo Response Models

private struct OMForecastResponse: Decodable { let daily: OMDaily }

private struct OMDaily: Decodable {
    let time: [String]?
    let temperature_2m_max: [Double]?
    let temperature_2m_min: [Double]?
    let apparent_temperature_max: [Double]?
    let apparent_temperature_min: [Double]?
    let weathercode: [Int]?
    let precipitation_sum: [Double]?
    let precipitation_probability_max: [Int]?
    let windspeed_10m_max: [Double]?
    let windgusts_10m_max: [Double]?
    let relative_humidity_2m_mean: [Int]?
    let surface_pressure_mean: [Double]?
    let uv_index_max: [Double]?
}

private struct AQResponse: Decodable { let current: AQCurrent? }
private struct AQCurrent: Decodable { let us_aqi: Int?; let pm2_5: Double?; let pm10: Double? }

// MARK: - WeatherAPI.com Response Models

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

// MARK: - Visual Crossing Response Models

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

// MARK: - WMO Weather Codes

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
