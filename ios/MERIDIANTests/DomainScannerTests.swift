import XCTest
@testable import MERIDIAN

final class DomainScannerTests: XCTestCase {

    func testNormalisesHttpPrefix() {
        XCTAssertEqual(DomainScanner.normalise(input: "http://example.com"), "example.com")
    }

    func testNormalisesHttpsPrefix() {
        XCTAssertEqual(DomainScanner.normalise(input: "https://example.com"), "example.com")
    }

    func testNormalisesWwwPrefix() {
        XCTAssertEqual(DomainScanner.normalise(input: "www.example.com"), "example.com")
    }

    func testNormalisesFullURL() {
        XCTAssertEqual(
            DomainScanner.normalise(input: "https://www.example.com/path?q=1"),
            "example.com"
        )
    }

    func testNormalisesTrailingSlash() {
        XCTAssertEqual(DomainScanner.normalise(input: "example.com/"), "example.com")
    }

    func testValidDomainAccepted() {
        XCTAssertTrue(DomainScanner.isValid(domain: "example.com"))
        XCTAssertTrue(DomainScanner.isValid(domain: "sub.example.co.uk"))
        XCTAssertTrue(DomainScanner.isValid(domain: "shopify.com"))
    }

    func testInvalidDomainRejected() {
        XCTAssertFalse(DomainScanner.isValid(domain: "not-a-domain"))
        XCTAssertFalse(DomainScanner.isValid(domain: ""))
        XCTAssertFalse(DomainScanner.isValid(domain: "just-text"))
    }

    func testIPAddressRejected() {
        XCTAssertFalse(DomainScanner.isValid(domain: "192.168.1.1"))
    }
}
