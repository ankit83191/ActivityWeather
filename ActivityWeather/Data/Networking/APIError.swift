import Foundation

enum APIError: Error, Sendable, Equatable {
    case invalidRequest
    case nonHTTPResponse
    case httpStatus(Int)
    case transport(URLError)
    case decoding

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.invalidRequest, .invalidRequest),
             (.nonHTTPResponse, .nonHTTPResponse),
             (.decoding, .decoding):
            return true
        case let (.httpStatus(lhsCode), .httpStatus(rhsCode)):
            return lhsCode == rhsCode
        case let (.transport(lhsError), .transport(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
