//
//  RequestMatcher.swift
//  Pods
//
//  Created by Sam Dean on 02/02/2016.
//
//

import Foundation

enum MatchesResponse {
    case noMatch
    case matches(extractions:[String])
}

protocol RequestMatcher {

    func matches(request: URLRequest) -> MatchesResponse
    
}
