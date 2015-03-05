//
//  FluxTests.swift
//  FluxTests
//
//  Created by Dallin Lauritzen on 3/4/15.
//  Copyright (c) 2015 Dallin Lauritzen. All rights reserved.
//

import Cocoa
import XCTest

class FluxTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDecodeInt() {
        if let data = "i42e".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let result = bencoding_decode(data) as? NSNumber {
                XCTAssert(result == 42, "Expected 42. Got \(result)")
            }
            else {
                XCTFail("Result nil or not a number")
            }
        }
        else {
            XCTFail("Could not create test data")
        }
    }
    
    func testDecodeStr() {
        if let data = "5:hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let s = bencoding_decode(data) as? String {
                XCTAssert(s == "hello", "Expected 'hello'. Got \(s)")
            }
            else {
                XCTFail("Result nil or not String")
            }
        }
        else {
            XCTFail("Could not create test data")
        }
    }
    
    func testDecodeList() {
        if let data = "li42e6:dalline".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let result = bencoding_decode(data) as? [AnyObject] {
                XCTAssert(result.count == 2, "List should have two elements. Has \(result.count)")
                if let n = result[0] as? Int {
                    XCTAssert(n == 42, "First element should be 42. Got \(n)")
                }
                else {
                    XCTFail("Could not extract Int from first element")
                }
                if let s = result[1] as? String {
                    XCTAssert(s == "dallin", "Second element should be 'dallin'. Got \(s)")
                }
                else {
                    XCTFail("Could not extract String from second element")
                }
            }
            else {
                XCTFail("Result nil or not an array")
            }
        }
        else {
            XCTFail("Could not create test data")
        }
    }
    
    func testDecodeDict() {
        if let data = "d1:ai1e1:bi2ee".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let result = bencoding_decode(data) as? [NSObject:AnyObject] {
                XCTAssert(result.count == 2, "Dict should have two elements. Has \(result.count)")
                var i = 0
                var g = result.generate()
                if let (key, value: AnyObject) = g.next() {
                    switch i {
                    case 0:
                        XCTAssert(key == "a", "First key should be 'a'. Got \(key)")
                        XCTAssert((value as? NSNumber) == 1, "First value should be 1. Got \(value)")
                    case 1:
                        XCTAssert(key == "b", "Second key should be 'b'. Got \(key)")
                        XCTAssert((value as? NSNumber) == 2, "Second value should be 2. Got \(value)")
                        break
                    default:
                        XCTFail("Dict should have two elements.")
                    }
                    i++
                }
            }
            else {
                XCTFail("Result nil or not an array.")
            }
        }
        else {
            XCTFail("Could not create test data")
        }
    }
    
    func testUnderconsume() {
        if let data = "5:too many chars".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let result: AnyObject? = bencoding_decode(data)
            XCTAssert(result == nil, "Decode should fail")
        }
        else {
            XCTFail("Could not create test data")
        }
    }
    
    func testOverconsume() {
        if let data = "200:abc".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let result: AnyObject? = bencoding_decode(data)
            XCTAssert(result == nil, "Decode should fail")
        }
        else {
            XCTFail("Could not create test data")
        }
    }
    
    func testDecodeFile() {
        let bundle = NSBundle(forClass: NSClassFromString(self.className))
        if let filePath = bundle.pathForResource("ubuntu-14.10-desktop-amd64.iso.torrent", ofType: nil) {
            if let fileData = NSData(contentsOfFile: filePath) {
                if let result: AnyObject = bencoding_decode(fileData) {
                    NSLog("Result: \(result)")
                    XCTAssertEqual(result["announce"] as String, "http://torrent.ubuntu.com:6969/announce", "")
                    XCTAssertEqual(result["creation date"] as Int, 1414070124, "")
                }
                else {
                    XCTFail("Decode returned nil.")
                }
            }
            else {
                XCTFail("Could not read test file.")
            }
        }
        else {
            XCTFail("Could not find test file.")
        }
    }
    
    func testEncodeInt() {
        let testInt = 42
        if let result = bencoding_encode(testInt) {
            let s = NSString(data: result, encoding: NSUTF8StringEncoding)!
            XCTAssert(s == "i\(testInt)e", "Expected i\(testInt)e. Got \(s)")
        }
        else {
            XCTFail("Failed to encode \(testInt)")
        }
    }
    
    func testEncodeStr() {
        let testString = "Dallin Lauritzen"
        let l = testString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        if let result = bencoding_encode(testString) {
            let s = NSString(data: result, encoding: NSUTF8StringEncoding)!
            XCTAssert(s == "\(l):\(testString)", "Expected \(l):\(testString). Got \(s)")
        }
        else {
            XCTFail("Failed to encode \"\(testString)\"")
        }
    }
    
    func testEncodeList() {
        let testList = ["abc", "def", 42]
        let testResult = "l3:abc3:defi42ee"
        if let result = bencoding_encode(testList) {
            let s = NSString(data: result, encoding: NSUTF8StringEncoding)!
            XCTAssert(s == testResult, "Expected \(testResult). Got \(s)")
        }
        else {
            XCTFail("Failed to encode \(testList)")
        }
    }
    
    func testEncodeDict() {
        let testDict = ["a": 5, "b": "c", "d": [1]]
        let testResult = "d1:ai5e1:b1:c1:dli1eee"
        if let result = bencoding_encode(testDict) {
            let s = NSString(data: result, encoding: NSUTF8StringEncoding)!
            XCTAssert(s == testResult, "Expected \(testResult). Got \(s)")
        }
        else {
            XCTFail("Failed to encode \(testDict)")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
