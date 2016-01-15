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
}

// MARK: - Contructors 

extension MockEntry {
    static func singleURL(URL: NSURL, withData data: NSData) -> MockEntry {
        return MockEntry(URL: URL, data: data, error: nil, isSingle: true)
    }
    
    static func everyURL(URL: NSURL, withData data: NSData) -> MockEntry {
        return MockEntry(URL: URL, data: data, error: nil, isSingle: false)
    }
    
    static func singleURL(URL: NSURL, withError error: NSError) -> MockEntry {
        return MockEntry(URL: URL, data: nil, error: error, isSingle: true)
    }
    
    static func everyURL(URL: NSURL, withError error: NSError) -> MockEntry {
        return MockEntry(URL: URL, data: nil, error: error, isSingle: false)
    }
}

extension MockEntry : Equatable { }

func ==(a: MockEntry, b: MockEntry) -> Bool {
    return (a.URL == b.URL &&
            a.data == b.data &&
            a.isSingle == b.isSingle)
}
