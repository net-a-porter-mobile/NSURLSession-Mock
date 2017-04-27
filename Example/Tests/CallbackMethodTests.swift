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
        URLSession.mockNext(request: request, body: body)

        // Create a session
        let session = URLSession(configuration: .default)

        // Perform the task
        let task = session.dataTask(with: request) { data, response, error in
            XCTAssertEqual(data, body)

            expectation.fulfill()
        }
        task.resume()

        self.waitForExpectations(timeout: 0.1) { _ in }
    }
}
