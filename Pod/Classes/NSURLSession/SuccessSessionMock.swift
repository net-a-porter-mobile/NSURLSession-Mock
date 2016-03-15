//
//  SuccessSessionMock.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

private let mult = Double(NSEC_PER_SEC)

class SuccessSessionMock : SessionMock {
    
    private let requestMatcher: RequestMatcher
    private let response: MockResponse
    private let delay: Double
    
    init(matching requestMatcher: RequestMatcher, response: MockResponse, delay: Double) {
        self.requestMatcher = requestMatcher
        self.response = response
        self.delay = delay
    }
    
    func matchesRequest(request: NSURLRequest) -> Bool {
        return requestMatcher.matches(request)
    }
    
    func consumeRequest(request: NSURLRequest, session: NSURLSession) throws -> NSURLSessionDataTask {
        // If this isn't for us, don't produce a task
        guard self.matchesRequest(request) else { throw SessionMockError.InvalidRequest(request: request) }
        
        let task = MockSessionDataTask() { task in
            task._state = .Running
            
            let timeDelta = 0.02
            var time = self.delay
            
            if let delegate = session.delegate as? NSURLSessionDataDelegate {
                
                if let body = self.response.data {
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: self.response.statusCode, HTTPVersion: "HTTP/1.1", headerFields: self.response.headers)!
                        task.response = response
                        delegate.URLSession?(session, dataTask: task, didReceiveResponse: response) { _ in }
                    }
                    
                    time += timeDelta
                        
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        delegate.URLSession?(session, dataTask: task, didReceiveData: body)
                    }
                    
                    time += timeDelta
                }
            }
            
            if let delegate = session.delegate as? NSURLSessionTaskDelegate {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                    delegate.URLSession?(session, task: task, didCompleteWithError: nil)
                    task._state = .Completed
                }
            }
        }
        
        task._originalRequest = request
        
        return task
    }
    
}

class SingleSuccessSessionMock : SuccessSessionMock {
    
    var canRun = true
    
    override func matchesRequest(request: NSURLRequest) -> Bool {
        return canRun && super.matchesRequest(request)
    }
    
    override func consumeRequest(request: NSURLRequest, session: NSURLSession) throws -> NSURLSessionDataTask {
        guard self.matchesRequest(request) else { throw SessionMockError.InvalidRequest(request: request) }
        
        guard canRun else { throw SessionMockError.HasAlreadyRun }
        
        let task = try super.consumeRequest(request, session: session)
        
        canRun = false
        
        return task
    }
    
}
