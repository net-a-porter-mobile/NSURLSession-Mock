//
//  MockRegister.swift
//  Pods
//
//  Created by Kerr Miller on 04/02/2016.
//
//

import Foundation

class MockRegister {
    
    private var permanentMocks: [SessionMock] = []
    private var ephemeralMocks: [SessionMock] = []
    
    func removeAllMocks() {
        self.permanentMocks.removeAll()
        self.ephemeralMocks.removeAll()
    }
    
    /**
     Adds a mock to the resgister that does not get removed after being returned
    */
    func addPermanentMock(mock: SessionMock) {
        self.permanentMocks.append(mock)
    }
    
    /**
     Adds a mock to to the register that will be removed after being returned once
    */
    func addEphemeralMock(mock: SessionMock) {
        self.ephemeralMocks.append(mock)
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    func removeAllMocks(of request: NSURLRequest) {
        self.permanentMocks = self.permanentMocks.filter {
            return !$0.matchesRequest(request)
        }
        self.ephemeralMocks = self.ephemeralMocks.filter {
            return !$0.matchesRequest(request)
        }
    }
    
    /*
    Returns the next mock for the given request. If the next mock is ephemeral, 
    it also removes it from the pool of ephemeral mocks.
    */
    func nextSessionMockForRequest(request: NSURLRequest) -> SessionMock? {
        let mocksCopy = self.ephemeralMocks
        
        //Ephemeral mocks have precedence over permanent mocks
        for (index, mock) in mocksCopy.enumerate() {
            if mock.matchesRequest(request) {
                self.ephemeralMocks.removeAtIndex(index)
                return mock
            }
        }
        
        for mock in self.permanentMocks {
            if mock.matchesRequest(request) {
                return mock
            }
        }
        
        return nil
    }
}
