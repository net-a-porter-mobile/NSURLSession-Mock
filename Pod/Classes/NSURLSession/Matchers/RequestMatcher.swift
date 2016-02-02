//
//  RequestMatcher.swift
//  Pods
//
//  Created by Sam Dean on 02/02/2016.
//
//

import Foundation

protocol RequestMatcher {

    func matches(request: NSURLRequest) -> Bool
    
}
