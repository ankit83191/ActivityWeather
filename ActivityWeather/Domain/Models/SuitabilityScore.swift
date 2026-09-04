struct SuitabilityScore: Equatable, Hashable, Comparable, Sendable {
    let value: Int

    init(_ value: Int) throws {
        guard (0...100).contains(value) else {
            throw DomainError.invalidScore(value)
        }
        self.value = value
    }

    init(clamping value: Int) {
        self.value = min(max(value, 0), 100)
    }

    var level: SuitabilityLevel {
        switch value {
        case 0...24: .poor
        case 25...49: .fair
        case 50...74: .good
        default: .great
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

enum SuitabilityLevel: String, Equatable, Sendable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case great = "Great"
}
