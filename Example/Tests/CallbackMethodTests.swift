//
//  CallbackMethodTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 4/18/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest

final class CallbackMethodTests: XCTestCase {

    func testSession_WithSingleMock_Callback() {
        let expectation = self.expectation(description: "Callback called back")

        // Tell NSURLSession to mock this URL, each time with different data
        let url = URL(string: "https://www.example.com")!
        let body = "Test response 1".data(using: String.Encoding.utf8)!
        let request = URLRequest(url: url)
        _ = URLSession.mockNext(request: request, body: body)

        // Create a session
        let conf = URLSessionConfiguration.default
        let session = URLSession(configuration: conf)

        // Perform the task
        let task = session.dataTask(with: request) { data, response, error in
            XCTAssertEqual(data, body)

            if (data != nil) {
                let str = String(data: data!, encoding: .utf8)
                if (str != nil) {
                    print(str!)
                }
            }

            expectation.fulfill()
        }
        task.resume()

        self.waitForExpectations(timeout: 10.1) { _ in }
    }
}
