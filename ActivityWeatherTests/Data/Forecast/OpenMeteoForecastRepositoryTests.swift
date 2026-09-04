import XCTest
@testable import ActivityWeather

final class OpenMeteoForecastRepositoryTests: XCTestCase {
    func testLoadsSevenDayForecastFromSelectedCoordinates() async throws {
        let dto = try ForecastFixture.decodeResponse(named: "forecast_success_seven_days")
        let client = ForecastStubAPIClient(behaviour: .success(dto))
        let repository = OpenMeteoForecastRepository(client: client)
        let location = try sampleLocation()

        let forecast = try await repository.forecast(for: location)
        let endpoints = await client.endpoints
        let endpoint = try XCTUnwrap(endpoints.first)
        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))

        XCTAssertEqual(forecast.days.count, 7)
        XCTAssertEqual(forecast.timeZoneIdentifier, "Europe/Berlin")
        XCTAssertEqual(queryValue("timezone", in: components), "auto")
        XCTAssertEqual(Double(try XCTUnwrap(queryValue("latitude", in: components))), location.coordinate.latitude)
        XCTAssertEqual(Double(try XCTUnwrap(queryValue("longitude", in: components))), location.coordinate.longitude)
        XCTAssertNil(queryValue("utc_offset_seconds", in: components))
    }

    func testPropagatesTransportError() async throws {
        let client = ForecastStubAPIClient(behaviour: .api(.transport(URLError(.notConnectedToInternet))))
        let repository = OpenMeteoForecastRepository(client: client)

        do {
            _ = try await repository.forecast(for: try sampleLocation())
            XCTFail("Expected transport")
        } catch let APIError.transport(urlError) {
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testPropagatesDecodingError() async throws {
        let client = ForecastStubAPIClient(behaviour: .api(.decoding))
        let repository = OpenMeteoForecastRepository(client: client)

        do {
            _ = try await repository.forecast(for: try sampleLocation())
            XCTFail("Expected decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testPropagatesCancellation() async throws {
        let client = ForecastStubAPIClient(behaviour: .cancellation)
        let repository = OpenMeteoForecastRepository(client: client)

        do {
            _ = try await repository.forecast(for: try sampleLocation())
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch let error as APIError {
            XCTFail("Cancellation became \(error)")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testPropagatesCancelledURLError() async throws {
        let client = ForecastStubAPIClient(behaviour: .url(URLError(.cancelled)))
        let repository = OpenMeteoForecastRepository(client: client)

        do {
            _ = try await repository.forecast(for: try sampleLocation())
            XCTFail("Expected cancellation")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cancelled)
        } catch is CancellationError {
            // Expected.
        } catch let error as APIError {
            XCTFail("Cancelled URLError became \(error)")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testPropagatesMappingErrors() async throws {
        let dto = try ForecastFixture.decodeResponse(named: "forecast_unexpected_unit")
        let client = ForecastStubAPIClient(behaviour: .success(dto))
        let repository = OpenMeteoForecastRepository(client: client)

        do {
            _ = try await repository.forecast(for: try sampleLocation())
            XCTFail("Expected unexpectedUnit")
        } catch let error as ForecastMappingError {
            XCTAssertEqual(
                error,
                .unexpectedUnit(field: "temperature_2m_max", expected: "°C", actual: "°F")
            )
        } catch let error as DomainError {
            XCTFail("Unexpected unit became DomainError \(error)")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testWrongJSONTypeThroughAPIClientIsDecoding() async throws {
        let host = "api.open-meteo.com"
        let payload = try ForecastFixture.data(named: "forecast_wrong_types")
        let url = URL(string: "https://\(host)/v1/forecast")!
        StubURLProtocol.register(
            host: host,
            result: .complete(
                HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!,
                payload
            )
        )
        defer { StubURLProtocol.reset() }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let repository = OpenMeteoForecastRepository(
            client: URLSessionAPIClient(session: URLSession(configuration: configuration))
        )

        do {
            _ = try await repository.forecast(for: try sampleLocation())
            XCTFail("Expected decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    private func sampleLocation() throws -> Location {
        Location(
            id: 2950159,
            displayName: "Berlin",
            region: "State of Berlin",
            country: "Germany",
            coordinate: try Coordinate(latitude: 52.52, longitude: 13.41),
            elevationMetres: 38,
            geocodingTimeZoneIdentifier: "Pacific/Auckland"
        )
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
