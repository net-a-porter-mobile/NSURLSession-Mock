//
//  CallbackMethodTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 4/18/17.
//  Copyright © 2017 YOOX NET-A-PORTER. All rights reserved.
//

import XCTest

final class CallbackMethodTests: XCTestCase {

    func testSession_WithSingleMock_Callback() {
        let expectation = self.expectation(description: "Callback called back")

        // Make the request we are going to mock
        let url = URL(string: "https://www.example.com")!
        let request = URLRequest(url: url)

        // Tell URLSession to mock this URL
        let body = "Test response 1".data(using: .utf8)!
        URLSession.mockNext(request: request, body: body, delay: 0.25)

        // Create a session
        let session = URLSession(configuration: .default)

        // Perform the task
        let task = session.dataTask(with: request) { data, response, error in
            XCTAssertEqual(data, body)

            expectation.fulfill()
        }
        task.resume()

        // Record the start time
        let start = NSDate()

        self.waitForExpectations(timeout: 0.5) { _ in
            // Check the delay
            let interval = -start.timeIntervalSinceNow
            
            XCTAssert(interval >= 0.25, "Should have taken more than 0.25 second to perform (it took \(interval)")
        }
    }

    func testSession_WithSingleMock_CancelShouldReturnError_Callback() {
        let expectation = self.expectation(description: "Callback called back")
        
        // Make the request we are going to mock
        let url = URL(string: "https://www.example.com")!
        let request = URLRequest(url: url)
        
        // Tell URLSession to mock this URL
        let body = "Test response 1".data(using: .utf8)!
        URLSession.mockNext(request: request, body: body, delay: 2.25)
        
        // Create a session
        let session = URLSession(configuration: .default)
        
        // Perform the task
        let task = session.dataTask(with: request) { data, response, error in
            let cancelledError : NSError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)

            XCTAssertEqual((error as NSError?),  cancelledError)
            
            expectation.fulfill()
        }
        task.resume()
        
        task.cancel()
        
        self.waitForExpectations(timeout: 2.5) { _ in }
    }

}
