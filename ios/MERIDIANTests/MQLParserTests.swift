import XCTest
@testable import MERIDIAN

final class MQLParserTests: XCTestCase {

    private var runtime: MQLRuntime!

    override func setUp() {
        super.setUp()
        runtime = MQLRuntime()
    }

    func testScanStatementParsesCorrectly() async {
        let query = #"SCAN domain "example.com""#
        await runtime.execute(query: query)
        let entry = runtime.history.last
        XCTAssertNotNil(entry)
        XCTAssertNil(entry?.error, "Expected no error for valid SCAN query")
    }

    func testFindWithWhereClause() async {
        let query = """
        FIND opportunities
          WHERE market = "saas"
          AND currency.stability > 0.9
          RANK BY opportunity_score DESC
          LIMIT 10
        """
        await runtime.execute(query: query)
        let entry = runtime.history.last
        XCTAssertNil(entry?.error, "Expected no error for valid FIND query")
    }

    func testGenerateStatementWithAllOptions() async {
        let query = """
        GENERATE ad
          FOR domain "competitor.com"
          STYLE "static"
          LANGUAGE "en-GB"
          CURRENCY "GBP"
          PLATFORM "instagram"
          FRAMEWORK "AIDA"
        """
        await runtime.execute(query: query)
        let entry = runtime.history.last
        XCTAssertNil(entry?.error, "Expected no error for valid GENERATE query")
    }

    func testAlertStatement() async {
        let query = """
        ALERT WHEN
          currency "USD/GBP" rate.change > 3%
          NOTIFY via "push"
          WITH message "Rate moved"
        """
        await runtime.execute(query: query)
        let entry = runtime.history.last
        XCTAssertNil(entry?.error, "Expected no error for valid ALERT query")
    }

    func testHistoryAccumulates() async {
        let queries = [
            #"SCAN domain "a.com""#,
            #"SCAN domain "b.com""#,
            #"SCAN domain "c.com""#,
        ]
        for query in queries {
            await runtime.execute(query: query)
        }
        XCTAssertEqual(runtime.history.count, 3)
    }

    func testEmptyQueryHandledGracefully() async {
        await runtime.execute(query: "")
        let entry = runtime.history.last
        XCTAssertNotNil(entry?.error, "Expected error for empty query")
    }
}
