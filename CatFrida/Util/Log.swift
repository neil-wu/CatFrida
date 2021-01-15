//
//  Log.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/17.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

fileprivate func LogTime() -> String {
    let currentDate = Date()
    let dateFormatter = DateFormatter();
    //dateFormatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai")
    //dateFormatter.locale = Locale(identifier: "zh")
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let convertedDate: String = dateFormatter.string(from: currentDate)
    return convertedDate;
}

enum LogLevel {
    case debug
    case info
    case error
}

#if DEBUG
func Log(_ msg: String, level:LogLevel = .info, file: String = #file, method: String = #function, line: Int = #line) {
    
    //let str = "\((file as NSString).lastPathComponent)[\(line)], \(method): \(msg)";
    //let str = "\(method): \(msg)";
    var filename = file.components(separatedBy: "/").last ?? "unknowfile"
    filename = filename.components(separatedBy: ".").first ?? filename
    let methodPrefix: String = method.components(separatedBy: "(").first ?? method
    //let str: String = "[\(LogTime())][\(filename) \(methodPrefix)] \(msg)";
    let str: String = "[\(filename) \(methodPrefix)]\(msg)";
    
    //globalCacheLog.addElement(str);
    #if DEBUG
    //    DDLogInfo(str);
    print("[\(LogTime())]" + str)
    #endif
}
func LogError(_ msg: String, file: String = #file, method: String = #function, line: Int = #line) {
    #if DEBUG
    let prefix: String = "[error]🛑"
    #else
    let prefix: String = "[error]"
    #endif
    
    Log(prefix + msg, level: .error, file: file, method: method, line: line)
}
#else
func Log(_ msg: String, level:LogLevel = .info) {
    
}

func LogError(_ msg: String) {
    #if DEBUG
    let prefix: String = "[error]🛑"
    #else
    let prefix: String = "[error]"
    #endif
    
    Log(prefix + msg, level: .error)
}
#endif


#if DEBUG
func LogDebug(_ msg: String, file: String = #file, method: String = #function, line: Int = #line) {
    Log("[debug]" + msg, level: .debug, file: file, method: method, line: line)
}
#else
func LogDebug(_ msg: String) {
} // for release
#endif

func Log(_ obj: NSObject,
         file: String = #file,
         method: String = #function,
         line: Int = #line) {
    #if DEBUG
    Log(obj.description, file: file, method: method, line: line);
    #endif
}






