struct Location: Identifiable, Sendable {
    let id: Int
    let displayName: String
    let region: String?
    let country: String
    let coordinate: Coordinate
    let elevationMetres: Double?
    let geocodingTimeZoneIdentifier: String?
}

extension Location: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Location: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
