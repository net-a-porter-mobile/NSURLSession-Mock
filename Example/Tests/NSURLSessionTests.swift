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
    
    var dataKeyedByTaskIdentifier : [Int : NSMutableData] = [:]
    var responseKeyedByTaskIdentifier : [Int : NSURLResponse] = [:]
    
    init(expectations: [XCTestExpectation]) {
        self.expectations = expectations
    }
    
    @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.responseKeyedByTaskIdentifier[dataTask.taskIdentifier] = response
    }
    
    @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData recievedData: NSData) {
        var data = dataKeyedByTaskIdentifier[dataTask.taskIdentifier]
        
        if data == nil {
            data = NSMutableData()
            dataKeyedByTaskIdentifier[dataTask.taskIdentifier] = data
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
    
    override func setUp() {
        super.setUp()
        
        NSURLSession.debugMockRequests = .All
    }
    
    override func tearDown() {
        NSURLSession.removeAllMocks()
        
        super.tearDown()
    }
    
    func testSession_WithSingleMock_ShouldReturnMockDataOnce() {
        let expectation1 = self.expectationWithDescription("Complete called for 1")
        let expectation2 = self.expectationWithDescription("Complete called for 2")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let URL = NSURL(string: "https://www.example.com/1")!
        let body1 = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
        let request1 = NSURLRequest.init(URL: URL)
        NSURLSession.mockNext(request1, body: body1)
        
        let body2 = "Test response 2".dataUsingEncoding(NSUTF8StringEncoding)!
        let request2 = NSURLRequest.init(URL: URL)
        NSURLSession.mockNext(request2, body: body2)
        
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
            
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body1)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], body2)
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
            
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task3.taskIdentifier], body)
        }
    }
    
    func testSession_WithDelayedMock_ShouldReturnMockAfterDelay() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let URL = NSURL(string: "https://www.example.com/1")!
        let body = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURLRequest.init(URL: URL)
        NSURLSession.mockEvery(request, body: body, delay: 1)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [expectation])
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
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body)
            
            // Check the delay
            let interval = -start.timeIntervalSinceNow
            XCTAssert(interval > 1, "Should have taken more than one second to perform (it took \(interval)")
            XCTAssert(interval < 1.2, "Should have taken less than 1.2 seconds to perform (it took \(interval)")
        }
    }
    
    
    func testSession_WithStatusCodeAndHeaders_ShouldReturnTheCorrectStatusCodes() {
        let expectation = self.expectationWithDescription("Complete called for headers and status code")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let URL = NSURL(string: "https://www.example.com/1")!
        let body = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURLRequest.init(URL: URL)
        let headers = ["Content-Type" : "application/test", "Custom-Header" : "Is custom"]
        NSURLSession.mockNext(request, body: body, headers: headers, statusCode: 200)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [expectation])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        // Perform task
        let task = session.dataTaskWithRequest(request)
        task.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(1) { timeoutError in
            XCTAssertNil(timeoutError)
            
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task.taskIdentifier], body)
            guard let response = delegate.responseKeyedByTaskIdentifier[task.taskIdentifier] as? NSHTTPURLResponse else {
                XCTFail("Response isn't the correct type")
                return
            }
            XCTAssertEqual(response.statusCode, 200)
            guard let responseHeaders = response.allHeaderFields as? [String : String] else {
                XCTFail("Response headers couldn't be transformed to String")
                return
            }
            XCTAssertEqual(responseHeaders, headers)
        }
    }
    
    func testSession_WithRegularExpression_ShouldMatch() {
        let expectation1 = self.expectationWithDescription("Complete called for request 1")
        let expectation2 = self.expectationWithDescription("Complete called for request 2")
        
        // Mock with a regex
        let body = "{'mocked':true}".dataUsingEncoding(NSUTF8StringEncoding)
        try! NSURLSession.mockEvery(".*/a.json", body: body)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        // Perform two tasks
        let request1 = NSURLRequest(URL: NSURL(string: "http://www.example.com/a.json?param1=1")!)
        let task1 = session.dataTaskWithRequest(request1)
        task1.resume()
        
        let request2 = NSURLRequest(URL: NSURL(string: "http://www.example.com/a.json?param2=2")!)
        let task2 = session.dataTaskWithRequest(request2)
        task2.resume()
        
        self.waitForExpectationsWithTimeout(1) { timeoutError in
            // Make sure it was the mock and not a valid response!
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], body)
        }
    }
    
    func testSession_WithUnauthorizedRequest_ShouldReturnCanceledTask() {
        let url = NSURL(string: "http://www.google.com")!
        let request = NSURLRequest(URL:url)
        
        // Create a session
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        NSURLSession.requestEvaluator = { request in
            return .Reject
        }
        
        SwiftTryCatch.tryBlock({ () -> Void in
            let _ = session.dataTaskWithRequest(request)
            }, catchBlock: { (exception) -> Void in
                XCTAssertTrue(exception.name == "Mocking Exception")
            }) {}
    }

    func testSession_WithBlock_ShouldReturnModifiedData() {
        // Create an expression which will match the product id
        let expression = "http://www.example.com/product/([0-9]{6})"
        try! NSURLSession.mockEvery(expression) { (matches: [String]) in
            return matches.first!.dataUsingEncoding(NSUTF8StringEncoding)!
        }

        // We are going to make two requests, with two different product ids.
        // When the delegate reports them both complete, we will check that the
        // data returned was valid for that specific URL
        let expectation1 = self.expectationWithDescription("Complete called for request 123456")
        let expectation2 = self.expectationWithDescription("Complete called for request 654321")

        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())

        // Perform two tasks
        let request1 = NSURLRequest(URL: NSURL(string: "http://www.example.com/product/123456")!)
        let task1 = session.dataTaskWithRequest(request1)
        task1.resume()

        let request2 = NSURLRequest(URL: NSURL(string: "http://www.example.com/product/654321")!)
        let task2 = session.dataTaskWithRequest(request2)
        task2.resume()

        self.waitForExpectationsWithTimeout(1) { timeoutError in
            // Make sure it was the mock and not a valid response!
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], "123456".dataUsingEncoding(NSUTF8StringEncoding))
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], "654321".dataUsingEncoding(NSUTF8StringEncoding))
        }
    }
    
    func testSession_WithConsumedSingleMock_ShouldBeConsumed() {
        let path = "http://www.example.com/test_path"
        let URL = NSURL(string: path)!
        let request = NSURLRequest(URL: URL)
        let handle = NSURLSession.mockNext(request, body: nil)
        
        let expectation1 = self.expectationWithDescription("Complete called")
        
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation1 ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        let task = session.dataTaskWithRequest(request)
        task.resume()
        
        self.waitForExpectationsWithTimeout(1) { error in
            let hasConsumed = NSURLSession.hasMockConsumed(handle)
            XCTAssertTrue(hasConsumed, "The handle should have been consumed")
        }
    }
    
    func testSession_WithNotYetConsumedSingleMock_ShouldNotBeConsumed() {
        // This handle should never be consumed - we're not going to be calling this URL
        let path = "http://www.example.com/test_path"
        let URL = NSURL(string: path)!
        let request = NSURLRequest(URL: URL)
        let handle = NSURLSession.mockNext(request, body: nil)
        
        // Mock this url as well so that we don't rely on network traffic to pass the test :)
        let path2 = "http://www.example.com/path_does_not_match"
        let URL2 = NSURL(string: path2)!
        let request2 = NSURLRequest(URL: URL2)
        NSURLSession.mockNext(request2, body: nil)
        
        // Sanity - make sure that we aren't going out to the network
        let originalEvaluator = NSURLSession.requestEvaluator
        NSURLSession.requestEvaluator = { _ in return .Reject }
        
        let expectation1 = self.expectationWithDescription("Complete called")
        
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = SessionTestDelegate(expectations: [ expectation1 ])
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        let testPath = "http://www.example.com/path_does_not_match"
        let testURL = NSURL(string: testPath)!
        let testRequest = NSURLRequest(URL: testURL)
        let task = session.dataTaskWithRequest(testRequest)
        task.resume()
        
        self.waitForExpectationsWithTimeout(1) { error in
            let hasConsumed = NSURLSession.hasMockConsumed(handle)
            XCTAssertFalse(hasConsumed, "The handle should not have been consumed")
        }
        
        // Reset the evaluator so we aren't screwing with any other tests
        NSURLSession.requestEvaluator = originalEvaluator
    }

}
