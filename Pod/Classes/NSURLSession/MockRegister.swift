//
//  MockRegister.swift
//  Pods
//
//  Created by Kerr Miller on 04/02/2016.
//
//

import Foundation

class MockRegister {
    
    private var mocks: [SessionMock] = []
    
    func removeAllMocks() {
        self.mocks.removeAll()
    }
    
    func addMock(mock: SessionMock) {
        self.mocks.append(mock)
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    func removeAllMocks(of request: NSURLRequest) {
        self.mocks = self.mocks.filter { item in
            return !item.matchesRequest(request)
        }
    }
    
    func nextSessionMockForRequest(request: NSURLRequest) -> SessionMock? {
        for mock in mocks {
            if mock.matchesRequest(request) {
                return mock
            }
        }
        
        return nil
    }
}
