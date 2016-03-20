//
//  SimpleRequestMatcherTests.swift
//  NSURLSession-Mock
//
//  Created by Sam Dean on 02/02/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

@testable import NSURLSession_Mock

class SimpleRequestMatcherTests: XCTestCase {

    func testRequestMatcher_WithPlainURL_ShouldMatch() {
        let path = "www.example.com/a/b/c"
        let URL = NSURL(string: path)!
        
        let matcher = SimpleRequestMatcher(url: URL, method: "GET")
        
        let r1 = NSURLRequest(URL: URL)

        let result = matcher.matches(r1)
        switch(result) {
        case .NoMatch:
            XCTFail("Should have matched")
        case .Matches(let extractions):
            XCTAssertEqual([], extractions)
        }
    }
    
    func testRequestMatcher_WithOddMethod_ShouldNotMatch() {
        let path = "www.example.com/a/b/c"
        let URL = NSURL(string: path)!
        
        let matcher = SimpleRequestMatcher(url: URL, method: "HEAD")
        
        let r1 = NSURLRequest(URL: URL)
        let result = matcher.matches(r1)
        switch(result) {
        case .NoMatch:
            break
        case .Matches(_):
            XCTFail("Should not have matched")
        }
    }
    
    func testRequestMatcher_WithRegex_ShouldMatch() {
        let path = ".*/a/b/(.)"
        let matcher = try! SimpleRequestMatcher(expression: path, method: "GET")
        
        let URL = NSURL(string: "www.example.com/a/b/c")!
        let r1 = NSURLRequest(URL: URL)

        let result = matcher.matches(r1)
        switch(result) {
        case .NoMatch:
            XCTFail("Should have matched")
        case .Matches(let extractions):
            XCTAssertEqual([ "c" ], extractions)
        }
    }
    
    func testRequestMatcher_WithRegex_ShouldNotMatch() {
        let path = ".*/a/b/c"
        let matcher = try! SimpleRequestMatcher(expression: path, method: "GET")
        
        let URL = NSURL(string: "www.example.com/b/c/a")!
        let r1 = NSURLRequest(URL: URL)

        let result = matcher.matches(r1)
        switch(result) {
        case .NoMatch:
            break
        case .Matches(_):
            XCTFail("Should not have matched")
        }
    }
}
