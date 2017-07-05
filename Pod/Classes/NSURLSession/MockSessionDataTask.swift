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
    
    var mockedResponseItems : [DispatchWorkItem]?;
    weak var session: URLSession?
	private var mutex: pthread_mutex_t = pthread_mutex_t()
    private var completionHandler: ((Data? , URLResponse?, Error?) -> Void)?
    
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
        pthread_mutex_lock(&mutex)
        //Cancel the task only if we haven't got a response yet and the task is running
        if (self._response == nil
            && (self._state == .running || self._state == .suspended)) {
            self._state = .canceling
            
            for mockedResponseItem in mockedResponseItems! {
                mockedResponseItem.cancel()
            }

            if let completionHandler = completionHandler {
                let urlResponse = HTTPURLResponse(url: (self.originalRequest?.url)!, statusCode: NSURLErrorCancelled, httpVersion: "HTTP/1.1", headerFields: [:])!
                completionHandler(nil, urlResponse, NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
            }
            else {
                if let delegate = session?.delegate as? URLSessionDataDelegate {
                    delegate.urlSession?(self.session!, task: self, didCompleteWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                }
            }
            
        }
        pthread_mutex_unlock(&mutex)
    }
    
    override var countOfBytesExpectedToSend: Int64 {
        return 0
    }
    
    override var countOfBytesExpectedToReceive: Int64 {
        return NSURLSessionTransferSizeUnknown
    }
    
    func scheduleMockedResponsesWith(request: URLRequest, session: URLSession, delay: Double, statusCode: Int, headers: [String:String], body: Data?, completionHandler : ((Data?, URLResponse?, Error?) -> Void)?) {
        var items : [DispatchWorkItem] = [];
        
        if let completionHandler = completionHandler {
            items.append(DispatchWorkItem { [weak self] in
                guard let task = self else { return }
                
                pthread_mutex_lock(&task.mutex)
                if (task._state == .running
                    || task._state == .suspended) {
                    let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
                    task.response = response
                    task._state = .completed
                    completionHandler(body, response, nil);
                }
                pthread_mutex_unlock(&task.mutex)
            })
        }
        else {
            items.append(DispatchWorkItem { [weak self] in
                guard let task = self else { return }
                guard let delegate : URLSessionDataDelegate = task.session?.delegate as? URLSessionDataDelegate else { return }
                
                pthread_mutex_lock(&task.mutex)
                if (task._state == .running
                    || task._state == .suspended) {
                    let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
                    task.response = response
                    delegate.urlSession?(session, dataTask: task, didReceive: response) { _ in }
                }
                pthread_mutex_unlock(&task.mutex)
            })
            
            if let body = body {
                items.append(DispatchWorkItem { [weak self] in
                    guard let task = self else { return }
                    guard let delegate : URLSessionDataDelegate = task.session?.delegate as? URLSessionDataDelegate else { return }
                    
                    pthread_mutex_lock(&task.mutex)
                    if (task._state == .running
                        || task._state == .suspended) {
                        delegate.urlSession?(session, dataTask: task, didReceive: body)
                    }
                    pthread_mutex_unlock(&task.mutex)
                })
            }
            
            items.append(DispatchWorkItem { [weak self] in
                guard let task = self else { return }
                guard let delegate : URLSessionTaskDelegate = task.session?.delegate as? URLSessionTaskDelegate else { return }
                
                pthread_mutex_lock(&task.mutex)
                if (task._state == .running
                    || task._state == .suspended) {
                    task._state = .completed
                    delegate.urlSession?(session, task: task, didCompleteWithError: nil)
                }
                pthread_mutex_unlock(&task.mutex)
            })
        }
        
        self.completionHandler = completionHandler;
        self._originalRequest = request
        self.session = session
        self._state = .running

        schedule(mockedResponses: items, after: delay)
    }
    
    func scheduleMockedResponsesWith(request: URLRequest, session: URLSession, delay: Double, error: NSError, completionHandler : ((Data?, URLResponse?, Error?) -> Void)?) {
        var items : [DispatchWorkItem] = [];
        
        if let completionHandler = completionHandler {
            items.append(DispatchWorkItem { [weak self] in
                guard let task = self else { return }
                
                pthread_mutex_lock(&task.mutex)
                if (task._state == .running
                    || task._state == .suspended) {
                    task._state = .completed
                    let urlResponse = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [:])!
                    completionHandler(nil, urlResponse, error)

                }
                pthread_mutex_unlock(&task.mutex)
            })
        }
        else {
            items.append(DispatchWorkItem { [weak self] in
                guard let task = self else { return }
                guard let delegate : URLSessionTaskDelegate = task.session?.delegate as? URLSessionTaskDelegate else { return }
                
                pthread_mutex_lock(&task.mutex)
                if (task._state == .running
                    || task._state == .suspended) {
                    task._state = .completed
                    delegate.urlSession?(session, task: task, didCompleteWithError: error)
                }
                pthread_mutex_unlock(&task.mutex)
            })
        }
        
        self.completionHandler = completionHandler;
        self._originalRequest = request
        self.session = session
        self._state = .running

        schedule(mockedResponses: items, after: delay)
    }
    
    private func schedule(mockedResponses: [DispatchWorkItem], after: Double) {
        let timeDelta = 0.02
        var time = after
        
        pthread_mutex_lock(&mutex)
        
        //cancel previous responses if any
        if let mockedResponseItems = self.mockedResponseItems {
            for mockedResponseItem in mockedResponseItems {
                mockedResponseItem.cancel()
            }
        }

        self.mockedResponseItems = mockedResponses
        
        for mockedResponseItem in mockedResponses {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time,
                                          execute: mockedResponseItem)
            time += timeDelta
        }
        
        pthread_mutex_unlock(&mutex)
    }
    
    deinit {
        self.cancel()
        pthread_mutex_destroy(&self.mutex)
    }
    
}

