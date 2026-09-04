import Foundation

enum UserFacingFailure: Equatable {
    case connection
    case service
    case invalidData
    case generic

    var recoveryMessage: String {
        switch self {
        case .connection:
            "Check your internet connection and try again."
        case .service:
            "The weather service is temporarily unavailable. Try again shortly."
        case .invalidData:
            "The weather service returned information the app couldn’t use. Try again."
        case .generic:
            "Something unexpected happened. Try again."
        }
    }

    static func classify(_ error: any Error) -> UserFacingFailure {
        guard let repositoryFailure = error as? RepositoryFailure else {
            return .generic
        }

        switch repositoryFailure {
        case .offline:
            return .connection
        case .serviceUnavailable:
            return .service
        case .invalidData:
            return .invalidData
        case .unknown:
            return .generic
        }
    }
}
