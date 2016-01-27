import ObjectiveC
import Foundation

private var entries: [MockEntry] = []

public extension NSURLConnection {
    
    private class func addMockEntry(entry: MockEntry) {
        // If we are not mocking any URLs, then we need to swizzle right now.
        self.swizzleIfNeeded()
        
        entries.append(entry)
    }

    /**
     For each call to a given URL, return the specified NSData to the connection's delegate.
     */
    public class func mockEvery(URL: NSURL, data: NSData, headers: [String: String] = [:], statusCode: Int = 200, delay: Double = MockEntry.DefaultDelay) {
        let response = MockResponse(data: data, error: nil, headers: headers, statusCode: statusCode)
        let entry = MockEntry.everyURL(URL, withResponse: response, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     For a single call to a given URL, return the specified NSData to the connection's delegate.
     */
     public class func mockSingle(URL: NSURL, data: NSData, headers: [String: String] = [:], statusCode: Int = 200, delay: Double = MockEntry.DefaultDelay) {
        let response = MockResponse(data: data, error: nil, headers: headers, statusCode: statusCode)
        let entry = MockEntry.singleURL(URL, withResponse: response, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     Return an error from the given URL each time it's called
     */
    public class func mockEvery(URL: NSURL, error: NSError, headers: [String: String] = [:], statusCode: Int = 400, delay: Double = MockEntry.DefaultDelay) {
        let response = MockResponse(data: nil, error: error, headers: headers, statusCode: statusCode)
        let entry = MockEntry.everyURL(URL, withResponse: response, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     Return an error from the given URL the first time it's called
     */
    public class func mockSingle(URL: NSURL, error: NSError, headers: [String: String] = [:], statusCode: Int = 400, delay: Double = MockEntry.DefaultDelay) {
        let response = MockResponse(data: nil, error: error, headers: headers, statusCode: statusCode)
        let entry = MockEntry.singleURL(URL, withResponse: response, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     Remove all mocked URL responses
     */
    public class func removeAllMocks() {
        entries = []
    }
    
    // MARK: - Swizzling utils
    
    private class func swizzleIfNeeded() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            try! swizzle(self, replace: "start", with: "swizzledStart")
            try! swizzle(self, replace: "initWithRequest:delegate:", with: "swizzledInitWithRequest:delegate:")
            
            Log("NSURLConnection now mocked")
        }
        
    }
    
    // MARK: - Internal properties
    
    private struct AssociatedKeys {
        static var DelegateKey = "DelegateKey"
    }
    
    private var delegate: AnyObject? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.DelegateKey)
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.DelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    // MARK: - Swizzled methods
    
    @objc(swizzledStart)
    private func swizzledStart() {
        for entry in entries {
            if entry.URL == self.currentRequest.URL {
                
                // If this is a single entry then we should remove it from the
                // entries array.
                if entry.isSingle {
                    let index = entries.indexOf { $0 == entry }
                    entries.removeAtIndex(index!)
                }
                
                // If the delegate isn't set correctly, bail
                guard let delegate = self.delegate as? NSURLConnectionDataDelegate else {
                    return
                }
                
                // Mock the callbacks for a successful response, but use the
                // mock entry's data
                let mult = Double(NSEC_PER_SEC)
                let timeDelta = 0.05
                var time = entry.delay
                let queue = dispatch_get_main_queue()
                
                // What kind of response is this, data or error?
                if let data = entry.response.data {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                        let response = NSHTTPURLResponse(URL: entry.URL, statusCode: entry.response.statusCode, HTTPVersion: "HTTP/1.1", headerFields: entry.response.headers)!
                        delegate.connection?(self, didReceiveResponse: response)
                    }
                    
                    time += timeDelta

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                        delegate.connection?(self, didReceiveData: data)
                    }
                
                    time += timeDelta
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                        delegate.connectionDidFinishLoading?(self)
                    }
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                        let response = NSHTTPURLResponse(URL: entry.URL, statusCode: entry.response.statusCode, HTTPVersion: "HTTP/1.1", headerFields: entry.response.headers)!
                        delegate.connection?(self, didReceiveResponse: response)
                    }
                    
                    time += timeDelta
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                        delegate.connection?(self, didFailWithError: entry.response.error!)
                    }
                }
                return
            }
        }
        
        // If we get here then the URL isn't a mocked one and we should just be
        // a normal NSURLConnection
        self.swizzledStart()
    }
    
    // We swizzle this init method so that we can grab the delegate as it passes
    // by
    @objc(swizzledInitWithRequest:delegate:)
    private func swizzledInit(request: NSURLRequest, delegate: AnyObject) -> Self {
        self.delegate = delegate
        return self.swizzledInit(request, delegate: delegate)
    }
    
}
