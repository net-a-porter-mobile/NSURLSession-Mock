//
//  MockSessionDataTask.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

private var globalTaskIdentifier: Int = 100000 // Some number bigger than the session would naturally create

public class MockSessionDataTask : NSURLSessionDataTask {
    
    let onResume: (task: MockSessionDataTask)->()
    
    init(onResume: (task: MockSessionDataTask)->()) {
        self.onResume = onResume
    }
    
    var _taskIdentifier: Int = { return ++globalTaskIdentifier }()
    override public var taskIdentifier: Int {
        return _taskIdentifier
    }
    
    var _originalRequest: NSURLRequest?
    override public var originalRequest: NSURLRequest? {
        return _originalRequest
    }
    
    var _currentRequest: NSURLRequest?
    override public var currentRequest: NSURLRequest? {
        return _currentRequest
    }
    
    var _state: NSURLSessionTaskState = .Suspended
    override public var state: NSURLSessionTaskState {
        return _state
    }
    
    override public func resume() {
        self.onResume(task: self)
    }
    
    private var _taskDescription: String?
    override public var taskDescription: String? {
        get { return _taskDescription }
        set { _taskDescription = newValue }
    }
    
    private var _response: NSURLResponse?
    override public var response: NSURLResponse? {
        get { return _response }
        set { _response = newValue }
    }
}
