struct CivilDate: Equatable, Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) throws {
        guard (1...9999).contains(year),
              (1...12).contains(month),
              (1...Self.daysInMonth(year: year, month: month)).contains(day) else {
            throw DomainError.invalidCivilDate
        }

        self.year = year
        self.month = month
        self.day = day
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.day < rhs.day
    }

    func isImmediatelyBefore(_ other: Self) -> Bool {
        guard let next = nextDay else {
            return false
        }
        return next == other
    }

    private var nextDay: Self? {
        let daysThisMonth = Self.daysInMonth(year: year, month: month)
        if day < daysThisMonth {
            return try? Self(year: year, month: month, day: day + 1)
        }
        if month < 12 {
            return try? Self(year: year, month: month + 1, day: 1)
        }
        guard year < 9999 else {
            return nil
        }
        return try? Self(year: year + 1, month: 1, day: 1)
    }

    private static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2:
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }

    private static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 400)
            || (year.isMultiple(of: 4) && !year.isMultiple(of: 100))
    }
}
