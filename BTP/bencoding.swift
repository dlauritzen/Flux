//
//  bencoding.swift
//  Flux
//
//  Created by Dallin Lauritzen on 3/4/15.
//  Copyright (c) 2015 Dallin Lauritzen. All rights reserved.
//

import Foundation

// MARK: Public

public func bencoding_decode(data : NSData) -> AnyObject? {
    let length = data.length
    if length == 0 {
        return nil
    }
    let original = UnsafePointer<UInt8>(data.bytes)
    var bytes = UnsafePointer<UInt8>(data.bytes)
    let ret: AnyObject? = read_any(&bytes)
    let read = original.distanceTo(bytes)
    if read != length {
        if read < length {
            NSLog("Leftover data after decode. Read \(read) of \(length) bytes.")
        }
        else {
            NSLog("Data overconsumed. Read \(read) of \(length) bytes.")
        }
        return nil
    }
    return ret
}

public func bencoding_encode(obj : AnyObject) -> NSData? {
    return dump_any(obj)
}

// MARK: Decode

private func atoi(a : UInt8) -> Int {
    return Int(a) - 48
}

private func read_int(inout data : UnsafePointer<UInt8>) -> Int? {
    var ret : Int = 0
    var negative = false
    reading: while true {
        let c = data.memory
        data = data.advancedBy(1)
        switch c {
        case 45: // '-': Negative number
            negative = true
        case 101: // 'e': End of Int
            break reading
        case 48...57: // digit
            let v = atoi(c)
            ret = (ret * 10) + v
        default:
            NSLog("Invalid Int. Expected digit, got \(c).")
            return nil
        }
    }
    return ret
}

private func read_dict(inout data : UnsafePointer<UInt8>) -> [NSObject:AnyObject]? {
    var ret : [NSObject:AnyObject] = [:]
    while let key = read_any(&data) as? String {
        if let value : AnyObject = read_any(&data) {
            ret[key] = value
        }
        else {
            NSLog("Error reading value.")
            return nil
        }
    }
    return ret
}

private func read_list(inout data : UnsafePointer<UInt8>) -> [AnyObject]? {
    var ret : [AnyObject] = []
    while let obj : AnyObject = read_any(&data) {
        ret.append(obj)
    }
    return ret
}

private func read_data(inout data : UnsafePointer<UInt8>) -> AnyObject? {
    var len = 0
    readinglen: while true {
        let c = data.memory
        data = data.advancedBy(1)
        switch c {
        case 58: // ':': end of string length
            break readinglen
        case 48...57: // digit
            len = (len * 10) + atoi(c)
        default: // Invalid
            NSLog("Invalid data while reading string length. Expected digit, got \(c).")
            return nil
        }
    }
    let ret = NSData(bytes: data, length: len)
    data = data.advancedBy(len)
    if let s = NSString(data: ret, encoding: NSUTF8StringEncoding) {
        return s
    }
    else {
        return ret
    }
}

private func read_any(inout data : UnsafePointer<UInt8>) -> AnyObject? {
    let c = data.memory
    switch c {
    case 100: // 'd': Dictionary
        data = data.advancedBy(1)
        return read_dict(&data)
    case 108: // 'l': List
        data = data.advancedBy(1)
        return read_list(&data)
    case 105: // 'i': Integer
        data = data.advancedBy(1)
        return read_int(&data)
    case 101: // 'e': End of object
        data = data.advancedBy(1)
        return nil
    case 48...57: // digit: String
        // Do not advance, since the digit is part of the data
        return read_data(&data)
    default:
        NSLog("Invalid data. Expected type (d,l,i,0-9), got \(c)")
        return nil
    }
}

// MARK: Encode

private func dump_int(n : Int) -> NSData? {
    return NSString(format: "i%de", n).dataUsingEncoding(NSUTF8StringEncoding)
}

private func dump_str(s : String) -> NSData? {
    return dump_data(s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
}

private func dump_data(d : NSData) -> NSData? {
    let lenChars = Int(ceil(log10(Float(d.length)))) // Bytes necessary to represent the data length in decimal chars
    let length = lenChars + 1 + d.length // size of length + ':' + data
    var ret = NSMutableData(capacity: length)
    ret?.appendData(NSString(format: "%d:", d.length).dataUsingEncoding(NSUTF8StringEncoding)!)
    ret?.appendData(d)
    return ret
}

private func dump_list(l : [AnyObject]) -> NSData? {
    var data = NSMutableData(data: "l".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    for x in l {
        if let d = dump_any(x) {
            data.appendData(d)
        }
        else {
            return nil
        }
    }
    data.appendData("e".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    return data
}

private func dump_dict(d : [String:AnyObject]) -> NSData? {
    var data = NSMutableData(data: "d".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    // Keys MUST be sorted
    let keys = d.keys.array.sorted { (a: String, b: String) -> Bool in
        return a < b
    }
    for key in keys {
        if let keyData = dump_str(key) {
            data.appendData(keyData)
            if let valueData = dump_any(d[key]!) {
                data.appendData(valueData)
            }
            else {
                NSLog("Error serializing value for key \(key).")
                return nil
            }
        }
        else {
            NSLog("Error serializing key \(key).")
            return nil
        }
    }
    data.appendData("e".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    return data
}

private func dump_any(x : AnyObject) -> NSData? {
    if let s = x as? String {
        return dump_str(s)
    }
    if let l = x as? [AnyObject] {
        return dump_list(l)
    }
    if let d = x as? [String:AnyObject] {
        return dump_dict(d)
    }
    if let n = x as? Int {
        return dump_int(n)
    }
    return nil
}
