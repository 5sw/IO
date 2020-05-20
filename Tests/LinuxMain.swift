import XCTest
import IOTests

var tests: [XCTestCaseEntry] = []
tests += IOTests.allTests()

XCTMain(tests)

