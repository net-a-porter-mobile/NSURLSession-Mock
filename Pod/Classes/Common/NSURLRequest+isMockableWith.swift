//
//  NSURLRequest+equality.swift
//  Pods
//
//  Created by Sam Dean on 19/01/2016.
//
//

import Foundation

extension NSURLRequest {
    
    func isMockableWith(other: NSURLRequest) -> Bool {
        return (self.URL == other.URL &&
                self.HTTPMethod == other.HTTPMethod)
    }
    
}
