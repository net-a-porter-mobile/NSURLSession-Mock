//
//  SimpleRequestMatcher.swift
//  Pods
//
//  Created by Sam Dean on 02/02/2016.
//
//

import Foundation

/**
 This struct matches by matching the path to a regular expression and by 
 comparing the methods for equality.
*/
struct SimpleRequestMatcher : RequestMatcher {
    
    let pathMatcher: NSRegularExpression
    
    let method: String
    
    init(url: NSURL, method: String) {
        let path = NSRegularExpression.escapedPatternForString(url.absoluteString)
        try! self.init(expression: "^\(path)$", method: method)
    }
    
    init(expression: String, method: String) throws {
        try self.pathMatcher = NSRegularExpression(pattern: expression, options: NSRegularExpressionOptions.AnchorsMatchLines)
        self.method = method
    }
    
    func matches(request: NSURLRequest) -> Bool {
        guard request.HTTPMethod == self.method else { return false }
        
        let path = request.URL?.absoluteString ?? ""
        let options = NSMatchingOptions(rawValue: 0)
        let range = NSMakeRange(0, (path as NSString).length)
        return pathMatcher.numberOfMatchesInString(path, options: options, range: range) == 1
    }
    
}
