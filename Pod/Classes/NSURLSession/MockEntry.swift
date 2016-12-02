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
    
    func consume(request: URLRequest, session: URLSession, with completionHandler:@escaping TaskCompletionHandler) throws -> URLSessionDataTask {
        
        switch (self.requestMatcher.matches(request: request)) {

        // If this isn't for us, we shouldn't have been called, throw and let
        // everyone know!
        case .noMatch:
            throw SessionMockError.invalidRequest(request: request)

        // Use the extractions from the match to create the data
        case .matches(let extractions):
            let task = MockSessionDataTask() { task in
                task._state = .running

                let response = self.response(request.url!, extractions)
                switch(response) {
                case let .success(statusCode, headers, body):
                    self.respondWith(request: request, session: session, task: task, statusCode: statusCode, headers: headers, body: body, with: completionHandler)

                case let .failure(error):
                    self.respondWith(request: request, session: session, task: task, error: error, with: completionHandler)
                }
            }
            
            task._originalRequest = request
            
            return task
        }
    }

    private func respondWith(request: URLRequest, session: URLSession, task: MockSessionDataTask, statusCode: Int, headers: [String:String], body: Data?, with completionHandler:@escaping TaskCompletionHandler) {
        let timeDelta = 0.02
        var time = self.delay

        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
        
        if let delegate = session.delegate as? URLSessionDataDelegate {
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                task.response = response
                
                delegate.urlSession?(session, dataTask: task, didReceive: response) { _ in }
            }

            time += timeDelta

            if let body = body {

                DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                    delegate.urlSession?(session, dataTask: task, didReceive: body)
                }

                time += timeDelta
            }
        }

        if let delegate = session.delegate as? URLSessionTaskDelegate {

            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                delegate.urlSession?(session, task: task, didCompleteWithError: nil)
                task._state = .completed
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            completionHandler(body, response, nil)
        }

    }

    private func respondWith(request: URLRequest, session: URLSession, task: MockSessionDataTask, error: NSError, with completionHandler:@escaping TaskCompletionHandler) {
        if let delegate = session.delegate as? URLSessionTaskDelegate {

            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                delegate.urlSession?(session, task: task, didCompleteWithError: error)
                completionHandler(nil, nil, error)
                task._state = .completed
            }
        }
    }
}


func ==(lhs: MockEntry, rhs: MockEntry) -> Bool {
    return lhs === rhs
}
