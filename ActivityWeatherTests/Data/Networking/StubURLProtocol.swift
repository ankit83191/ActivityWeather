import Foundation

enum StubURLProtocolResult: Sendable {
    case complete(URLResponse, Data)
    case failure(URLError)
    case hang
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var results: [String: StubURLProtocolResult] = [:]
        var startedHosts: Set<String> = []
        var startWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]
    }

    private static let storage = Storage()

    static func register(host: String, result: StubURLProtocolResult) {
        storage.lock.lock()
        storage.results[host] = result
        storage.lock.unlock()
    }

    static func reset() {
        storage.lock.lock()
        storage.results.removeAll()
        storage.startedHosts.removeAll()
        storage.startWaiters.removeAll()
        storage.lock.unlock()
    }

    static func waitUntilRequestStarts(host: String) async {
        await withCheckedContinuation { continuation in
            storage.lock.lock()
            if storage.startedHosts.contains(host) {
                storage.lock.unlock()
                continuation.resume()
                return
            }
            storage.startWaiters[host, default: []].append(continuation)
            storage.lock.unlock()
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let host = request.url?.host else {
            return false
        }
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.results[host] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let host = request.url?.host else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        Self.storage.lock.lock()
        Self.storage.startedHosts.insert(host)
        let result = Self.storage.results[host]
        let waiters = Self.storage.startWaiters.removeValue(forKey: host) ?? []
        Self.storage.lock.unlock()
        waiters.forEach { $0.resume() }

        switch result {
        case let .complete(response, data):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case .hang:
            break
        case .none:
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
        }
    }

    override func stopLoading() {}
}
