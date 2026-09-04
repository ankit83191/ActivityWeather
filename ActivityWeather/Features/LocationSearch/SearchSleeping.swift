import Foundation

protocol SearchSleeping: Sendable {
    func sleep() async throws
}

struct TaskSearchSleeper: SearchSleeping {
    private let duration: Duration

    init(duration: Duration = .milliseconds(350)) {
        self.duration = duration
    }

    func sleep() async throws {
        try await Task.sleep(for: duration)
    }
}
