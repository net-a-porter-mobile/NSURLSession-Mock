//
//  TestDelegate.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 15/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class TestDelegate : NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var response: URLResponse?
    var data: NSMutableData?
    var error: Error?
    
    let complete: () -> ()
    
    init(complete: @escaping () -> ()) {
        self.complete = complete
    }
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        self.response = response
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        if self.data == nil {
            self.data = NSMutableData()
        }
        self.data!.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.complete()
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.error = error
        self.complete()
    }
}
