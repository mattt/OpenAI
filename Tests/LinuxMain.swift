import XCTest

import OpenAITests

var tests = [XCTestCaseEntry]()
tests += OpenAITests.allTests()
XCTMain(tests)
