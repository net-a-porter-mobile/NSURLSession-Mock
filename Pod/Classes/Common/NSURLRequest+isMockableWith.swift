//
//  NSURLRequest+equality.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

extension NSURLRequest {
    
    /**
     Compare two requests to see if it makes sense to return a mock response when recieving the other. This function is symmetric.
     
     - parameter other: The request to compare against.
     
     - returns: `true` if it's reasonable to consider these two requests the same for mocking. `false` otherwise.
     */
    func isMockableWith(other: NSURLRequest) -> Bool {
        return (self.URL == other.URL &&
                self.HTTPMethod == other.HTTPMethod)
    }
    
}
