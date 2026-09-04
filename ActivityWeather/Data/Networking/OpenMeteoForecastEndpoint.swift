import Foundation

enum OpenMeteoForecastEndpoint {
    static let dailyVariables: [String] = [
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
        "apparent_temperature_max",
        "precipitation_sum",
        "rain_sum",
        "snowfall_sum",
        "precipitation_hours",
        "wind_speed_10m_max",
        "wind_gusts_10m_max",
        "sunshine_duration",
        "daylight_duration",
        "uv_index_max"
    ]

    static func forecast(latitude: Double, longitude: Double) -> APIEndpoint {
        APIEndpoint(
            scheme: "https",
            host: "api.open-meteo.com",
            path: "/v1/forecast",
            queryItems: [
                URLQueryItem(name: "latitude", value: posixDecimal(latitude)),
                URLQueryItem(name: "longitude", value: posixDecimal(longitude)),
                URLQueryItem(name: "forecast_days", value: "7"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "temperature_unit", value: "celsius"),
                URLQueryItem(name: "wind_speed_unit", value: "kmh"),
                URLQueryItem(name: "precipitation_unit", value: "mm"),
                URLQueryItem(name: "daily", value: dailyVariables.joined(separator: ","))
            ]
        )
    }

    private static func posixDecimal(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
