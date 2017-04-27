//
//  MockRegisterTests.swift
//  NSURLSession-Mock
//
//  Created by Kerr Miller on 04/02/2016.
//  Copyright © 2016 YOOX NET-A-PORTER. All rights reserved.
//

import XCTest

@testable import NSURLSession_Mock

class TestSessionMock: SessionMock, Equatable {
    let requestString: String
    
    var canMatchRequests: Bool { return true }
    
    init(requestString: String) {
        self.requestString = requestString
    }
    
    func matches(request: URLRequest) -> Bool {
        return (request.url?.absoluteString.contains(requestString))!
    }
    
    func consume(request: URLRequest, completionHandler: ( (Data?, URLResponse?, Error?) -> Void )?, session: URLSession) throws -> URLSessionDataTask {
        return URLSessionDataTask()
    }
}

func ==(lhs: TestSessionMock, rhs: TestSessionMock) -> Bool {
    return lhs === rhs
}


class MockRegisterTests: XCTestCase {
    
    func testMockRegister_WithPermanentTestMock_ShouldReturnTestMockWithCorrectURL() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "test")
        
        register.add(permanent: mock)
        
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMock(for: request)
        
        XCTAssertNotNil(returnedMock)
    }
    
    func testMockRegister_WithEphemeralTestMock_ShouldReturnTestMockWithCorrectURL() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "test")
        
        register.add(ephemeral: mock)
        
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMock(for: request)
        
        XCTAssertNotNil(returnedMock)
    }
    
    func testMockRegister_WithRemoveAll_ShouldNotReturnAnyMocks() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "test")
        
        register.add(permanent: mock)
        register.add(ephemeral: mock)
        
        register.removeAllMocks()
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        let returnedMock = register.nextSessionMock(for: request)
        
        XCTAssertNil(returnedMock)
    }
    
    func testMockRegister_WithTestMockThatDoesntMatchRequest_ShouldReturnNil() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "test")
        
        register.add(permanent: mock)
        register.add(ephemeral: mock)
        
        let request = URLRequest(url: URL(string: "http://www.example.com")!)
        let returnedMock = register.nextSessionMock(for: request)
        
        XCTAssertNil(returnedMock)
    }
    
    func testMockRegister_WithPermanentMockRemovingCertainRequests_ShouldFilterOut() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "test")
        let permanent = TestSessionMock(requestString: "shouldstillbethere")
        
        register.add(permanent: mock)
        register.add(permanent: permanent)
        
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        let permanentRequest = URLRequest(url: URL(string: "http://www.example.com/shouldstillbethere")!)
        
        register.removeAllMocks(of: request)
        
        let permanentMock = register.nextSessionMock(for: permanentRequest)
        let fleetingMock = register.nextSessionMock(for: request)
        
        XCTAssertNotNil(permanentMock)
        XCTAssertNil(fleetingMock)
    }
    
    func testMockRegister_WithEphemeralMockRemovingCertainRequests_ShouldFilterOut() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "test")
        let permanent = TestSessionMock(requestString: "shouldstillbethere")
        
        register.add(ephemeral: mock)
        register.add(ephemeral: permanent)
        
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        let permanentRequest = URLRequest(url: URL(string: "http://www.example.com/shouldstillbethere")!)
        
        register.removeAllMocks(of: request)
        
        let permanentMock = register.nextSessionMock(for: permanentRequest)
        let fleetingMock = register.nextSessionMock(for: request)
        
        XCTAssertNotNil(permanentMock)
        XCTAssertNil(fleetingMock)
    }
    
    func testMockRegister_WithEphemeralMock_ShouldRemoveAfterReturning() {
        
        class TestEphemeralMock: SessionMock {
            var runsOnce = true
            let requestString: String
            
            init(requestString: String) {
                self.requestString = requestString
            }
            
            func matches(request: URLRequest) -> Bool {
                return (request.url?.absoluteString.contains(requestString))!
            }
            
            func consume(request: URLRequest, completionHandler: ( (Data?, URLResponse?, Error?) -> Void )?, session: URLSession) throws -> URLSessionDataTask {
                return URLSessionDataTask()
            }
        }
        let register = MockRegister<TestEphemeralMock>()
        let mock = TestEphemeralMock(requestString: "test")
        
        register.add(ephemeral: mock)
        
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        let notNilMock = register.nextSessionMock(for: request)
        let nilMock = register.nextSessionMock(for: request)
        XCTAssertNil(nilMock)
        XCTAssertNotNil(notNilMock)
    }
    
    func testMockRegister_WithEphemeralAndPermanentMock_ShouldPrioritizeEphemeralMock() {
        
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "example.com/test")
        let permanentMock = TestSessionMock(requestString: "test")
        let secondPermanentMock = TestSessionMock(requestString: "test")
        
        register.add(permanent: permanentMock)
        register.add(ephemeral: mock)
        register.add(permanent: secondPermanentMock)
        
        let request = URLRequest(url: URL(string: "http://www.example.com/test")!)
        guard let ephemeral = register.nextSessionMock(for: request) as? TestSessionMock else {
            XCTFail("Could not get ephemeral mock")
            return
        }
        
        XCTAssertNotNil(ephemeral)
        XCTAssertEqual(ephemeral.requestString, "example.com/test")
    }
    
    func testMockRegister_WithEquatableMock_ShouldContainEphemeralMock() {
        let register = MockRegister<TestSessionMock>()
        let mock1 = TestSessionMock(requestString: "example.com/test1")
        let mock2 = TestSessionMock(requestString: "example.com/test2")
        register.add(ephemeral: mock1)
        register.add(permanent: mock2)
        
        XCTAssertTrue(register.contains(ephemeral: mock1))
        XCTAssertFalse(register.contains(ephemeral: mock2))
    }
    
    func testMockRegister_WithConsumedMock_ShouldNotContainMock() {
        let register = MockRegister<TestSessionMock>()
        let mock = TestSessionMock(requestString: "example.com/test1")
        register.add(ephemeral: mock)

        // Consume the mock again
        _ = register.nextSessionMock(for: URLRequest(url: URL(string: mock.requestString)!))
        XCTAssertFalse(register.contains(ephemeral: mock))
        
        // Make sure it's not still contained in the register
        XCTAssertFalse(register.contains(ephemeral: mock))
    }
}
