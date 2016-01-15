# NSURLConnection-Mock

[![CI Status](http://img.shields.io/travis/net-a-porter-mobile/NSURLConnection-Mock.svg?style=flat)](https://travis-ci.org/Sam Dean/NSURLConnection-Mock)
[![Version](https://img.shields.io/cocoapods/v/NSURLConnection-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLConnection-Mock)
[![License](https://img.shields.io/cocoapods/l/NSURLConnection-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLConnection-Mock)
[![Platform](https://img.shields.io/cocoapods/p/NSURLConnection-Mock.svg?style=flat)](http://cocoapods.org/pods/NSURLConnection-Mock)

## Usage

This pod is designed to help during functional testing by returning canned responses to URLs requested by the app.

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

### Example project

To run the example project, clone the repo, and run `pod install` from the Example directory first. This project contains a test suite that should show examples of how to use the pod.

## Installation

NSURLConnection-Mock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NSURLConnection-Mock"
```

## Author

Sam Dean, sam.dean@net-a-porter.com

## License

NSURLConnection-Mock is available under the Apache license. See the LICENSE file for more info.
