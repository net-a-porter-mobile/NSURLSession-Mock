import UIKit
import XCTest
import NSURLConnection_Mock

class Tests: XCTestCase {
    
    class URLConnectionDelegate : NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
        
        var response: NSURLResponse?
        var data: NSMutableData?
        
        let complete: () -> ()
        
        init(complete: () -> ()) {
            self.complete = complete
        }
        
        func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
            self.response = response
        }
        
        func connection(connection: NSURLConnection, didReceiveData data: NSData) {
            if self.data == nil {
                self.data = NSMutableData()
            }
            self.data!.appendData(data)
        }
        
        func connectionDidFinishLoading(connection: NSURLConnection) {
            self.complete()
        }
    }
    
    func test_WithMockURL_ShouldReturnMockedData() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock this URL
        let URL = NSURL(string: "https://www.example.com/1")!
        let data = "test".dataUsingEncoding(NSUTF8StringEncoding)!
        NSURLConnection.mock(URL, data: data)
        
        // Make a delegate we will inspect at the end of the test
        let delegate = URLConnectionDelegate(complete: {
            expectation.fulfill()
        })
        
        // Make the request
        let request = NSURLRequest(URL: URL)
        let connection = NSURLConnection.init(request: request, delegate: delegate)
        XCTAssertNotNil(connection)
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(data, delegate.data)
        }
    }
    
}
