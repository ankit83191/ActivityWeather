enum DomainError: Error, Equatable, Sendable {
    case invalidCoordinate
    case invalidScore(Int)
    case invalidCivilDate
    case invalidForecastTimezone
    case invalidForecastWindow
    case invalidForecastValues
    case missingCriticalData
}
