//
//  MockEntry.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation


private let mult = Double(NSEC_PER_SEC)


class MockEntry: SessionMock, Equatable {
    private let requestMatcher: RequestMatcher
    private let response: MockResponseHandler
    private let delay: Double

    init(matching requestMatcher: RequestMatcher, response: @escaping MockResponseHandler, delay: Double) {
        self.requestMatcher = requestMatcher
        self.response = response
        self.delay = delay
    }

    func matches(request: URLRequest) -> Bool {
        switch(self.requestMatcher.matches(request: request)) {
        case .matches: return true
        case .noMatch: return false
        }
    }

    func consume(request: URLRequest, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?, session: URLSession) throws -> URLSessionDataTask {

        switch (self.requestMatcher.matches(request: request)) {

        // If this isn't for us, we shouldn't have been called, throw and let
        // everyone know!
        case .noMatch:
            throw SessionMockError.invalidRequest(request: request)

        // Use the extractions from the match to create the data
        case .matches(let extractions):
            // Do we respond to the completion handler, or the session delegate?
            let handler = { (completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> (MockSessionDataTask) -> Void in
                if let completionHandler = completionHandler {
                    return self.respondToCompletionHandler(request: request, extractions: extractions, completionHandler: completionHandler)
                } else {
                    return self.respondToDelegate(request: request, extractions: extractions, session: session)
                }
            }(completionHandler)

            let task = MockSessionDataTask() { task in
                task._state = .running

                handler(task)
            }

            task._originalRequest = request

            return task
        }
    }

    // MARK: - Completion handler responder
    private func respondToCompletionHandler(request: URLRequest, extractions: [String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> (MockSessionDataTask) -> Void {
        return { task in
            let response = self.response(request.url!, extractions)

            switch response {
            case .success(let statusCode, let headers, let body):
                let urlResponse = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
                completionHandler(body, urlResponse, nil)
            case .failure(let error):
                let urlResponse = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [:])!
                completionHandler(nil, urlResponse, error)
            }
        }
    }

    // MARK: - Session delegate responder
    private func respondToDelegate(request: URLRequest, extractions: [String], session: URLSession) -> (MockSessionDataTask) -> Void {
        return { task in
            let response = self.response(request.url!, extractions)

            switch response {
            case let .success(statusCode, headers, body):
                self.respondToDelegateWith(request: request, session: session, task: task, statusCode: statusCode, headers: headers, body: body)

            case let .failure(error):
                self.respondToDelegateWith(request: request, session: session, task: task, error: error)
            }
        }
    }

    private func respondToDelegateWith(request: URLRequest, session: URLSession, task: MockSessionDataTask, statusCode: Int, headers: [String:String], body: Data?) {
        let timeDelta = 0.02
        var time = self.delay

        if let delegate = session.delegate as? URLSessionDataDelegate {

            DispatchQueue.current.asyncAfter(deadline: .now() + time) {
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
                task.response = response

                delegate.urlSession?(session, dataTask: task, didReceive: response) { _ in }
            }

            time += timeDelta

            if let body = body {

                DispatchQueue.current.asyncAfter(deadline: .now() + time) {
                    delegate.urlSession?(session, dataTask: task, didReceive: body)
                }

                time += timeDelta
            }
        }

        if let delegate = session.delegate as? URLSessionTaskDelegate {

            DispatchQueue.current.asyncAfter(deadline: .now() + time) {
                if #available(iOS 10.0, *) {
                    let metrics = URLSessionTaskMetrics()
                    // Alamofire waits for the didFinishCollecting to trigger the callbacks of a request
                    delegate.urlSession?(session, task: task, didFinishCollecting: metrics)
                }
                delegate.urlSession?(session, task: task, didCompleteWithError: nil)
                task._state = .completed
            }
        }

    }

    private func respondToDelegateWith(request: URLRequest, session: URLSession, task: MockSessionDataTask, error: NSError) {
        if let delegate = session.delegate as? URLSessionTaskDelegate {

            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                delegate.urlSession?(session, task: task, didCompleteWithError: error)
                task._state = .completed
            }
        }
    }
}


func ==(lhs: MockEntry, rhs: MockEntry) -> Bool {
    return lhs === rhs
}

// Ugly work around for the demo mode work work we need to use the same queue as the one the requests where
// scheduled. Alamofire uses its own queue and has assertions for checking this.
extension DispatchQueue {
    private static let dispatch_get_current_queue = dlsym(dlopen(nil, RTLD_GLOBAL), "dispatch_get_current_queue")

    static var current: DispatchQueue {
        dispatch_get_current_queue.map {
            unsafeBitCast($0, to: (@convention(c) () -> Unmanaged<DispatchQueue>).self)().takeUnretainedValue()
        } ?? .global(qos: .background)
    }
}
