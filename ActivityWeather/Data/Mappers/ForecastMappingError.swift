enum ForecastMappingError: Error, Equatable, Sendable {
    case unexpectedUnit(field: String, expected: String, actual: String)
}
