//
//  MockEntry.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation


private let mult = Double(NSEC_PER_SEC)


class MockEntry: SessionMock, Equatable {
    private let requestMatcher: RequestMatcher
    private let response: MockResponseHandler
    private let delay: Double
    
    init(matching requestMatcher: RequestMatcher, response: @escaping MockResponseHandler, delay: Double) {
        self.requestMatcher = requestMatcher
        self.response = response
        self.delay = delay
    }
    
    func matches(request: URLRequest) -> Bool {
        switch(self.requestMatcher.matches(request: request)) {
        case .matches: return true
        case .noMatch: return false
        }
    }
    
    func consume(request: URLRequest, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?, session: URLSession) throws -> URLSessionDataTask {

        switch (self.requestMatcher.matches(request: request)) {

        // If this isn't for us, we shouldn't have been called, throw and let
        // everyone know!
        case .noMatch:
            throw SessionMockError.invalidRequest(request: request)

        // Use the extractions from the match to create the data
        case .matches(let extractions):
            let task = MockSessionDataTask() { task in

                let response = self.response(request.url!, extractions)

                switch(response) {
                case let .success(statusCode, headers, body):
                    task.scheduleMockedResponsesWith(request: request, session: session, delay: self.delay, statusCode: statusCode, headers: headers, body: body, completionHandler: completionHandler)

                case let .failure(error):
                    task.scheduleMockedResponsesWith(request: request, session: session, delay: self.delay, error: error, completionHandler: completionHandler)
                }
            }
            
            
            return task
        }
    }
    
}

func ==(lhs: MockEntry, rhs: MockEntry) -> Bool {
    return lhs === rhs
}
