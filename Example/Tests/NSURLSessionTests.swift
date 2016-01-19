//
//  NSURLSessionTests.swift
//  NSURLConnection-Mock
//
//  Created by Sam Dean on 18/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

class NSURLSessionTests: XCTestCase {
    
    func testSession_WithSingleMock_ShouldReturnMockData() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock this URL
        let URL = NSURL(string: "https://www.example.com/1")!
        let error = NSError(domain: "TestDomain", code: 0, userInfo: nil)
        NSURLConnection.mockEvery(URL, error: error, delay: 1.5)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(URL) { (data, response, error) -> Void in
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        // Validate that the mock data was returned
        let start = NSDate()
        self.waitForExpectationsWithTimeout(2.5) { timeoutError in
            XCTAssertNil(timeoutError)
            
            let end = NSDate()
            let interval = end.timeIntervalSinceDate(start)
            XCTAssert(interval > 1.0, "This request should have taken longer, it took \(interval)")
        }
    }
    
}
