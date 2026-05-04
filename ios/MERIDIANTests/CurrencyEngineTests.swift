import XCTest
@testable import MERIDIAN

final class CurrencyEngineTests: XCTestCase {

    private var engine: CurrencyEngine!

    override func setUp() {
        super.setUp()
        engine = CurrencyEngine()
    }

    func testConversionWithKnownRate() {
        // Seed a rate for testing
        let rate = CurrencyRate(
            id: "GBP/USD",
            rate: 1.27,
            previousRate: 1.25,
            timestamp: Date(),
            source: "test"
        )
        engine.rates = [rate]

        let result = engine.convert(amount: 100.0, from: "GBP", to: "USD")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 127.0, accuracy: 0.001)
    }

    func testConversionReturnsNilForUnknownPair() {
        engine.rates = []
        let result = engine.convert(amount: 100.0, from: "XYZ", to: "ABC")
        XCTAssertNil(result)
    }

    func testChangePercentCalculation() {
        let rate = CurrencyRate(
            id: "GBP/USD",
            rate: 1.27,
            previousRate: 1.25,
            timestamp: Date(),
            source: "test"
        )
        let change = rate.changePercent
        XCTAssertEqual(change, 1.6, accuracy: 0.1)
    }

    func testAddAlertAppendsToList() {
        let alert = RateAlert(
            id: UUID(),
            pair: "GBP/USD",
            threshold: 1.30,
            direction: .above,
            isActive: true
        )
        engine.addAlert(alert)
        XCTAssertEqual(engine.alerts.count, 1)
        XCTAssertEqual(engine.alerts.first?.pair, "GBP/USD")
    }

    func testRemoveAlertDeletesCorrectItem() {
        let id1 = UUID()
        let id2 = UUID()
        engine.alerts = [
            RateAlert(id: id1, pair: "GBP/USD", threshold: 1.30, direction: .above, isActive: true),
            RateAlert(id: id2, pair: "EUR/GBP", threshold: 0.85, direction: .below, isActive: true),
        ]
        engine.removeAlert(id: id1)
        XCTAssertEqual(engine.alerts.count, 1)
        XCTAssertEqual(engine.alerts.first?.id, id2)
    }
}
