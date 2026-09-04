import XCTest
@testable import ActivityWeather

private struct SamplePayload: Decodable, Sendable, Equatable {
    let name: String
}

final class URLSessionAPIClientTests: XCTestCase {
    private var client: URLSessionAPIClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        client = URLSessionAPIClient(session: URLSession(configuration: configuration))
    }

    override func tearDown() {
        StubURLProtocol.reset()
        client = nil
        super.tearDown()
    }

    func testDecodesPayloadFromHTTP200() async throws {
        let host = uniqueHost()
        StubURLProtocol.register(
            host: host,
            result: .complete(httpResponse(host: host, status: 200), Data(#"{"name":"Berlin"}"#.utf8))
        )

        let payload: SamplePayload = try await client.execute(endpoint(host: host))
        XCTAssertEqual(payload, SamplePayload(name: "Berlin"))
    }

    func testDecodesPayloadFromHTTP201() async throws {
        let host = uniqueHost()
        StubURLProtocol.register(
            host: host,
            result: .complete(httpResponse(host: host, status: 201), Data(#"{"name":"Paris"}"#.utf8))
        )

        let payload: SamplePayload = try await client.execute(endpoint(host: host))
        XCTAssertEqual(payload.name, "Paris")
    }

    func testMapsNon2xxStatusBeforeDecoding() async {
        let host = uniqueHost()
        StubURLProtocol.register(
            host: host,
            result: .complete(httpResponse(host: host, status: 404), Data(#"{"name":"ignored"}"#.utf8))
        )

        do {
            let _: SamplePayload = try await client.execute(endpoint(host: host))
            XCTFail("Expected httpStatus")
        } catch let error as APIError {
            XCTAssertEqual(error, .httpStatus(404))
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testRejectsNonHTTPResponse() async {
        let host = uniqueHost()
        let url = URL(string: "https://\(host)/v1/search")!
        StubURLProtocol.register(
            host: host,
            result: .complete(URLResponse(url: url, mimeType: "application/json", expectedContentLength: 2, textEncodingName: nil), Data("{}".utf8))
        )

        do {
            let _: SamplePayload = try await client.execute(endpoint(host: host))
            XCTFail("Expected nonHTTPResponse")
        } catch let error as APIError {
            XCTAssertEqual(error, .nonHTTPResponse)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testMapsTransportFailure() async {
        let host = uniqueHost()
        let transport = URLError(.notConnectedToInternet)
        StubURLProtocol.register(host: host, result: .failure(transport))

        do {
            let _: SamplePayload = try await client.execute(endpoint(host: host))
            XCTFail("Expected transport")
        } catch let APIError.transport(urlError) {
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testMapsMalformedJSONToDecoding() async {
        let host = uniqueHost()
        StubURLProtocol.register(
            host: host,
            result: .complete(httpResponse(host: host, status: 200), Data(#"{"name":"#.utf8))
        )

        do {
            let _: SamplePayload = try await client.execute(endpoint(host: host))
            XCTFail("Expected decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testCancelledURLErrorIsNotWrappedAsTransport() async {
        let host = uniqueHost()
        StubURLProtocol.register(host: host, result: .failure(URLError(.cancelled)))

        do {
            let _: SamplePayload = try await client.execute(endpoint(host: host))
            XCTFail("Expected cancellation")
        } catch let error as APIError {
            XCTFail("Cancelled URLError became \(error)")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cancelled)
        } catch is CancellationError {
            // Also treated as cancellation, not APIError.transport.
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testTaskCancellationIsNotMappedToAPIError() async {
        let host = uniqueHost()
        StubURLProtocol.register(host: host, result: .hang)
        let apiClient = client!
        let request = endpoint(host: host)
        let work = Task {
            try await apiClient.execute(request) as SamplePayload
        }

        await StubURLProtocol.waitUntilRequestStarts(host: host)
        work.cancel()

        do {
            _ = try await work.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch let error as URLError where error.code == .cancelled {
            // Expected.
        } catch let error as APIError {
            XCTFail("Task cancellation became \(error)")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    private func uniqueHost() -> String {
        "\(UUID().uuidString.lowercased()).example"
    }

    private func endpoint(host: String) -> APIEndpoint {
        APIEndpoint(scheme: "https", host: host, path: "/v1/search", queryItems: [])
    }

    private func httpResponse(host: String, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://\(host)/v1/search")!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}
