//
//  NSURLSessionTests.swift
//  NSURLConnection-Mock
//
//  Created by Sam Dean on 18/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

import NSURLConnection_Mock

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
        
        class TestDelegate: NSObject, NSURLSessionDataDelegate {
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
        
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = TestDelegate(expectations: [ expectation1, expectation2 ])
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
    
}
