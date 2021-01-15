//
//  ExtApp.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/17.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import AppKit

extension Array {
    func nwOptionObj(at index: Int) -> Element? {
        if (index >= 0 && index < self.count) {
            return self[index];
        }
        return nil;
    }
}

extension NSDictionary {
    func getString(by key:String) -> String {
        if let str = self.object(forKey: key) as? String {
            return str
        }
        return ""
    }
    
    func printableDesc() -> String {
        let desc = self.description
        
        if let cstr = desc.cString(using: .utf8) {
            return String(cString: cstr, encoding: String.Encoding.nonLossyASCII) ?? desc
        }
        return desc
    }
}


extension String {
    
    
    func ifEmpty(_ place: String) -> String {
        if self.isEmpty {
            return place
        }
        return self;
    }
    func subString(from: Int, to: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[startIndex...endIndex])
    }
    func charStr(at idx: Int) -> String {
        if idx >= self.count {
            return ""
        }
        let tmpidx = self.index(self.startIndex, offsetBy: idx)
        return String(self[tmpidx...tmpidx])
    }
    func nwStipHTMLTags() -> String {
        let str = self.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil);
        return str;
    }
    
    func nwUrlEncode() -> String? {
        let unreserved = "-._~"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet);
    }
    
    
    func nwPureStrBy(prefix: String, suffix: String, suffixPureOffset: Int) -> String? {
        
        var nsstr: NSString = self as NSString;
        let firstrange: NSRange = nsstr.range(of: prefix); //
        if (firstrange.location == NSNotFound) {
            //Log("firstrange is nil, fail to find");
            return nil;
        }
        nsstr = nsstr.substring(from: firstrange.location) as NSString;
        let secondrange: NSRange = nsstr.range(of: suffix);
        if (secondrange.location == NSNotFound) {
            //Log("secondrange is nil, fail to parse");
            return nil;
        }
        nsstr = nsstr.substring(to: secondrange.location + suffixPureOffset) as NSString;
        
        let tmpstr: String = nsstr as String;
        return tmpstr;
    }
    
    /// SwifterSwift: Removes given prefix from the string.
    ///
    ///   "Hello, World!".removingPrefix("Hello, ") -> "World!"
    ///
    /// - Parameter prefix: Prefix to remove from the string.
    /// - Returns: The string after prefix removing.
    public func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    
    /// SwifterSwift: Removes given suffix from the string.
    ///
    ///   "Hello, World!".removingSuffix(", World!") -> "Hello"
    ///
    /// - Parameter suffix: Suffix to remove from the string.
    /// - Returns: The string after suffix removing.
    public func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
    /// SwifterSwift: Check if string contains one or more instance of substring.
    ///
    ///        "Hello World!".contain("O") -> false
    ///        "Hello World!".contain("o", caseSensitive: false) -> true
    ///
    /// - Parameters:
    ///   - string: substring to search for.
    ///   - caseSensitive: set true for case sensitive search (default is true).
    /// - Returns: true if string contains one or more instance of substring.
    public func contains(_ string: String, caseSensitive: Bool = true) -> Bool {
        if !caseSensitive {
            return range(of: string, options: .caseInsensitive) != nil
        }
        return range(of: string) != nil
    }
    
    var containsChineseCharacters: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
    var asciiString: String {
        //返回该字符串中的ascii字符组成的string
        let fstr: String = self.filter { (ch:Character) -> Bool in
            return ch.isASCII;
        }
        return fstr;
    }
}


func NSColorFromRGB(_ rgbValue: UInt, alpha: CGFloat = 1.0) -> NSColor {
    let r: UInt = (rgbValue & 0xFF0000) >> 16;
    let g: UInt = (rgbValue & 0x00FF00) >> 8;
    let b: UInt = rgbValue & 0x0000FF;
    return NSColor(
        red: CGFloat(r) / 255.0,
        green: CGFloat(g) / 255.0,
        blue: CGFloat(b) / 255.0,
        alpha: alpha
    )
}

