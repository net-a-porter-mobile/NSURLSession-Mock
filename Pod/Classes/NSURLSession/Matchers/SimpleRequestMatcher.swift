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

    func matches(request: NSURLRequest) -> MatchesResponse {
        // Quick check that the methods are the same
        guard request.HTTPMethod == self.method else { return .NoMatch }

        // Get the match
        let path = request.URL?.absoluteString ?? ""
        let range = NSMakeRange(0, path.utf16.count)
        let matches = self.pathMatcher.matchesInString(path, options: [], range: range)
        guard matches.count > 0 else { return .NoMatch }

        // If there were any matches, extract them here (match at index 0 is the
        // whole string - skip that one)
        var extractions = [String]()
        for match in matches {
            for n in 1 ..< match.numberOfRanges {
                let range = match.rangeAtIndex(n)
                let extraction = (path as NSString).substringWithRange(range)
                extractions.append(extraction)
            }
        }

        return .Matches(extractions: extractions)
    }
    
}
