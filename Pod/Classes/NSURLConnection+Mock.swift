private var isSwizzled = false

private var entries = Array<MockEntry>()

public extension NSURLConnection {

    public func mock(URL: NSURL, response: NSData) {
        // If we are not mocking any URLs, then we need to swizzle right now.
        self.swizzleIfNeeded()
        
        // Add this URL and response into the list of mocked responses
        
    }
    
    private func swizzleIfNeeded() {
        if !isSwizzled { return }
        isSwizzled = true
        
        
    }
    
}
