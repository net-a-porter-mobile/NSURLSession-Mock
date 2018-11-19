//
//  NSURLSession+Mock.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation


/**
 Set the debug level on NSURLSession to output all the request that flow through
 this extension.
 
 - None: Don't log any requests
 - Mocked: Only log requests which are mocked
 - All: Log all requests whether they match a mock or not
*/
public enum RequestDebugLevel: Int {
    case none
    case mocked
    case unmocked
    case all
}


/**
 An opaque reference to a request for mocking - this can be passed back in to determine the state of a mock
*/
public struct Handle {
    fileprivate let sessionMock: MockEntry
}


extension URLSession {
    
    internal static let register = MockRegister<MockEntry>()
    
    /**
     The next call exactly matching `request` will successfully return `body`
     
     - parameter request: The request to mock
     - parameter body: The data returned by the session data task. If this is `nil` then the didRecieveData callback won't be called.
     - parameter headers: The headers returned by the session data task
     - parameter statusCode: The status code (default=200) returned by the session data task
     - parameter delay: A artificial delay before the session data task starts to return response and data
     */
    @discardableResult
    public class func mockNext(request: URLRequest, body: Data?, headers: [String: String] = [:], statusCode: Int = 200, delay: Double = DefaultDelay) -> Handle {
        let matcher = SimpleRequestMatcher(url: request.url!, method: request.httpMethod!)
        return self.mock(next: matcher, delay: delay) { _,_  in .success(statusCode: statusCode, headers: headers, body: body) }
    }

    /**
     All calls exactly matching `request` will successfully return `body`
     
     - parameter request: The request to mock
     - parameter body: The data returned by the session data task. If this is `nil` then the didRecieveData callback won't be called.
     - parameter headers: The headers returned by the session data task
     - parameter statusCode: The status code (default=200) returned by the session data task
     - parameter delay: A artificial delay before the session data task starts to return response and data
     */
    public class func mockEvery(request: URLRequest, body: Data?, headers: [String: String] = [:], statusCode: Int = 200, delay: Double = DefaultDelay) {
        let matcher = SimpleRequestMatcher(url: request.url!, method: request.httpMethod!)
        self.mock(every: matcher, delay:delay) { _,_  in return .success(statusCode: statusCode, headers: headers, body: body) }
    }
    
    /**
     The next call matching `expression` will successfully return `body`
     
     - parameter expression: The regular expression to compare incoming requests against
     - parameter HTTPMethod: The method to match against
     - parameter body: The data returned by the session data task. If this is `nil` then the didRecieveData callback won't be called.     
     - parameter headers: The headers returned by the session data task
     - parameter statusCode: The status code (default=200) returned by the session data task
     - parameter delay: A artificial delay before the session data task starts to return response and data
     */
    @discardableResult
    public class func mockNext(expression: String, httpMethod: String = "GET", body: Data?, headers: [String: String] = [:], statusCode: Int = 200, delay: Double = DefaultDelay) throws -> Handle {
        let matcher = try SimpleRequestMatcher(expression: expression, method: httpMethod)
        return self.mock(next: matcher, delay: delay) { _,_  in return .success(statusCode: statusCode, headers: headers, body: body) }
    }

    /**
     All subsequent requests matching `expression` will successfully return `body`

     - parameter expression: The regular expression to compare incoming requests against
     - parameter HTTPMethod: The method to match against
     - parameter body: The data returned by the session data task. If this is `nil` then the didRecieveData callback won't be called.
     - parameter headers: The headers returned by the session data task
     - parameter statusCode: The status code (default=200) returned by the session data task
     - parameter delay: A artificial delay before the session data task starts to return response and data
     */
    public class func mockEvery(expression: String, httpMethod: String = "GET", body: Data?, headers: [String: String] = [:], statusCode: Int = 200, delay: Double = DefaultDelay) throws {
        let matcher = try SimpleRequestMatcher(expression: expression, method: httpMethod)
        self.mock(every: matcher, delay: delay) { _,_  in return .success(statusCode: statusCode, headers: headers, body: body) }
    }

    /**
     The next request matching `expression` will successfully return the result of `response`, a method where the matched sections of the url are passed in as parameters.

     - parameter expression: The regular expression to compare incoming requests against
     - parameter HTTPMethod: The method to match against
     - parameter headers: The headers returned by the session data task
     - parameter statusCode: The status code (default=200) returned by the session data task
     - parameter delay: A artificial delay before the session data task starts to return response and data
     - parameter response: Returns data the data to be returned by the session data task. If this returns `nil` then the didRecieveData callback won't be called.
     */
    @discardableResult
    public class func mockNext(expression: String, httpMethod: String = "GET", delay: Double = DefaultDelay, response: @escaping MockResponseHandler) throws -> Handle {
        let matcher = try SimpleRequestMatcher(expression: expression, method: httpMethod)
        return self.mock(next: matcher, delay: delay, response: response)
    }

    /**
     All subsequent requests matching `expression` will successfully return the result of `response`, a method where the matched sections of the url are passed in as parameters.

     - parameter expression: The regular expression to compare incoming requests against
     - parameter HTTPMethod: The method to match against
     - parameter headers: The headers returned by the session data task
     - parameter statusCode: The status code (default=200) returned by the session data task
     - parameter delay: A artificial delay before the session data task starts to return response and data
     - parameter response: Returns data the data to be  returned by the session data task. If this returns `nil` then the didRecieveData callback won't be called.
     */
    public class func mockEvery(expression: String, httpMethod: String = "GET", delay: Double = DefaultDelay, response: @escaping MockResponseHandler) throws {
        let matcher = try SimpleRequestMatcher(expression: expression, method: httpMethod)
        self.mock(every: matcher, delay: delay, response: response)
    }

    /**
     Remove all mocks - NSURLSession will behave as if it had never been touched
     */
    public class func removeAllMocks() {
        self.register.removeAllMocks()
    }
    
    /**
     Remove all mocks matching the given request. All other requests will still
     be mocked
     */
    public class func removeAllMocks(of request: URLRequest) {
        self.register.removeAllMocks(of: request)
    }
    
    /**
     For a given handle, has it been consumed or not?
     
     - paramater handle: The returned handle from a call to mock a request i.e. mockSingle(...)
     */
    public class func hasMockConsumed(handle: Handle) -> Bool {
        return !register.contains(ephemeral: handle.sessionMock)
    }

    //MARK: Private methods
    
    // Add a request matcher to the list of mocks
    private class func mock(next matcher: RequestMatcher, delay: Double, response: @escaping MockResponseHandler) -> Handle {
        let handle = Handle(sessionMock: MockEntry(matching: matcher, response: response, delay: delay))
        self.register.add(ephemeral: handle.sessionMock)
        self.swizzleIfNeeded()
        return handle
    }
    
    // Add a request matcher to the list of mocks
    private class func mock(every matcher: RequestMatcher, delay: Double, response: @escaping MockResponseHandler) {
        let mock = MockEntry(matching: matcher, response: response, delay: delay)
        self.register.add(permanent: mock)
        self.swizzleIfNeeded()
    }
}
