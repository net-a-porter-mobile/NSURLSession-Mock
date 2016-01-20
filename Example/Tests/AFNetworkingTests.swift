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
        NSURLSession.removeAllMocks()
    }

    func testAFNetworking_WithSessionMockGET_WorksTogether() {
        let expectation = self.expectationWithDescription("Success completion block called")
        
        let URL = NSURL(string: "https://www.example.com/1")!
        let body = "{ \"data\": 1 }".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSURLRequest.init(URL: URL)
        NSURLSession.mockSingle(request, body: body)

        let manager = AFHTTPSessionManager()
        
        manager.GET(URL.absoluteString, parameters: nil, success: { (task, response) -> Void in
            
            XCTAssertEqual(response as? NSDictionary, [ "data": 1 ])
            
            expectation.fulfill()
        }) { (task, error) -> Void in
            XCTFail("This shouldn't return an error")
        }
        
        self.waitForExpectationsWithTimeout(1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testAFNetworking_WithSessionMockPOST_WorksTogether() {
        let expectation = self.expectationWithDescription("Success completion block called")
        
        let URL = NSURL(string: "https://www.example.com/2")!
        let body = "{ \"data\": 2 }".dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSMutableURLRequest.init(URL: URL)
        request.HTTPMethod = "POST"
        NSURLSession.mockSingle(request, body: body)
        
        let manager = AFHTTPSessionManager()
        
        manager.POST(URL.absoluteString, parameters: nil, success: { (task, response) -> Void in
            
            XCTAssertEqual(response as? NSDictionary, [ "data": 2 ])
            
            expectation.fulfill()
            }) { (task, error) -> Void in
                XCTFail("This shouldn't return an error")
        }
        
        self.waitForExpectationsWithTimeout(1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

}
