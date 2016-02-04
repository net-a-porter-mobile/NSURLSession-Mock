//
//  MockRegister.swift
//  Pods
//
//  Created by Kerr Miller on 04/02/2016.
//
//

import Foundation

internal class MockRegister {
    
    private var mocks: [SessionMock] = []
    
    internal func removeAllMocks() {
        self.mocks.removeAll()
    }
    
    internal func addMock(mock: SessionMock) {
        self.mocks.append(mock)
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    internal func removeAllMocks(of request: NSURLRequest) {
        self.mocks = self.mocks.filter { item in
            return !item.matchesRequest(request)
        }
    }
    
    internal func nextSessionMockForRequest(request: NSURLRequest) -> SessionMock? {
        for mock in mocks {
            if mock.matchesRequest(request) {
                return mock
            }
        }
        
        return nil
    }
}