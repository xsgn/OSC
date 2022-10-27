import XCTest
@testable import OSC

final class OSCTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OSC().text, "Hello, World!")
    }
    func testMemory() {
        do {
            let result = withUnsafeTemporaryAllocation(of: Float32.self, capacity: 10) {
                print($0.baseAddress)
                return Array($0)
            }
            result.withUnsafeBufferPointer {
                print($0.baseAddress)
            }
        }
        do {
            let result = Array<Float32>(unsafeUninitializedCapacity: 10) {
                print($0.baseAddress)
                $1 = $0.count
            }
            result.withUnsafeBufferPointer {
                print($0.baseAddress)
            }
        }
    }
}
