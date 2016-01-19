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
    
    public class func mockSingle(request: NSURLRequest, body: NSData?) {
        mocks.append(SuccessSessionMock(request: request, body: body))
        
        swizzleIfNeeded()
    }
    
    public class func removeAllMocks() {
        mocks.removeAll()
    }
    
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
    
    // MARK: - Swizzled methods
    
    @objc(swizzledDataTaskWithRequest:)
    public func swizzledDataTaskWithRequest(request: NSURLRequest!) -> NSURLSessionDataTask {
        // If any of our mocks match this request, just do that instead
        if let task = nextSessionMockWithRequest(request) {
            return task
        }
        
        print("Attempted, but failed, to match mock (request: \(request))")
        
        // Otherwise, super
        return swizzledDataTaskWithRequest(request)
    }
    
    @objc(swizzledDataTaskWithURL:)
    public func swizzledDataTaskWithURL(URL: NSURL!) -> NSURLSessionDataTask {
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
        for var mock in mocks {
            if let task = mock.consumeRequest(request, session: self) {
                return task
            }
        }
        
        return nil
    }
}
