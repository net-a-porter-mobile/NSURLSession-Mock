//
//  NSURLSession+Swizzle.swift
//  Pods
//
//  Created by Kerr Miller on 04/02/2016.
//
//

import Foundation

public typealias RequestEvaluator = (NSURLRequest) -> Bool

extension NSURLSession {
    /**
     Set this to output all requests which were mocked to the console
     */
    public static var debugMockRequests: RequestDebugLevel = .None
    
    /**
     Set this to a block that will decide whether or not a request must be mocked.
     */
    public struct Evaluator {
        public static var requestEvaluator: RequestEvaluator = { _ in return true }
    }
    
    
    // MARK: - Swizling
    
    class func swizzleIfNeeded() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            try! swizzle(self, replace: "dataTaskWithRequest:", with: "swizzledDataTaskWithRequest:")
            try! swizzle(self, replace: "dataTaskWithURL:", with: "swizzledDataTaskWithURL:")
            
            Log("NSURLSession now mocked")
        }
    }
    
    // MARK: Swizzled methods
    
    @objc(swizzledDataTaskWithRequest:)
    private func swizzledDataTaskWithRequest(request: NSURLRequest!) -> NSURLSessionDataTask {
        // If any of our mocks match this request, just do that instead
        if let task = taskForRequest(request) {
            
            if NSURLSession.debugMockRequests != .None {
                Log("request: \(request.debugMockDescription) mocked")
            }
            
            return task
        }
        
        guard NSURLSession.Evaluator.requestEvaluator(request) else {
            let exception = NSException(name: "Mocking Exception",
                reason: "Request \(request) was not mocked but is required to be mocked",
                userInfo: [:])
            exception.raise()
            return self.swizzledDataTaskWithRequest(request)
        }
        
        if NSURLSession.debugMockRequests == .All {
            Log("request: \(request.debugMockDescription) not mocked")
        }
        
        // Otherwise, let NSURLSession deal with it
        return swizzledDataTaskWithRequest(request)
    }
    
    @objc(swizzledDataTaskWithURL:)
    private func swizzledDataTaskWithURL(URL: NSURL!) -> NSURLSessionDataTask {
        let request = NSURLRequest(URL: URL)
        if let task = taskForRequest(request) {
            
            if NSURLSession.debugMockRequests != .None {
                Log("request: \(request.debugMockDescription) mocked")
            }
            
            return task
        }
        
        guard NSURLSession.Evaluator.requestEvaluator(request) else {
            let exception = NSException(name: "Mocking Exception",
                reason: "Request \(request) was not mocked but is required to be mocked",
                userInfo: [:])
            exception.raise()
            return self.swizzledDataTaskWithRequest(request)
        }
        
        if NSURLSession.debugMockRequests == .All {
            Log("request: \(request.debugMockDescription) not mocked")
        }
        
        // Otherwise, let NSURLSession deal with it
        return swizzledDataTaskWithURL(URL)
    }
    
    // MARK: - Helpers
    
    private func taskForRequest(request: NSURLRequest) -> NSURLSessionDataTask? {
        if let mock = NSURLSession.register.nextSessionMockForRequest(request) {
            return try! mock.consumeRequest(request, session: self)
            
        }
        return nil
    }
}
