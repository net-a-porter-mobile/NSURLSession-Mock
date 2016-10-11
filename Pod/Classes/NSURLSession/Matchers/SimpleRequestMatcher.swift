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
struct SimpleRequestMatcher: RequestMatcher {

    let pathMatcher: NSRegularExpression

    let method: String

    init(url: URL, method: String) {
        let path = NSRegularExpression.escapedPattern(for: url.absoluteString)
        try! self.init(expression: "^\(path)$", method: method)
    }

    init(expression: String, method: String) throws {
        try self.pathMatcher = NSRegularExpression(pattern: expression, options: NSRegularExpression.Options.anchorsMatchLines)
        self.method = method
    }

    func matches(request: URLRequest) -> MatchesResponse {
        // Quick check that the methods are the same
        guard request.httpMethod == self.method else { return .noMatch }

        // Get the match
        let path = request.url?.absoluteString ?? ""
        let range = NSMakeRange(0, path.utf16.count)
        let matches = self.pathMatcher.matches(in: path, options: [], range: range)
        guard matches.count > 0 else { return .noMatch }

        // If there were any matches, extract them here (match at index 0 is the
        // whole string - skip that one)
        var extractions = [String]()
        for match in matches {
            for n in 1 ..< match.numberOfRanges {
                let range = match.rangeAt(n)
                let extraction = (path as NSString).substring(with: range)
                extractions.append(extraction)
            }
        }

        return .matches(extractions: extractions)
    }
}
