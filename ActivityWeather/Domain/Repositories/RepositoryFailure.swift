enum RepositoryFailure: Error, Equatable, Sendable {
    case offline
    case serviceUnavailable
    case invalidData
    case unknown
}
