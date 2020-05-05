import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(coherent_swiftTests.allTests),
    ]
}
#endif
