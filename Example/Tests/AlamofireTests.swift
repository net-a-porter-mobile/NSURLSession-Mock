//
//  AlamofireTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 19/01/2016.
//  Copyright © 2016 YOOX NET-A-PORTER. All rights reserved.
//

import XCTest

import NSURLSession_Mock

import Alamofire

final class AlamofireTests: XCTestCase {
    
    override func tearDown() {
        URLSession.removeAllMocks()

        super.tearDown()
    }

    func testAlamofire_WithSessionMockGET_WorksTogether() {
        let expectation = self.expectation(description: "Success completion block called")
        
        let url = URL(string: "https://www.example.com/1")!
        let body = "{ \"data\": \"1\" }".data(using: String.Encoding.utf8)!
        let request = URLRequest(url: url)
        let headers = [ "Content-Type" : "application/json"]
        URLSession.mockNext(request: request, body: body, headers: headers)

        let manager = Session()

        manager.request(url).responseJSON { response in
            switch response.result {
            case .success(let dictionary as [String: String]):
                XCTAssertEqual(dictionary, [ "data": "1" ])
            case .success(let value):
                XCTFail("Invalid response: \(value)")
            case .failure(let error):
                XCTFail("Should have been success, got \(error) instead.")
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testAFNetworking_WithSessionMockPOST_WorksTogether() {
        let expectation = self.expectation(description: "Success completion block called")
        
        let url = URL(string: "https://www.example.com/2")!
        let body = "{ \"data\": \"2\" }".data(using: String.Encoding.utf8)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let headers = [ "Content-Type" : "application/json"]
        URLSession.mockNext(request: request, body: body, headers: headers)
        
        let manager = Session()
        
        manager.request(url, method: .post).responseJSON { response in
            switch response.result {
            case .success(let dictionary as [String: String]):
                XCTAssertEqual(dictionary, [ "data": "2" ])
            case .success(let value):
                XCTFail("Invalid response: \(value)")
            case .failure(let error):
                XCTFail("Should have been success, got \(error) instead.")
            }

            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }
}
