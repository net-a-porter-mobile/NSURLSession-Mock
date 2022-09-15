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

    /// Async queue using a barrier to ensure a reader/writer lock
    private let asyncQueue = DispatchQueue(label: "MockQueue", attributes: .concurrent, target: nil)

    func removeAllMocks() {
        asyncQueue.async( flags: .barrier ) {
            self.permanentMocks.removeAll()
            self.ephemeralMocks.removeAll()
        }
    }
    
    /**
     Adds a mock to the resgister that does not get removed after being returned
    */
    func add(permanent mock: T) {
        asyncQueue.async( flags: .barrier ) {
            self.permanentMocks.append(mock)
        }
    }
    
    /**
     Adds a mock to to the register that will be removed after being returned once
    */
    func add(ephemeral mock: T) {
        asyncQueue.async( flags: .barrier ) {
            self.ephemeralMocks.append(mock)
        }
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    func removeAllMocks(of request: URLRequest) {
        asyncQueue.async( flags: .barrier ) {
            self.permanentMocks = self.permanentMocks.filter {
                return !$0.matches(request: request)
            }
            self.ephemeralMocks = self.ephemeralMocks.filter {
                return !$0.matches(request: request)
            }
        }

    }
    
    /*
    Returns the next mock for the given request. If the next mock is ephemeral, 
    it also removes it from the pool of ephemeral mocks.
    */
    func nextSessionMock(for request: URLRequest) -> SessionMock? {

        var result: SessionMock? = nil
        asyncQueue.sync( flags: .barrier ) {

            //Ephemeral mocks have precedence over permanent mocks
            for (index, mock) in self.ephemeralMocks.enumerated() {
                if mock.matches(request: request) {
                    self.ephemeralMocks.remove(at: index)
                    result = mock
                    break
                }
            }

            if result == nil {
                for mock in self.permanentMocks {
                    if mock.matches(request: request) {
                        result = mock
                        break
                    }
                }
            }
        }

        return result
    }
}


extension MockRegister where T: Equatable {

    /**
     Returns true if this register contains `mock` as an ephemeral mock
     */
    func contains(ephemeral mock: T) -> Bool {
        var result: Bool = false
        asyncQueue.sync {
            result =  self.ephemeralMocks.contains(mock)
        }
        return result
    }
}
