//
//  AFNetworkingTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 19/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

import NSURLSession_Mock

import AFNetworking

class AFNetworkingTests: XCTestCase {
    
    override func tearDown() {
        URLSession.removeAllMocks()
    }

    func testAFNetworking_WithSessionMockGET_WorksTogether() {
        let expectation = self.expectation(description: "Success completion block called")
        
        let url = URL(string: "https://www.example.com/1")!
        let body = "{ \"data\": 1 }".data(using: String.Encoding.utf8)!
        let request = URLRequest(url: url)
        let headers = [ "Content-Type" : "application/json"]
        URLSession.mockNext(request: request, body: body, headers: headers)

        let manager = AFHTTPSessionManager()
        
        manager.get(url.absoluteString, parameters: nil, success: { (task, response) -> Void in
            
            XCTAssertEqual(response as? NSDictionary, [ "data": 1 ])
            
            expectation.fulfill()
        }) { (task, error) -> Void in
            XCTFail("This shouldn't return an error")
        }
        
        self.waitForExpectations(timeout: 1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testAFNetworking_WithSessionMockPOST_WorksTogether() {
        let expectation = self.expectation(description: "Success completion block called")
        
        let url = URL(string: "https://www.example.com/2")!
        let body = "{ \"data\": 2 }".data(using: String.Encoding.utf8)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let headers = [ "Content-Type" : "application/json"]
        URLSession.mockNext(request: request, body: body, headers: headers)
        
        let manager = AFHTTPSessionManager()
        
        manager.post(url.absoluteString, parameters: nil, success: { (task, response) -> Void in
            
            XCTAssertEqual(response as? NSDictionary, [ "data": 2 ])
            
            expectation.fulfill()
            }) { (task, error) -> Void in
                XCTFail("This shouldn't return an error")
        }
        
        self.waitForExpectations(timeout: 1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

}
