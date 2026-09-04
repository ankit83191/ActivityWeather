import Foundation

struct GeocodingResponseDTO: Decodable, Sendable {
    let results: [GeocodingResultDTO]?
}

struct GeocodingResultDTO: Decodable, Sendable {
    let id: Int?
    let name: String?
    let latitude: Double?
    let longitude: Double?
    let elevation: Double?
    let country: String?
    let admin1: String?
    let timezone: String?
}
