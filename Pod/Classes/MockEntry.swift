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
     The mock data to return
     */
    let data: NSData?
    
    /**
     An error to return
     */
    let error: NSError?
    
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
    static func singleURL(URL: NSURL, withData data: NSData, delay: Double) -> MockEntry {
        return MockEntry(URL: URL, data: data, error: nil, isSingle: true, delay: delay)
    }
    
    static func everyURL(URL: NSURL, withData data: NSData, delay: Double) -> MockEntry {
        return MockEntry(URL: URL, data: data, error: nil, isSingle: false, delay: delay)
    }
    
    static func singleURL(URL: NSURL, withError error: NSError, delay: Double) -> MockEntry {
        return MockEntry(URL: URL, data: nil, error: error, isSingle: true, delay: delay)
    }
    
    static func everyURL(URL: NSURL, withError error: NSError, delay: Double) -> MockEntry {
        return MockEntry(URL: URL, data: nil, error: error, isSingle: false, delay: delay)
    }
}

extension MockEntry : Equatable { }

func ==(a: MockEntry, b: MockEntry) -> Bool {
    return (a.URL == b.URL &&
            a.data == b.data &&
            a.isSingle == b.isSingle)
}
