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
    
    func testSession_WithSingleMock_ShouldReturnMockData() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock this URL
        let URL = NSURL(string: "https://www.example.com/1")!
        let body = "Test response".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURLRequest.init(URL: URL)
        NSURLSession.mockSingle(request, body: body)
        
        class TestDelegate: NSObject, NSURLSessionDataDelegate {
            let expectation: XCTestExpectation
            var data: NSMutableData?
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData recievedData: NSData) {
                if data == nil {
                    data = NSMutableData()
                }
                
                data!.appendData(recievedData)
            }
            
            @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
                expectation.fulfill()
            }
        }
        
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate = TestDelegate(expectation: expectation)
        let session = NSURLSession(configuration: conf, delegate: delegate, delegateQueue: NSOperationQueue())
        
        let task = session.dataTaskWithRequest(request)
        task.resume()
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(1) { timeoutError in
            XCTAssertNil(timeoutError)
            
            XCTAssertEqual(delegate.data, body)
        }
    }
    
}
