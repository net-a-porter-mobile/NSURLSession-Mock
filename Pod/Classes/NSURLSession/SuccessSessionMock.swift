//
//  SuccessSessionMock.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

private let mult = Double(NSEC_PER_SEC)

class SuccessSessionMock : SessionMock {

    private let requestMatcher: RequestMatcher
    private let response: MockResponseHandler
    private let delay: Double
    
    init(matching requestMatcher: RequestMatcher, response: MockResponseHandler, delay: Double) {
        self.requestMatcher = requestMatcher
        self.response = response
        self.delay = delay
    }

    func matchesRequest(request: NSURLRequest) -> Bool {
        switch(self.requestMatcher.matches(request)) {
        case .Matches: return true
        case .NoMatch: return false
        }
    }

    func consumeRequest(request: NSURLRequest, session: NSURLSession) throws -> NSURLSessionDataTask {

        switch (self.requestMatcher.matches(request)) {

            // If this isn't for us, we shouldn't have been called, throw and let
        // everyone know!
        case .NoMatch:
            throw SessionMockError.InvalidRequest(request: request)

        // Use the extractions from the match to create the data
        case .Matches(let extractions):
            let task = MockSessionDataTask() { task in
                task._state = .Running

                let timeDelta = 0.02
                var time = self.delay

                let response = self.response(url: request.URL!, extractions: extractions)

                if let delegate = session.delegate as? NSURLSessionDataDelegate,
                    let body = response.body {

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: response.statusCode, HTTPVersion: "HTTP/1.1", headerFields: response.headers)!
                        task.response = response
                        delegate.URLSession?(session, dataTask: task, didReceiveResponse: response) { _ in }
                    }

                    time += timeDelta

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        delegate.URLSession?(session, dataTask: task, didReceiveData: body)
                    }

                    time += timeDelta
                }

                if let delegate = session.delegate as? NSURLSessionTaskDelegate {

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), dispatch_get_main_queue()) {
                        delegate.URLSession?(session, task: task, didCompleteWithError: nil)
                        task._state = .Completed
                    }
                }
            }

            task._originalRequest = request

            return task
        }
    }

}
