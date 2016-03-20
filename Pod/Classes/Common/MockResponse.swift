//
//  MockResponse.swift
//  Pods
//
//  Created by Kerr Miller on 27/01/2016.
//
//

import Foundation

/**
 Describes a single response to a mocked request
*/
struct MockResponse {
    let body: NSData?
    let statusCode: Int
    let headers: [String:String]

    init(body: NSData?, statusCode: Int = 200, headers: [String:String] = [:]) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
    }
}

/**
 Given the URL and the extracted sections, what should be the response data, the status code and the headers.
*/
typealias MockResponseHandler = (url: NSURL, extractions: [String]) -> MockResponse
