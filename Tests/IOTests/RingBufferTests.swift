import XCTest

@testable import IO

final class RingBufferTests: XCTestCase {
    func testNewRingBufferIsEmpty() {
        let minimumCapacity = 10

        let r = RingBuffer(capacity: minimumCapacity)
        XCTAssertEqual(r.availableToRead, 0)
        XCTAssertGreaterThan(r.availableToWrite, minimumCapacity)
    }

    static var allTests = [
        ("testNewRingBufferIsEmpty", testNewRingBufferIsEmpty)
    ]
}
