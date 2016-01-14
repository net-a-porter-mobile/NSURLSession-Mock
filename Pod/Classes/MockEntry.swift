//
//  MockEntry.swift
//  Pods
//
//  Created by Sam Dean on 14/01/2016.
//
//

import Foundation

struct MockEntry {
    let url: NSURL
    
    let headers: Dictionary<String, String> = Dictionary()
    let response: NSData
}
