//
//  NSURLSession+Mock.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

private var mocks: Array<SessionMock> = Array()

extension NSURLSession {
    
    /**
     The next call matching `request` will successfully return `body`
     
     - parameter request: The request to mock
     - parameter body: The data to return in the callback. If this is `nil` then the didRecieveData callback won't be called.
     */
    public class func mockSingle(request: NSURLRequest, body: NSData?, delay: Double = DefaultDelay) {
        mocks.append(SingleSuccessSessionMock(request: request, body: body, delay: delay))
        
        swizzleIfNeeded()
    }
    
    /**
     All calls matching `request` will successfully return `body`
     
     - parameter request: The request to mock
     - parameter body: The data to return in the callback. If this is `nil` then the didRecieveData callback won't be called.
     */
    public class func mockEvery(request: NSURLRequest, body: NSData?, delay: Double = DefaultDelay) {
        mocks.append(SuccessSessionMock(request: request, body: body, delay: delay))
        
        swizzleIfNeeded()
    }
    
    /**
     Remove all mocks - NSURLSession will behave as if it had never been touched
     */
    public class func removeAllMocks() {
        mocks.removeAll()
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    public class func removeAllMocks(of request: NSURLRequest) {
        mocks = mocks.filter { (item) -> Bool in
            return !item.matchesRequest(request)
        }
    }
    
    // MARK: - Swizling
    
    private class func swizzleIfNeeded() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            try! swizzle(self, replace: "dataTaskWithRequest:", with: "swizzledDataTaskWithRequest:")
            try! swizzle(self, replace: "dataTaskWithURL:", with: "swizzledDataTaskWithURL:")
            
            print("NSURLSession now mocked")
        }
    }
    
    // MARK: Swizzled methods
    
    @objc(swizzledDataTaskWithRequest:)
    private func swizzledDataTaskWithRequest(request: NSURLRequest!) -> NSURLSessionDataTask {
        // If any of our mocks match this request, just do that instead
        if let task = nextSessionMockWithRequest(request) {
            return task
        }
        
        print("Attempted, but failed, to match mock (request: \(request))")
        
        // Otherwise, super
        return swizzledDataTaskWithRequest(request)
    }
    
    @objc(swizzledDataTaskWithURL:)
    private func swizzledDataTaskWithURL(URL: NSURL!) -> NSURLSessionDataTask {
        let request = NSURLRequest(URL: URL)
        if let task = nextSessionMockWithRequest(request) {
            return task
        }
        
        // If any of our mocks match this request, just do that instead
        print("Attempted, but failed, to match mock (URL: \(URL))")
        
        // Otherwise, super
        return swizzledDataTaskWithURL(URL)
    }
    
    // MARK: - Helpers
    
    private func nextSessionMockWithRequest(request: NSURLRequest) -> NSURLSessionDataTask? {
        for mock in mocks {
            if let task = mock.consumeRequest(request, session: self) {
                return task
            }
        }
        
        return nil
    }
}
