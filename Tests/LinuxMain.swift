import XCTest
@testable import AsyncTests

XCTMain([
    testCase(AsyncTests.allTests),
    testCase(AsyncGroupTests.allTests)
])
