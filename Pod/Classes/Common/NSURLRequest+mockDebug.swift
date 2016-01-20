//
//  NSURLRequest+mockDebug.swift
//  Pods
//
//  Created by Sam Dean on 20/01/2016.
//
//

import Foundation


extension NSURLRequest {
    
    var debugMockDescription: String {
        
        let method = self.HTTPMethod ?? "<no method>"
        let URL = self.URL?.absoluteString ?? "<no url>"
        
        return "<NSURLRequest:\(unsafeAddressOf(self)) \(method) \(URL)"
    }

}
