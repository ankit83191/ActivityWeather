import Foundation

enum GeocodingLocationMapper {
    static func locations(from dto: GeocodingResponseDTO) throws -> [Location] {
        guard let results = dto.results else {
            return []
        }
        if results.isEmpty {
            return []
        }

        let locations = results.compactMap(location(from:))
        guard !locations.isEmpty else {
            throw GeocodingError.noValidLocations
        }
        return locations
    }

    private static func location(from dto: GeocodingResultDTO) -> Location? {
        guard let id = dto.id else {
            return nil
        }

        let name = trimmed(dto.name)
        let country = trimmed(dto.country)
        guard let name, let country else {
            return nil
        }
        guard let latitude = dto.latitude, let longitude = dto.longitude else {
            return nil
        }
        guard let coordinate = try? Coordinate(latitude: latitude, longitude: longitude) else {
            return nil
        }

        return Location(
            id: id,
            displayName: name,
            region: trimmed(dto.admin1),
            country: country,
            coordinate: coordinate,
            elevationMetres: dto.elevation,
            geocodingTimeZoneIdentifier: trimmed(dto.timezone)
        )
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
