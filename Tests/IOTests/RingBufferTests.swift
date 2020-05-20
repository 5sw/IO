import XCTest

@testable import IO

final class RingBufferTests: XCTestCase {
    func testNewRingBufferIsEmpty() {
        let minimumCapacity = 10

        let r = RingBuffer(capacity: minimumCapacity)
        XCTAssertEqual(r.availableToRead, 0)
        XCTAssertGreaterThan(r.availableToWrite, minimumCapacity)
    }

    func testCopying() throws {
        let first = RingBuffer(capacity: 10)
        try first.write([1, 2, 42, 5])

        let second = RingBuffer(first)

        XCTAssertEqual(first.availableToRead, 4)
        XCTAssertEqual(second.availableToRead, 4)

        let testBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 10, alignment: 0)
        defer { testBuffer.deallocate() }

        let readFirst = first.read(buffer: testBuffer)
        XCTAssertTrue(testBuffer.prefix(readFirst).elementsEqual([1, 2, 42, 5]))

        XCTAssertEqual(first.availableToRead, 0)
        XCTAssertEqual(second.availableToRead, 4)

        bzero(testBuffer.baseAddress!, 10)

        let readSecond = second.read(buffer: testBuffer)
        XCTAssertTrue(testBuffer.prefix(readSecond).elementsEqual([1, 2, 42, 5]))

        XCTAssertEqual(second.availableToRead, 0)
    }

    func testGrowing() throws {
        var buffer = RingBuffer(capacity: 10)
        try buffer.write([1, 2, 42, 5])

        weak var oldObject = buffer.buffer

        let oldCapacity = buffer.capacity

        buffer.grow()

        XCTAssertNil(oldObject)

        XCTAssertGreaterThan(buffer.capacity, oldCapacity)

        let testBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: buffer.capacity, alignment: 0)
        defer { testBuffer.deallocate() }

        let read = buffer.read(buffer: testBuffer)
        XCTAssertTrue(testBuffer.prefix(read).elementsEqual([1, 2, 42, 5]))
    }

    static var allTests = [
        ("testNewRingBufferIsEmpty", testNewRingBufferIsEmpty),
        ("testCopying", testCopying),
        ("testGrowing", testGrowing),
    ]
}
