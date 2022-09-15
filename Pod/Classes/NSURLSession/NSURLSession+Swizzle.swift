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
                    try URLSession.swizzle(replace: "dataTaskWithURL:", with: "swizzledDataTaskWithURL:")

                    try URLSession.swizzle(replace: "dataTaskWithRequest:completionHandler:", with: "swizzledDataTaskWithRequest:completionHandler:")
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
    
    @objc(swizzledDataTaskWithRequest:)
    private func swizzledDataTaskWithRequest(request: URLRequest!) -> URLSessionDataTask {
        return self.actOnDataTask(withRequest: request,
                                  fallback: { self.swizzledDataTaskWithRequest(request: request) },
                                  completionHandler: nil)
    }

    @objc(swizzledDataTaskWithRequest:completionHandler:)
    private func swizzledDataTaskWithRequest(request: URLRequest!, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.actOnDataTask(withRequest: request,
                                  fallback: { return swizzledDataTaskWithRequest(request: request, completionHandler: completionHandler) },
                                  completionHandler: completionHandler)

    }

    @objc(swizzledDataTaskWithURL:)
    private func swizzledDataTaskWithURL(url: URL!) -> URLSessionDataTask {
        let request = URLRequest(url: url)

        return self.dataTask(with: request)
    }

    @objc(swizzledDataTaskWithURL:completionHandler:)
    private func swizzledDataTaskWithURL(url: URL!, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let request = URLRequest(url: url)

        return self.dataTask(with: request, completionHandler: completionHandler)
    }

    // MARK: - Helpers

    private func actOnDataTask(withRequest request: URLRequest, fallback: () -> URLSessionDataTask, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> URLSessionDataTask {
        // If any of our mocks match this request, just do that instead
        if let task = task(for: request, completionHandler: completionHandler) {

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
                                        reason: "Request \(String(describing: request)) was not mocked but is required to be mocked",
                                        userInfo: nil)
            exception.raise()
            return fallback()
        }

        switch (URLSession.debugMockRequests) {
        case .all, .unmocked:
            Log("request: \(request.debugMockDescription) not mocked")
        default:
            break
        }

        // Otherwise, let NSURLSession deal with it
        return fallback()
    }
    
    private func task(for request: URLRequest, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> URLSessionDataTask? {
        if let mock = URLSession.register.nextSessionMock(for: request) {
            return try! mock.consume(request: request, completionHandler: completionHandler, session: self)
        }
        return nil
    }
}
