//
//  NSURLSessionTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 18/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

import NSURLSession_Mock


private class SessionTestDelegate: NSObject, URLSessionDataDelegate {
    var expectations: [XCTestExpectation]
    
    var dataKeyedByTaskIdentifier: [Int: Data] = [:]
    var responseKeyedByTaskIdentifier: [Int: URLResponse] = [:]
    var errorKeyedByTaskIdentifier: [Int: Error] = [:]
    
    init(expectations: [XCTestExpectation]) {
        self.expectations = expectations
    }
    
    @objc func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        self.responseKeyedByTaskIdentifier[dataTask.taskIdentifier] = response
    }
    
    @objc func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive recievedData: Data) {
        var data = self.dataKeyedByTaskIdentifier[dataTask.taskIdentifier] ?? Data()
        
        data.append(recievedData)
        
        self.dataKeyedByTaskIdentifier[dataTask.taskIdentifier] = data
    }
    
    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.errorKeyedByTaskIdentifier[task.taskIdentifier] = error
        }

        let expectation = self.expectations.first!
        expectation.fulfill()
        self.expectations.removeFirst()
    }
}


class NSURLSessionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLSession.debugMockRequests = .all
    }
    
    override func tearDown() {
        URLSession.removeAllMocks()
        
        super.tearDown()
    }
    
    func testSession_WithSingleMock_ShouldReturnMockDataOnce() {
        let expectation1 = self.expectation(description: "Complete called for 1")
        let expectation2 = self.expectation(description: "Complete called for 2")
        let expectation3 = self.expectation(description: "Complete callback called for 2")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let url1 = URL(string: "https://www.example.com/1")!
        let body1 = "Test response 1".data(using: String.Encoding.utf8)!
        let request1 = URLRequest(url: url1)
        _ = URLSession.mockNext(request: request1, body: body1)
        
        let url2 = URL(string: "https://www.example.com/2")!
        let body2 = "Test response 2".data(using: String.Encoding.utf8)!
        let request2 = URLRequest(url: url2)
        _ = URLSession.mockNext(request: request2, body: body2)
        
        // Create a session
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        // Perform both tasks
        let task1 = session.dataTask(with: request1)
        task1.resume()
        
        let task2 = session.dataTask(with: request2) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            
            XCTAssertNil(error, "Error in callback")
            
            XCTAssertEqual(data!, body2)
            expectation3.fulfill()
            return
        }
        task2.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectations(timeout: 1) { timeoutError in
            XCTAssertNil(timeoutError)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body1)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], body2)
        }
    }
    
    func testSession_WithEveryMock_ShouldReturnMockEachTime() {
        let expectation1 = self.expectation(description: "Complete called for 1")
        let expectation2 = self.expectation(description: "Complete called for 2")
        let expectation3 = self.expectation(description: "Complete called for 3")
        let expectation4 = self.expectation(description: "Complete callback called for 3")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let url = URL(string: "https://www.example.com/1")!
        let body = "Test response 1".data(using: String.Encoding.utf8)!
        let request = URLRequest(url: url)
        URLSession.mockEvery(request: request, body: body)
        
        // Create a session
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2, expectation3 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        // Perform the task a few times
        let task1 = session.dataTask(with: request)
        task1.resume()
        
        let task2 = session.dataTask(with: request)
        task2.resume()
        
        let task3 = session.dataTask(with: request) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            
            XCTAssertNil(error, "Error in callback")
            
            XCTAssertEqual(data, body)
            expectation4.fulfill()
            return
        }
        task3.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectations(timeout: 1) { timeoutError in
            XCTAssertNil(timeoutError)
            
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task3.taskIdentifier], body)
        }
    }
    
    func testSession_WithDelayedMock_ShouldReturnMockAfterDelay() {
        let expectation1 = self.expectation(description: "Complete called for 1")
        let expectation2 = self.expectation(description: "Complete called for 2")
        let expectation3 = self.expectation(description: "Complete callback called for 2")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let url = URL(string: "https://www.example.com/1")!
        let body = "Test response 1".data(using: String.Encoding.utf8)!
        let request = URLRequest(url: url)
        URLSession.mockEvery(request: request, body: body, delay: 1)
        
        // Create a session
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [expectation1, expectation2])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        // Record the start time
        let start = NSDate()
        
        // Perform the task
        let task1 = session.dataTask(with: request)
        task1.resume()
        
        // Perform the task with callback
        let task2 = session.dataTask(with: request) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            
            XCTAssertNil(error, "Error in callback")
            
            // Sanity it's actually mocked
            XCTAssertEqual(data, body)
            
            // Check the delay
            let interval = -start.timeIntervalSinceNow
            XCTAssert(interval > 1, "Should have taken more than one second to perform (it took \(interval)")
            XCTAssert(interval < 1.2, "Should have taken less than 1.2 seconds to perform (it took \(interval)")
            
            expectation3.fulfill()
            
            return
        }
        task2.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectations(timeout: 2) { timeoutError in
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
        let expectation1 = self.expectation(description: "Complete called for headers and status code for 1")
        let expectation2 = self.expectation(description: "Complete called for headers and status code for 2")
        let expectation3 = self.expectation(description: "Complete callback called for headers and status code for 2")
        
        // Tell NSURLSession to mock this URL, each time with different data
        let url = URL(string: "https://www.example.com/1")!
        let body = "Test response 1".data(using: String.Encoding.utf8)!
        let request = URLRequest(url: url)
        let headers = ["Content-Type" : "application/test", "Custom-Header" : "Is custom"]
        URLSession.mockNext(request: request, body: body, headers: headers, statusCode: 200)
        URLSession.mockNext(request: request, body: body, headers: headers, statusCode: 200)
        
        // Create a session
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [expectation1, expectation2])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        // Perform task
        let task1 = session.dataTask(with: request)
        task1.resume()
        
        // Perform task
        let task2 = session.dataTask(with: request) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            
            XCTAssertNil(error, "Error in callback")
            
            guard let response = response as? HTTPURLResponse else {
                XCTFail("Response in callback isn't the correct type")
                return
            }
            
            XCTAssertEqual(response.statusCode, 200)
            guard let responseHeaders = response.allHeaderFields as? [String : String] else {
                XCTFail("Response headers  in callback couldn't be transformed to String")
                return
            }
            XCTAssertEqual(responseHeaders, headers)
            
            expectation3.fulfill()
        }
        task2.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectations(timeout: 1) { timeoutError in
            XCTAssertNil(timeoutError)
            
            for task in [task1, task2] {
                XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task.taskIdentifier], body)
                XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task.taskIdentifier], body)
                guard let response = delegate.responseKeyedByTaskIdentifier[task.taskIdentifier] as? HTTPURLResponse else {
                    XCTFail("Response 1 isn't the correct type")
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
    }
    
    func testSession_WithRegularExpression_ShouldMatch() {
        let expectation1 = self.expectation(description: "Complete called for request 1")
        let expectation2 = self.expectation(description: "Complete called for request 2")
        let expectation3 = self.expectation(description: "Complete callback called for request 2")
        
        // Mock with a regex
        let body = "{'mocked':true}".data(using: String.Encoding.utf8)
        try! URLSession.mockEvery(expression: ".*/a.json", body: body)
        
        // Create a session
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        // Perform two tasks
        let request1 = URLRequest(url: URL(string: "http://www.example.com/a.json?param1=1")!)
        let task1 = session.dataTask(with: request1)
        task1.resume()
        
        let request2 = URLRequest(url: URL(string: "http://www.example.com/a.json?param2=2")!)
        let task2 = session.dataTask(with: request2)  { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            
            XCTAssertNil(error, "Error in callback")
            
            XCTAssertEqual(data!, body)
            
            expectation3.fulfill()
            
        }
        task2.resume()
        
        self.waitForExpectations(timeout: 1) { timeoutError in
            // Make sure it was the mock and not a valid response!
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], body)
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], body)
        }
    }
    
    func testSession_WithUnauthorizedRequest_ShouldReturnCanceledTask() {
        let url = URL(string: "http://www.google.com")!
        let request = NSURLRequest(url: url as URL)
        
        // Create a session
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        URLSession.requestEvaluator = { request in
            return .reject
        }
        
        SwiftTryCatch.try({ () -> Void in
            let _ = session.dataTask(with: request as URLRequest)
            }, catch: { (exception: NSException?) -> Void in
                XCTAssertEqual(exception?.name, NSExceptionName(rawValue: "Mocking Exception"))
            }) {}
        
        SwiftTryCatch.try({ () -> Void in
            let _ = session.dataTask(with: request as URLRequest) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in return }
            }, catch: { (exception: NSException?) -> Void in
                XCTAssertEqual(exception?.name, NSExceptionName(rawValue: "Mocking Exception"))
            }) {}
    }

    func testSession_WithBlock_ShouldReturnModifiedData() {
        // Create an expression which will match the product id
        let expression = "http://www.example.com/product/([0-9]{6})"
        try! URLSession.mockEvery(expression: expression) { (url: URL, matches: [String]) in
            return .success(statusCode: 200, headers: [:], body: matches.first!.data(using: String.Encoding.utf8)!)
        }

        // We are going to make two requests, with two different product ids.
        // When the delegate reports them both complete, we will check that the
        // data returned was valid for that specific URL
        let expectation1 = self.expectation(description: "Complete called for request 123456")
        let expectation2 = self.expectation(description: "Complete called for request 654321")
        let expectation3 = self.expectation(description: "Complete callback called for request 654321")

        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())

        // Perform two tasks
        let request1 = URLRequest(url: URL(string: "http://www.example.com/product/123456")!)
        let task1 = session.dataTask(with: request1)
        task1.resume()

        let request2 = URLRequest(url: URL(string: "http://www.example.com/product/654321")!)
        let task2 = session.dataTask(with: request2) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            
            XCTAssertNil(error, "Error in callback")
            
            XCTAssertEqual(data!, "654321".data(using: String.Encoding.utf8))
            
            expectation3.fulfill()
        }
        task2.resume()

        self.waitForExpectations(timeout: 1) { timeoutError in
            // Make sure it was the mock and not a valid response!
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], "123456".data(using: String.Encoding.utf8))
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task2.taskIdentifier], "654321".data(using: String.Encoding.utf8))
        }
    }
    
    func testSession_WithConsumedSingleMock_ShouldBeConsumed() {
        let path = "http://www.example.com/test_path"
        let url = URL(string: path)!
        let request = URLRequest(url: url)
        let handle = URLSession.mockNext(request: request, body: nil)
        
        let expectation1 = self.expectation(description: "Complete called")
        
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        let task = session.dataTask(with: request)
        task.resume()
        
        self.waitForExpectations(timeout: 1) { error in
            let hasConsumed = URLSession.hasMockConsumed(handle: handle)
            XCTAssertTrue(hasConsumed, "The handle should have been consumed")
        }
    }
    
    func testSession_WithNotYetConsumedSingleMock_ShouldNotBeConsumed() {
        // This handle should never be consumed - we're not going to be calling this URL
        let path = "http://www.example.com/test_path"
        let url = URL(string: path)!
        let request = URLRequest(url: url)
        let handle = URLSession.mockNext(request: request, body: nil)
        
        // Mock this url as well so that we don't rely on network traffic to pass the test :)
        let path2 = "http://www.example.com/path_does_not_match"
        let url2 = URL(string: path2)!
        let request2 = URLRequest(url: url2)
        URLSession.mockNext(request: request2, body: nil)
        
        // Sanity - make sure that we aren't going out to the network
        let originalEvaluator = URLSession.requestEvaluator
        URLSession.requestEvaluator = { _ in return .reject }
        
        let expectation1 = self.expectation(description: "Complete called")
        
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())
        
        let testPath = "http://www.example.com/path_does_not_match"
        let testURL = URL(string: testPath)!
        let testRequest = URLRequest(url: testURL)
        let task = session.dataTask(with: testRequest)
        task.resume()
        
        self.waitForExpectations(timeout: 1) { error in
            let hasConsumed = URLSession.hasMockConsumed(handle: handle)
            XCTAssertFalse(hasConsumed, "The handle should not have been consumed")
        }
        
        // Reset the evaluator so we aren't screwing with any other tests
        URLSession.requestEvaluator = originalEvaluator
    }

    func testSession_WithFailureBlock_ShouldReturnError() {
        // Create an expression which will match the product id - if it's 123456 return some data, 
        // if it isn't, return a networking error.
        let expression = "http://www.example.com/product/([0-9]{6})"
        try! URLSession.mockEvery(expression: expression) { (url: URL, matches: [String]) in
            let productID = matches.first!

            if (productID == "123456") {
                return .success(statusCode: 200, headers: [:], body: matches.first!.data(using: String.Encoding.utf8)!)
            } else {
                let error = NSError(domain: "TestErrorDomain", code: 0, userInfo: [ NSLocalizedDescriptionKey: "Request invalid" ])
                return .failure(error: error)
            }
        }

        // We are going to make two requests, with two different product ids.
        // One should return data, the other should fail with an error
        let expectation1 = self.expectation(description: "Complete called for request 123456")
        let expectation2 = self.expectation(description: "Complete called for request 654321")
        let expectation3 = self.expectation(description: "Complete called for request 654321")

        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [ expectation1, expectation2 ])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())

        // Perform two tasks
        let request1 = URLRequest(url: URL(string: "http://www.example.com/product/123456")!)
        let task1 = session.dataTask(with: request1)
        task1.resume()

        let request2 = URLRequest(url: URL(string: "http://www.example.com/product/654321")!)
        let task2 = session.dataTask(with: request2) { (_ data: Data?, _ response: URLResponse?, _ error: Error?) in
            XCTAssertNotNil(error)
            expectation3.fulfill()
        }
        task2.resume()

        self.waitForExpectations(timeout: 1) { timeoutError in
            // Make sure it was the mock and not a valid response!
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task1.taskIdentifier], "123456".data(using: String.Encoding.utf8))
            XCTAssertNil(delegate.errorKeyedByTaskIdentifier[task1.taskIdentifier])
            XCTAssertNotNil(delegate.errorKeyedByTaskIdentifier[task2.taskIdentifier])
        }
    }

    func testSession_WithClearMocks_ShouldClearExistingMocks() {
        let path = "www.example.com/test.json"
        let url = URL(string: path)!
        let request = URLRequest(url: url)

        // Mock every request to a path
        let body1 = "{'mocked':1}".data(using: String.Encoding.utf8)
        URLSession.mockEvery(request: request, body: body1)

        // Clear all the mocks
        URLSession.removeAllMocks()

        // Mock the same request, with a different response
        let body2 = "{'mocked':2}".data(using: String.Encoding.utf8)
        URLSession.mockEvery(request: request, body: body2)

        // Create a session
        let expectation = self.expectation(description: "Request complete")
        let conf = URLSessionConfiguration.default
        let delegate = SessionTestDelegate(expectations: [expectation])
        let session = URLSession(configuration: conf, delegate: delegate, delegateQueue: OperationQueue())

        // Perform task
        let task = session.dataTask(with: request)
        task.resume()

        self.waitForExpectations(timeout: 1) { timeoutError in
            XCTAssertEqual(delegate.dataKeyedByTaskIdentifier[task.taskIdentifier], body2)
        }
    }
}
