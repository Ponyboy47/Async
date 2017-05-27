import XCTest
@testable import AsyncTestSuite

XCTMain([
    testCase(AsyncTests.allTests),
    testCase(AsyncGroupTests.allTests)
])
