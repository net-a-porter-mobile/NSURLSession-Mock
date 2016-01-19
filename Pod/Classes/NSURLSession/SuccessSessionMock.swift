//
//  SuccessSessionMock.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

private let DefaultDelay = 0.25

private let mult = Double(NSEC_PER_SEC)

class SuccessSessionMock : SessionMock {
    
    private let request: NSURLRequest
    private let body: NSData?
    
    init(request: NSURLRequest, body: NSData? = nil) {
        self.request = request
        self.body = body
    }
    
    func matchesRequest(request: NSURLRequest) -> Bool {
        return request.isMockableWith(self.request)
    }
    
    func consumeRequest(request: NSURLRequest, session: NSURLSession) -> NSURLSessionDataTask? {
        // If this isn't for us, don't produce a task
        guard self.matchesRequest(request) else { return nil }
        
        let task = MockSessionDataTask() { task in
            task._state = .Running
            
            var time = DefaultDelay
            
            if let delegate = session.delegate as? NSURLSessionDataDelegate {
                if let body = self.body {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        delegate.URLSession?(session, dataTask: task, didReceiveData: body)
                    }
                    
                    time += DefaultDelay
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
    
    override func consumeRequest(request: NSURLRequest, session: NSURLSession) -> NSURLSessionDataTask? {
        guard self.matchesRequest(request) else { return nil }
        
        guard canRun else { return nil }
        canRun = false
        
        return super.consumeRequest(request, session: session)
    }
    
}
