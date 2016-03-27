# NSURLSession-Mock

[![CI Status](http://img.shields.io/travis/net-a-porter-mobile/NSURLSession-Mock.svg?style=flat)](https://travis-ci.org/net-a-porter-mobile/NSURLSession-Mock)
[![Version](https://img.shields.io/cocoapods/v/NSURLSession-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLSession-Mock)
[![License](https://img.shields.io/cocoapods/l/NSURLSession-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLSession-Mock)
[![Platform](https://img.shields.io/cocoapods/p/NSURLSession-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLSession-Mock)
[![BADGINATOR](https://badginator.herokuapp.com/net-a-porter-mobile/NSURLSession-Mock.svg)](https://github.com/defunctzombie/badginator)

## Usage

This pod is designed to help during functional testing by returning canned responses to URLs requested by the app.

### NSURLSession

To mock a single request use `mockNext` - this method can be called multiple times and the responses will be returned in the same order they were added in:

```objc
let body1 = "Test response 1".dataUsingEncoding(NSUTF8StringEncoding)!
let body2 = "Test response 2".dataUsingEncoding(NSUTF8StringEncoding)!

let URL = NSURL(string: "https://www.example.com/1")!
let request = NSURLRequest.init(URL: URL)

// Mock calls to that request returning both responses in turn
NSURLSession.mockNext(request, body: body1, delay: 1)
NSURLSession.mockNext(request, body: body2, delay: 1)
```


To mock every call to a request, just use `mockEvery` instead:

```objc
NSURLSession.mockEvery(request, body: body, delay: 1)
```

The parameters `body` and `delay` are optional if you want you code to be a bit more succinct. i.e. to just return 200 with no data you can do:

```objc
NSURLSession.mockEvery(request)
```

Ephemeral mocks have priority over permanent mocks. This is to say that, if you were to add permanent and ephemeral mocks for the same request, the ephemeral mocks would be returned and consumed first.

If you want your response to depend on the URL called, you can pass in a function like this:

```objc
let URL = NSURL(string: "https://www.example.com/product/([0-9]{6})")!
let request = NSURLRequest.init(URL: URL)

// Return a valid test product JSON response with the correct pid
NSURLSession.mockEvery(request) { (matches:[String]) in
    let pid = matches.first!
    return "{ 'productId':'\(pid)', 'description':'This is a test product' }".datawithEncoding(UTF8StringEncoding)!
}
```

To remove all the mocks (or just some of them) you can do


```objc
// Remove everything
NSURLSession.removeAllMocks()

// Remove all mocks matching a request
NSURLSession.removeAllMocks(of: request)
```

If you would like to fail requests that haven't been mocked, set the NSURLSession's request evaluator to return whether or not the requests must be allowed. For example, to ensure that all calls to Net-A-Porter's domain are mocked you would:

```swift
NSURLSession.requestEvaluator = { request in
    guard let url = request.URL else { return .Reject }

    return url.host == "www.net-a-porter.com" ? .Reject : .PassThrough
}

```

If a request to www.net-a-porter.com is made and not mocked, an exception will be raised.

### AFNetworking

This pod is designed to be AFNetworking (~>2.0) friendly - mocks to NSURLSession will work via AFNetworking's `AFHTTPSessionManager` methods. Checkout `AFNetworkingTests.swift` for an example.


### Example project

To run the example project, clone the repo, and run `pod install` from the Example directory first. This project contains a test suite that should show examples of how to use the pod.

## Installation

NSURLSession-Mock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NSURLSession-Mock"
```

## Author

Sam Dean, sam.dean@net-a-porter.com

## License

NSURLSession-Mock is available under the Apache license. See the LICENSE file for more info.
