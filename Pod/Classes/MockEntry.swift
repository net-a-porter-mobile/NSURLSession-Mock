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
    let data: NSData
    
    /**
     If this is true then the mock data should only be returned once
    */
    let isSingle: Bool
}

extension MockEntry : Equatable { }

func ==(a: MockEntry, b: MockEntry) -> Bool {
    return (a.URL == b.URL &&
            a.data == b.data &&
            a.isSingle == b.isSingle)
}
