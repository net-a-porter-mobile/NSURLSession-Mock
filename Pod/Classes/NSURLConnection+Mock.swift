import ObjectiveC
import Foundation

private var entries: Array<MockEntry> = []

public extension NSURLConnection {
    
    private class func addMockEntry(entry: MockEntry) {
        // If we are not mocking any URLs, then we need to swizzle right now.
        self.swizzleIfNeeded()
        
        entries.append(entry)
    }

    /**
     For each call to a given URL, return the specified NSData to the connection's delegate.
     */
    public class func mockEvery(URL: NSURL, data: NSData, delay: Double = MockEntry.DefaultDelay) {
        let entry = MockEntry.everyURL(URL, withData: data, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     For a single call to a given URL, return the specified NSData to the connection's delegate.
     */
     public class func mockSingle(URL: NSURL, data: NSData, delay: Double = MockEntry.DefaultDelay) {
        let entry = MockEntry.singleURL(URL, withData: data, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     Return an error from the given URL each time it's called
     */
    public class func mockEvery(URL: NSURL, error: NSError, delay: Double = MockEntry.DefaultDelay) {
        let entry = MockEntry.everyURL(URL, withError: error, delay: delay)
        self.addMockEntry(entry)
    }
    
    /**
     Return an error from the given URL the first time it's called
     */
    public class func mockSingle(URL: NSURL, error: NSError, delay: Double = MockEntry.DefaultDelay) {
        let entry = MockEntry.singleURL(URL, withError: error, delay: delay)
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
            
            print("NSURLConnection now mocked")
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
    func swizzledStart() {
        for entry in entries {
            if entry.URL == self.currentRequest.URL {
                
                // If this is a single entry then we should remove it from the
                // entries array.
                if entry.isSingle {
                    let index = entries.indexOf { $0 == entry }
                    entries.removeAtIndex(index!)
                }
                
                // Mock the callbacks for a successful response, but use the
                // mock entry's data
                if let delegate = self.delegate as? NSURLConnectionDataDelegate {
                    let mult = Double(NSEC_PER_SEC)
                    let timeDelta = 0.05
                    var time = entry.delay
                    let queue = dispatch_get_main_queue()
                    
                    // What kind of response is this, data or error?
                    if let data = entry.data {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                            let response = NSURLResponse(URL: entry.URL, MIMEType: nil, expectedContentLength: data.length, textEncodingName: nil)
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
                            let response = NSURLResponse(URL: entry.URL, MIMEType: nil, expectedContentLength: 1000, textEncodingName: nil)
                            delegate.connection?(self, didReceiveResponse: response)
                        }
                        
                        time += timeDelta
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(mult * time)), queue) {
                            delegate.connection?(self, didFailWithError: entry.error!)
                        }
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
    func swizzledInit(request: NSURLRequest, delegate: AnyObject) -> Self {
        self.delegate = delegate
        return self.swizzledInit(request, delegate: delegate)
    }
    
}
