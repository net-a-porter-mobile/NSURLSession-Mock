//
//  MockRegisterTests.swift
//  NSURLSession-Mock
//
//  Created by Kerr Miller on 04/02/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

@testable import NSURLSession_Mock

class MockRegisterTests: XCTestCase {
    
    class TestSessionMock : SessionMock {
        
        let requestString : String
        
        var canMatchRequests: Bool { return true }
        
        init(requestString: String) {
            self.requestString = requestString
        }
        
        func matchesRequest(request: NSURLRequest) -> Bool {
            return (request.URL?.absoluteString.containsString(requestString))!
        }
        
        func consumeRequest(request: NSURLRequest, session: NSURLSession) throws -> NSURLSessionDataTask {
            return NSURLSessionDataTask()
        }
    }

    func testMockRegister_WithTestMock_ShouldReturnTestMockWithCorrectURL() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addMock(mock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNotNil(returnedMock)
    }
    
    func testMockRegister_WithRemoveAll_ShouldNotReturnAnyMocks() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addMock(mock)
        
        register.removeAllMocks()
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNil(returnedMock)
    }
    
    func testMockRegister_WithTestMockThatDoesntMatchRequest_ShouldReturnNil() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addMock(mock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNil(returnedMock)
    }
    
    func testMockRegister_WithRemovingCertainRequests_ShouldFilterOut() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        let permanent = TestSessionMock(requestString: "shouldstillbethere")
        
        register.addMock(mock)
        register.addMock(permanent)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let permanentRequest = NSURLRequest(URL: NSURL(string: "http://www.example.com/shouldstillbethere")!)
        
        register.removeAllMocks(of: request)
        
        let permanentMock = register.nextSessionMockForRequest(permanentRequest)
        let fleetingMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNotNil(permanentMock)
        XCTAssertNil(fleetingMock)
    }
}

