//
//  MockEntry.swift
//  Pods
//
//  Created by Sam Dean on 14/01/2016.
//
//

import Foundation

/**
 Represents a mock response for a URL
*/
struct MockEntry {
    
    /**
     A constant for the default delay
     */
    static let DefaultDelay = 0.05
    
    /**
     The URL to match against
     */
    let URL: NSURL
    
    /**
     The Mock response to return from this request
    */
    let response: MockResponse
     
    /**
     If this is true then the mock data should only be returned once
     */
    let isSingle: Bool
    
    /**
     Add a delay to the response
     */
    let delay: Double
}

// MARK: - Contructors 

extension MockEntry {
    static func singleURL(URL: NSURL, withResponse response: MockResponse, delay: Double) -> MockEntry {
        return MockEntry(URL: URL, response: response, isSingle: true, delay: delay)
    }
    
    static func everyURL(URL: NSURL, withResponse response: MockResponse, delay: Double) -> MockEntry {
        return MockEntry(URL: URL, response: response, isSingle: false, delay: delay)
    }
}

extension MockEntry : Equatable { }

func ==(a: MockEntry, b: MockEntry) -> Bool {
    return (a.URL == b.URL &&
            a.response == b.response &&
            a.isSingle == b.isSingle)
}


