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

And, curiously, added the properties that `NSURLSessionDataTask` says it has but doesn't actuall have. Not sure what's going on there.
*/
class MockSessionDataTask : NSURLSessionDataTask {
    
    let onResume: (task: MockSessionDataTask)->()
    
    init(onResume: (task: MockSessionDataTask)->()) {
        self.onResume = onResume
    }
    
    var _taskIdentifier: Int = {
        globalTaskIdentifier += 1
        return globalTaskIdentifier
    }()
    override var taskIdentifier: Int {
        return _taskIdentifier
    }
    
    var _originalRequest: NSURLRequest?
    override var originalRequest: NSURLRequest? {
        return _originalRequest
    }
    
    var _currentRequest: NSURLRequest?
    override var currentRequest: NSURLRequest? {
        return _currentRequest
    }
    
    var _state: NSURLSessionTaskState = .Suspended
    override var state: NSURLSessionTaskState {
        return _state
    }
    
    override func resume() {
        self.onResume(task: self)
    }
    
    private var _taskDescription: String?
    override var taskDescription: String? {
        get { return _taskDescription }
        set { _taskDescription = newValue }
    }
    
    private var _response: NSURLResponse?
    override var response: NSURLResponse? {
        get { return _response }
        set { _response = newValue }
    }
    
    override func cancel() {
        self._state = .Canceling
    }
}
