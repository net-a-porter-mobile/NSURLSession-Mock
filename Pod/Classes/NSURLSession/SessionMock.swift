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
    For a given request, this method will return a data task if it matches,
    otherwise it will return `nil`
    */
    mutating func consumeRequest(request: NSURLRequest, session: NSURLSession) -> NSURLSessionDataTask?
    
}
