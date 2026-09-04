import Foundation

struct ForecastResponseDTO: Decodable, Sendable {
    let timezone: String?
    let daily: ForecastDailyDTO?
    let dailyUnits: ForecastDailyUnitsDTO?

    enum CodingKeys: String, CodingKey {
        case timezone
        case daily
        case dailyUnits = "daily_units"
    }
}

struct ForecastDailyDTO: Decodable, Sendable {
    let time: [String?]?
    let weatherCode: [Int?]?
    let temperature2mMax: [Double?]?
    let temperature2mMin: [Double?]?
    let apparentTemperatureMax: [Double?]?
    let precipitationSum: [Double?]?
    let rainSum: [Double?]?
    let snowfallSum: [Double?]?
    let precipitationHours: [Double?]?
    let windSpeed10mMax: [Double?]?
    let windGusts10mMax: [Double?]?
    let sunshineDuration: [Double?]?
    let daylightDuration: [Double?]?
    let uvIndexMax: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case apparentTemperatureMax = "apparent_temperature_max"
        case precipitationSum = "precipitation_sum"
        case rainSum = "rain_sum"
        case snowfallSum = "snowfall_sum"
        case precipitationHours = "precipitation_hours"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
        case sunshineDuration = "sunshine_duration"
        case daylightDuration = "daylight_duration"
        case uvIndexMax = "uv_index_max"
    }
}

struct ForecastDailyUnitsDTO: Decodable, Sendable {
    let time: String?
    let weatherCode: String?
    let temperature2mMax: String?
    let temperature2mMin: String?
    let apparentTemperatureMax: String?
    let precipitationSum: String?
    let rainSum: String?
    let snowfallSum: String?
    let precipitationHours: String?
    let windSpeed10mMax: String?
    let windGusts10mMax: String?
    let sunshineDuration: String?
    let daylightDuration: String?
    let uvIndexMax: String?

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case apparentTemperatureMax = "apparent_temperature_max"
        case precipitationSum = "precipitation_sum"
        case rainSum = "rain_sum"
        case snowfallSum = "snowfall_sum"
        case precipitationHours = "precipitation_hours"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
        case sunshineDuration = "sunshine_duration"
        case daylightDuration = "daylight_duration"
        case uvIndexMax = "uv_index_max"
    }
}
