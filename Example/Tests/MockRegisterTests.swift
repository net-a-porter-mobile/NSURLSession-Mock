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


    func testMockRegister_WithPermanentTestMock_ShouldReturnTestMockWithCorrectURL() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addPermanentMock(mock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNotNil(returnedMock)
    }
    
    func testMockRegister_WithEphemeralTestMock_ShouldReturnTestMockWithCorrectURL() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addEphemeralMock(mock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNotNil(returnedMock)
    }
    
    func testMockRegister_WithRemoveAll_ShouldNotReturnAnyMocks() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addPermanentMock(mock)
        register.addEphemeralMock(mock)
        
        register.removeAllMocks()
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNil(returnedMock)
    }
    
    func testMockRegister_WithTestMockThatDoesntMatchRequest_ShouldReturnNil() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        
        register.addPermanentMock(mock)
        register.addEphemeralMock(mock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com")!)
        let returnedMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNil(returnedMock)
    }
    
    func testMockRegister_WithPermanentMockRemovingCertainRequests_ShouldFilterOut() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        let permanent = TestSessionMock(requestString: "shouldstillbethere")
        
        register.addPermanentMock(mock)
        register.addPermanentMock(permanent)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let permanentRequest = NSURLRequest(URL: NSURL(string: "http://www.example.com/shouldstillbethere")!)
        
        register.removeAllMocks(of: request)
        
        let permanentMock = register.nextSessionMockForRequest(permanentRequest)
        let fleetingMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNotNil(permanentMock)
        XCTAssertNil(fleetingMock)
    }
    
    func testMockRegister_WithEphemeralMockRemovingCertainRequests_ShouldFilterOut() {
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "test")
        let permanent = TestSessionMock(requestString: "shouldstillbethere")
        
        register.addEphemeralMock(mock)
        register.addEphemeralMock(permanent)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let permanentRequest = NSURLRequest(URL: NSURL(string: "http://www.example.com/shouldstillbethere")!)
        
        register.removeAllMocks(of: request)
        
        let permanentMock = register.nextSessionMockForRequest(permanentRequest)
        let fleetingMock = register.nextSessionMockForRequest(request)
        
        XCTAssertNotNil(permanentMock)
        XCTAssertNil(fleetingMock)
    }
    
    func testMockRegister_WithEphemeralMock_ShouldRemoveAfterReturning() {
        
        class TestEphemeralMock : SessionMock {
            var runsOnce = true
            let requestString : String
            
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
        let register = MockRegister()
        let mock = TestEphemeralMock(requestString: "test")
        
        register.addEphemeralMock(mock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        let notNilMock = register.nextSessionMockForRequest(request)
        let nilMock = register.nextSessionMockForRequest(request)
        XCTAssertNil(nilMock)
        XCTAssertNotNil(notNilMock)
    }
    
    func testMockRegister_WithEphemeralAndPermanentMock_ShouldPrioritizeEphemeralMock() {
        
        let register = MockRegister()
        let mock = TestSessionMock(requestString: "example.com/test")
        let permanentMock = TestSessionMock(requestString: "test")
        let secondPermanentMock = TestSessionMock(requestString: "test")
        
        register.addPermanentMock(permanentMock)
        register.addEphemeralMock(mock)
        register.addPermanentMock(secondPermanentMock)
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.example.com/test")!)
        guard let ephemeral = register.nextSessionMockForRequest(request) as? TestSessionMock else {
            XCTFail("Could not get ephemeral mock")
            return
        }
        
        
        XCTAssertNotNil(ephemeral)
        XCTAssertEqual(ephemeral.requestString, "example.com/test")
    }
}

