//
//  NSURLRequest+mockDebug.swift
//  Pods
//
//  Created by Sam Dean on 20/01/2016.
//
//

import Foundation


extension URLRequest {
    
    var debugMockDescription: String {
        
        let method = self.httpMethod ?? "<no method>"
        let URL = self.url?.absoluteString ?? "<no url>"
        
        return "<NSURLRequest \(method) \(URL)"
    }
}
