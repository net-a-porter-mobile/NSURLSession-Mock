//
//  MockSessionDataTask.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation


private var globalTaskIdentifier: Int = 100000 // Some number bigger than the session would naturally create


/**
Internal implementation of `NSURLSessionDataTask` with read-write properties.

And, curiously, added the properties that `NSURLSessionDataTask` says it has but doesn't actually have. Not sure what's going on there.
*/
class MockSessionDataTask: URLSessionDataTask {
    
    let onResume: (_ task: MockSessionDataTask)->()
    
    init(onResume: @escaping (_ task: MockSessionDataTask)->()) {
        self.onResume = onResume
    }
    
    var _taskIdentifier: Int = {
        globalTaskIdentifier += 1
        return globalTaskIdentifier
    }()
    override var taskIdentifier: Int {
        return _taskIdentifier
    }
    
    var _originalRequest: URLRequest?
    override var originalRequest: URLRequest? {
        return _originalRequest
    }
    
    var _currentRequest: URLRequest?
    override var currentRequest: URLRequest? {
        return _currentRequest
    }
    
    var _state: URLSessionTask.State = .suspended
    override var state: URLSessionTask.State {
        return _state
    }
    
    override func resume() {
        self.onResume(self)
    }
    
    private var _taskDescription: String?
    override var taskDescription: String? {
        get { return _taskDescription }
        set { _taskDescription = newValue }
    }
    
    private var _response: URLResponse?
    override var response: URLResponse? {
        get { return _response }
        set { _response = newValue }
    }
    
    override func cancel() {
        self._state = .canceling
    }
    
    override var countOfBytesExpectedToSend: Int64 {
        return 0
    }
    
    override var countOfBytesExpectedToReceive: Int64 {
        return NSURLSessionTransferSizeUnknown
    }
}
