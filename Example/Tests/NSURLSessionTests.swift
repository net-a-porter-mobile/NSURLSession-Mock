//
//  NSURLSessionTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 18/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

import NSURLSession_Mock

private class SessionTestDelegate: NSObject, NSURLSessionDataDelegate {
    var expectations: [XCTestExpectation]
    
    var dataKeyedByTask = Dictionary<Int, NSMutableData>() // [ taskIdentifier: data from task ]
    
    init(expectations: [XCTestExpectation]) {
        self.expectations = expectations
    }
    
    @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData recievedData: NSData) {
        var data = dataKeyedByTask[dataTask.taskIdentifier]
        
        if data == nil {
            data = NSMutableData()
            dataKeyedByTask[dataTask.taskIdentifier] = data
        }
        
        data!.appendData(recievedData)
    }
    
    @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        let expectation = expectations.first!
        expectation.fulfill()
        expectations.removeFirst()
    }
}


class NSURLSessionTests: XCTestCase {
    
    override func tearDown() {
        NSURLSession.removeAllMocks()
    }
    
    func testSession_WithSingleMock_ShouldReturnMockDataOnce() {
        let expectation1 = self.expectationWithDescription("Complete called for 1")
        let expectation2 = self.expectationWithDescription("Complete called for 2")
        
        // Tell NSURLSession to mock thhis URL, each time with different data
        let URL = NSURL(string: "https://www.example.com/1")!
        let body1 = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
        let request1 = NSURLRequest.init(URL: URL)
        NSURLSession.mockSingle(request1, body: body1)

        let body2 = "Test response 2".dataUsingEncoding(NSUTF8StringEncoding)!
        let request2 = NSURLRequest.init(URL: URL)
        NSURLSession.mockSingle(request2, body: body2)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())

        // Perform both tasks
        let task1 = session.dataTaskWithRequest(request1)
        task1.resume()
        
        let task2 = session.dataTaskWithRequest(request2)
        task2.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(1) { timeoutError in
            XCTAssertNil(timeoutError)
            
            XCTAssertEqual(delegate.dataKeyedByTask[task1.taskIdentifier], body1)
            XCTAssertEqual(delegate.dataKeyedByTask[task2.taskIdentifier], body2)
        }
    }
    
    func testSession_WithEveryMock_ShouldReturnMockEachTime() {
        let expectation1 = self.expectationWithDescription("Complete called for 1")
        let expectation2 = self.expectationWithDescription("Complete called for 2")
        let expectation3 = self.expectationWithDescription("Complete called for 3")
        
        // Tell NSURLSession to mock thhis URL, each time with different data
        let URL = NSURL(string: "https://www.example.com/1")!
        let body = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURLRequest.init(URL: URL)
        NSURLSession.mockEvery(request, body: body)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2, expectation3 ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        // Perform the task a few times
        let task1 = session.dataTaskWithRequest(request)
        task1.resume()
        
        let task2 = session.dataTaskWithRequest(request)
        task2.resume()

        let task3 = session.dataTaskWithRequest(request)
        task3.resume()

        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(1) { timeoutError in
            XCTAssertNil(timeoutError)
            
            XCTAssertEqual(delegate.dataKeyedByTask[task1.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTask[task2.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTask[task3.taskIdentifier], body)
        }
    }
    
    func testSession_WithDelayedMock_ShouldReturnMockAfterDelay() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLSession to mock thhis URL, each time with different data
        let URL = NSURL(string: "https://www.example.com/1")!
        let body = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURLRequest.init(URL: URL)
        NSURLSession.mockEvery(request, body: body, delay: 1)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        // Perform the task
        let task1 = session.dataTaskWithRequest(request)
        task1.resume()
        
        // Record the start time
        let start = NSDate()
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(2) { timeoutError in
            XCTAssertNil(timeoutError)

            // Sanity it's actually mocked
            XCTAssertEqual(delegate.dataKeyedByTask[task1.taskIdentifier], body)
            
            // Check the delay
            let interval = -start.timeIntervalSinceNow
            XCTAssert(interval > 1, "Should have taken more than one second to perform (it took \(interval)")
            XCTAssert(interval < 1.2, "Should have taken less than 1.2 seconds to perform (it took \(interval)")
        }
    }

}
