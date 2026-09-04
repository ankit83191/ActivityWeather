struct Coordinate: Equatable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) throws {
        guard latitude.isFinite,
              longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            throw DomainError.invalidCoordinate
        }

        self.latitude = latitude
        self.longitude = longitude
    }
}
