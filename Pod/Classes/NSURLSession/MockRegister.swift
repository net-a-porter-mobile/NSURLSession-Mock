//
//  MockRegister.swift
//  Pods
//
//  Created by Kerr Miller on 04/02/2016.
//
//

import Foundation


class MockRegister<T: SessionMock> {
    
    fileprivate var permanentMocks: [T] = []
    fileprivate var ephemeralMocks: [T] = []
    
    func removeAllMocks() {
        self.permanentMocks.removeAll()
        self.ephemeralMocks.removeAll()
    }
    
    /**
     Adds a mock to the resgister that does not get removed after being returned
    */
    func add(permanent mock: T) {
        self.permanentMocks.append(mock)
    }
    
    /**
     Adds a mock to to the register that will be removed after being returned once
    */
    func add(ephemeral mock: T) {
        self.ephemeralMocks.append(mock)
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    func removeAllMocks(of request: URLRequest) {
        self.permanentMocks = self.permanentMocks.filter {
            return !$0.matches(request: request)
        }
        self.ephemeralMocks = self.ephemeralMocks.filter {
            return !$0.matches(request: request)
        }
    }
    
    /*
    Returns the next mock for the given request. If the next mock is ephemeral, 
    it also removes it from the pool of ephemeral mocks.
    */
    func nextSessionMock(for request: URLRequest) -> SessionMock? {
        let mocksCopy = self.ephemeralMocks
        
        //Ephemeral mocks have precedence over permanent mocks
        for (index, mock) in mocksCopy.enumerated() {
            if mock.matches(request: request) {
                self.ephemeralMocks.remove(at: index)
                return mock
            }
        }
        
        for mock in self.permanentMocks {
            if mock.matches(request: request) {
                return mock
            }
        }
        
        return nil
    }
}


extension MockRegister where T: Equatable {

    /**
     Returns true if this register contains `mock` as an ephemeral mock
     */
    func contains(ephemeral mock: T) -> Bool {
        return self.ephemeralMocks.contains(mock)
    }
}
