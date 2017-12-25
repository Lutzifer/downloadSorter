/**
 *  DownloadSorter
 *  Copyright (c) Wolfgang Lutz 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import DownloadSorterCore
import XCTest

class DownloadSorterTests: XCTestCase {
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
}

extension DownloadSorterTests {
  static var allTests: [(String, (DownloadSorterTests) -> () throws -> Void)] {
    return [
      ("testExample", testExample),
      ("testPerformanceExample", testPerformanceExample)
    ]
  }
}
