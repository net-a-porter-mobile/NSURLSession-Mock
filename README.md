# NSURLSession-Mock

[![CI Status](http://img.shields.io/travis/net-a-porter-mobile/NSURLSession-Mock.svg?style=flat)](https://travis-ci.org/net-a-porter-mobile/NSURLSession-Mock)
[![Version](https://img.shields.io/cocoapods/v/NSURLSession-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLSession-Mock)
[![License](https://img.shields.io/cocoapods/l/NSURLSession-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLSession-Mock)
[![Platform](https://img.shields.io/cocoapods/p/NSURLSession-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLSession-Mock)

## Usage

This pod is designed to help during functional testing by returning canned responses to URLs requested by the app.

### NSURLSession

To mock a single request use `mockSingle` - this method can be called multiple times and the responses will be returned in the same order they were added in:

```objc
let body1 = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
let body2 = "Test response 2".dataUsingEncoding(NSUTF8StringEncoding)!

let URL = NSURL(string: "https://www.example.com/1")!
let request = NSURLRequest.init(URL: URL)

// Mock calls to that request returning both responses in turn
NSURLSession.mockSingle(request, body: body1, delay: 1)
NSURLSession.mockSingle(request, body: body2, delay: 1)
```

To mock every call to a request, just use `mockEvery` instead:

```objc
NSURLSession.mockEvery(request, body: body, delay: 1)
```

The parameters `body` and `delay` are optional if you want you code to be a bit more succinct. i.e. to just return 200 with no data you can do:

```objc
NSURLSession.mockEvery(request)
```

To remove all the mocks (or just some of them) you can do


```objc
// Remove everything
NSURLSession.removeAllMocks()

// Remove all mocks matching a request
NSURLSession.removeAllMocks(of: request)
```

### AFNetworking

This pod is designed to be AFNetworking (~>2.0) friendly - mocks to NSURLSession will work via AFNetworking's `AFHTTPSessionManager` methods. Checkout `AFNetworkingTests.swift` for an example.


### NSURLConnection

If you're that way inclined, you can also use this to mock responses from `NSURLConnection`.

To mock the response of a URL:

```objc
let URL = NSURL(string: "https://www.example.com/1")!
let data = "test".dataUsingEncoding(NSUTF8StringEncoding)!
NSURLConnection.mockEvery(URL, data: data)
```

If you want to mock a sequence of responses to a URL, use mockSingle instead

```objc
let URL = NSURL(string: "https://www.example.com/2")!

let data1 = "some-data".dataUsingEncoding(NSUTF8StringEncoding)!
NSURLConnection.mockSingle(URL, data: data1)

let data2 = "some-more-data".dataUsingEncoding(NSUTF8StringEncoding)!
NSURLConnection.mockSingle(URL, data: data2)
```

If you want to test errors, pass an error instead of data

```objc
let URL = NSURL(string: "https://www.example.com/invalid/path")!
let error = NSError(domain: "TestDomain", code: 0, userInfo: nil)
NSURLConnection.mockEvery(URL, error: error)
```

To test a response that might take a long duration, there is an optional `delay` parameter. For example
this response will return an error after 10 seconds

```objc
let URL = NSURL(string: "https://www.example.com/invalid/path")!
let error = NSError(domain: "TestDomain", code: 0, userInfo: nil)
NSURLConnection.mockEvery(URL, error: error, delay: 10.0)
```

Removing all mocks

```objc
NSURLConnection.removeAllMocks()
```


### Example project

To run the example project, clone the repo, and run `pod install` from the Example directory first. This project contains a test suite that should show examples of how to use the pod.

## Installation

NSURLSession-Mock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NSURLSession-Mock"
```

## TODO:

+ mock all the convenience methods of NSURLSession (i.e. the ones which take in completion blocks)
+ Mock headers in a response instead of just the body
+ Mock status codes in a response
+ Allow a block instead of static NSData for body responses
+ Allow regular expression matches instead of fixed URLs when adding mocks

## Author

Sam Dean, sam.dean@net-a-porter.com

## License

NSURLSession-Mock is available under the Apache license. See the LICENSE file for more info.
