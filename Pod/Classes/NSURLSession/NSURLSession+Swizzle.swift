//
//  NSURLSession+Swizzle.swift
//  Pods
//
//  Created by Kerr Miller on 04/02/2016.
//
//

import Foundation


public enum EvaluationResult {
    case passThrough
    case reject
}


public typealias RequestEvaluator = (URLRequest) -> EvaluationResult
public typealias TaskCompletionHandler = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void


extension URLSession {
    /**
     Set this to output all requests which were mocked to the console
     */
    public static var debugMockRequests: RequestDebugLevel = .none {
        didSet {
            self.swizzleIfNeeded()
        }
    }
    
    private static let defaultEvaluator: RequestEvaluator = { _ in return .passThrough }
    
    /**
     Set this to a block that will decide whether or not a request must be mocked.
     */
    public static var requestEvaluator: RequestEvaluator = defaultEvaluator {
        didSet {
            URLSession.swizzleIfNeeded()
        }
    }
    
    
    
    
    // MARK: - Swizling
    
    @discardableResult
    class func swizzleIfNeeded() -> Bool {
        enum Static {
            fileprivate static let swizzled: Bool = {
                do {
                    try URLSession.swizzle(replace: "dataTaskWithRequest:", with: "swizzledDataTaskWithRequest:")
                    try URLSession.swizzle(replace: "dataTaskWithRequest:completionHandler:", with: "swizzledDataTaskWithRequest:completionHandler:")
                    try URLSession.swizzle(replace: "dataTaskWithURL:", with: "swizzledDataTaskWithURL:")
                    try URLSession.swizzle(replace: "dataTaskWithURL:completionHandler:", with: "swizzledDataTaskWithURL:completionHandler:")
                    
                    Log("NSURLSession now mocked")
                } catch let e {
                    Log("ERROR: Swizzling failed \(e)")
                }
                
                return true
            }()
        }
        
        return Static.swizzled
    }
    
    // MARK: Swizzled methods
    
    private var emptyCompletionHandler:TaskCompletionHandler {
        get { return { TaskCompletionHandler in return } }
    }
    
    @objc(swizzledDataTaskWithRequest:)
    private func swizzledDataTaskWithRequest(request: URLRequest!) -> URLSessionDataTask {
        return dataTask(with: request, completionHandler: emptyCompletionHandler)
    }
    
    @objc(swizzledDataTaskWithURL:)
    private func swizzledDataTaskWithURL(url: URL!) -> URLSessionDataTask {
        return dataTask(with: url, completionHandler: emptyCompletionHandler)
    }
    
    @objc(swizzledDataTaskWithRequest:completionHandler:)
    private func swizzledDataTaskWithRequest(request: URLRequest!, completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask {
        // If any of our mocks match this request, just do that instead
        if let task = task(for: request, with: completionHandler) {
            switch (URLSession.debugMockRequests) {
            case .all, .mocked:
                Log("request: \(request.debugMockDescription) mocked")
            default:
                break
            }
            
            return task
        }
        
        guard URLSession.requestEvaluator(request) == .passThrough else {
            let exception = NSException(name: NSExceptionName(rawValue: "Mocking Exception"),
                                        reason: "Request \(request) was not mocked but is required to be mocked",
                userInfo: nil)
            exception.raise()
            return self.swizzledDataTaskWithRequest(request: request, completionHandler: completionHandler)
        }
        
        switch (URLSession.debugMockRequests) {
        case .all, .unmocked:
            Log("request: \(request.debugMockDescription) not mocked")
        default:
            break
        }
        
        // Otherwise, let NSURLSession deal with it
        return swizzledDataTaskWithRequest(request: request, completionHandler: completionHandler)
    }
    
    @objc(swizzledDataTaskWithURL:completionHandler:)
    private func swizzledDataTaskWithURL(url: URL!, completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        if let task = task(for: request, with: completionHandler) {
            
            if URLSession.debugMockRequests != .none {
                Log("request: \(request.debugMockDescription) mocked")
            }
            
            return task
        }
        
        guard URLSession.requestEvaluator(request) == .passThrough else {
            let exception = NSException(name: NSExceptionName(rawValue: "Mocking Exception"),
                                        reason: "Request \(request) was not mocked but is required to be mocked",
                userInfo: nil)
            exception.raise()
            return self.swizzledDataTaskWithRequest(request: request, completionHandler: completionHandler)
        }
        
        if URLSession.debugMockRequests == .all {
            Log("request: \(request.debugMockDescription) not mocked")
        }
        
        // Otherwise, let URLSession deal with it
        return swizzledDataTaskWithURL(url: url, completionHandler: completionHandler)
    }
    
    // MARK: - Helpers
    
    fileprivate func task(for request: URLRequest, with completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask? {
        if let mock = URLSession.register.nextSessionMock(for: request) {
            return try! mock.consume(request: request, session: self, with: completionHandler)
        }
        return nil
    }
}
