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
        let url = URL(string: path)!
        
        let matcher = SimpleRequestMatcher(url: url, method: "GET")
        
        let r1 = URLRequest(url: url)

        let result = matcher.matches(request: r1)
        switch(result) {
        case .noMatch:
            XCTFail("Should have matched")
        case .matches(let extractions):
            XCTAssertEqual([], extractions)
        }
    }
    
    func testRequestMatcher_WithOddMethod_ShouldNotMatch() {
        let path = "www.example.com/a/b/c"
        let url = URL(string: path)!
        
        let matcher = SimpleRequestMatcher(url: url, method: "HEAD")
        
        let r1 = URLRequest(url: url)
        let result = matcher.matches(request: r1)
        switch(result) {
        case .noMatch:
            break
        case .matches(_):
            XCTFail("Should not have matched")
        }
    }
    
    func testRequestMatcher_WithRegex_ShouldMatch() {
        let path = ".*/a/b/(.)"
        let matcher = try! SimpleRequestMatcher(expression: path, method: "GET")
        
        let url = URL(string: "www.example.com/a/b/c")!
        let r1 = URLRequest(url: url)

        let result = matcher.matches(request: r1)
        switch(result) {
        case .noMatch:
            XCTFail("Should have matched")
        case .matches(let extractions):
            XCTAssertEqual([ "c" ], extractions)
        }
    }
    
    func testRequestMatcher_WithRegex_ShouldNotMatch() {
        let path = ".*/a/b/c"
        let matcher = try! SimpleRequestMatcher(expression: path, method: "GET")
        
        let url = URL(string: "www.example.com/b/c/a")!
        let r1 = URLRequest(url: url)

        let result = matcher.matches(request: r1)
        switch(result) {
        case .noMatch:
            break
        case .matches(_):
            XCTFail("Should not have matched")
        }
    }

    func testRequestMatcher_WithDuplicateMatch_ShouldMatch() {

        let path = "/product/(...)"
        let matcher = try! SimpleRequestMatcher(expression: path, method: "GET")

        let url = URL(string: "/product/123/product/456")!
        let request = URLRequest(url: url)

        let result = matcher.matches(request: request)
        switch(result) {
        case .noMatch:
            XCTFail("Should have matched")
        case let .matches(matches):
            XCTAssertEqual(matches, [ "123", "456" ])
        }
    }
}
