//
//  MockResponse.swift
//  Pods
//
//  Created by Kerr Miller on 27/01/2016.
//
//

import Foundation

struct MockResponse {
    /**
     The mock data to return
     */
    let data: NSData?
    
    /**
     An error to return
     */
    let error: NSError?
    
    /**
     A set of headers to return
     */
    let headers: [String: String]
    
    /**
     The status code to return from the response
     */
    let statusCode: Int
}

extension MockResponse : Equatable { }

func ==(a: MockResponse, b: MockResponse) -> Bool {
    return (a.data == b.data &&
            a.statusCode == b.statusCode &&
            a.error == b.error &&
            a.headers == b.headers
    )
}