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
    
    private let request: NSURLRequest
    private let body: NSData?
    private let delay: Double
    
    init(request: NSURLRequest, body: NSData? = nil, delay: Double) {
        self.request = request
        self.body = body
        self.delay = delay
    }
    
    func matchesRequest(request: NSURLRequest) -> Bool {
        return request.isMockableWith(self.request)
    }
    
    func consumeRequest(request: NSURLRequest, session: NSURLSession) throws -> NSURLSessionDataTask {
        // If this isn't for us, don't produce a task
        guard self.matchesRequest(request) else { throw SessionMockError.InvalidRequest(request: request) }
        
        let task = MockSessionDataTask() { task in
            task._state = .Running
            
            let timeDelta = 0.05
            var time = self.delay
            
            if let delegate = session.delegate as? NSURLSessionDataDelegate {
                if let body = self.body {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        delegate.URLSession?(session, dataTask: task, didReceiveData: body)
                    }
                    
                    time += timeDelta
                }
            }
            
            if let delegate = session.delegate as? NSURLSessionTaskDelegate {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                    task._state = .Completed
                    delegate.URLSession?(session, task: task, didCompleteWithError: nil)
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
