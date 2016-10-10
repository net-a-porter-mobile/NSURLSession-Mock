//
//  SessionMock.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

/**
 Protocol implemented by all recorded mocks for a session
*/
protocol SessionMock {
    
    /**
     For a given request, return `true` if this mock matches it (i.e. will return
     a data task from `consumeRequest(request:session:)`.
     */
    func matches(request: URLRequest) -> Bool
    
    /**
     For a given request, this method will return a data task. This method will
     throw if it's asked to consume a request that it doesn't match
    */
    func consume(request: URLRequest, session: URLSession) throws -> URLSessionDataTask
}


enum SessionMockError: Error {
    case invalidRequest(request: URLRequest)
    case hasAlreadyRun
}


/**
A default delay to use when mocking requests
*/
var DefaultDelay: Double = 0.25
