import Foundation

enum RepositoryFailureMapping {
    static func map(_ error: any Error) -> any Error {
        if error is CancellationError {
            return CancellationError()
        }

        if let urlError = error as? URLError {
            if urlError.code == .cancelled {
                return urlError
            }
            return connectivityCodes.contains(urlError.code)
                ? RepositoryFailure.offline
                : RepositoryFailure.unknown
        }

        if let apiError = error as? APIError {
            switch apiError {
            case let .transport(urlError):
                if urlError.code == .cancelled {
                    return urlError
                }
                return connectivityCodes.contains(urlError.code)
                    ? RepositoryFailure.offline
                    : RepositoryFailure.unknown
            case let .httpStatus(status):
                return status == 429 || (500...599).contains(status)
                    ? RepositoryFailure.serviceUnavailable
                    : RepositoryFailure.unknown
            case .invalidRequest, .nonHTTPResponse, .decoding:
                return RepositoryFailure.invalidData
            }
        }

        if error is GeocodingError
            || error is ForecastMappingError
            || error is DomainError
            || error is DecodingError {
            return RepositoryFailure.invalidData
        }

        if let repositoryFailure = error as? RepositoryFailure {
            return repositoryFailure
        }
        return RepositoryFailure.unknown
    }

    private static let connectivityCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .cannotConnectToHost,
        .cannotFindHost,
        .dnsLookupFailed,
        .timedOut,
        .internationalRoamingOff,
        .dataNotAllowed,
        .secureConnectionFailed,
        .cannotLoadFromNetwork,
        .backgroundSessionWasDisconnected
    ]
}
