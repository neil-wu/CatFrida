//
//  CMessage.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/20.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import HandyJSON


// send('xxx') => { payload = "xxx"; type = send; }
// console.log('yyy') => { payload = "yyy"; type = info; }
enum CMessageType: String, HandyJSONEnum {
    case send = "send"
    case info = "info"
    case error = "error"
    case log = "log"
    case unknow = ""
}


struct CMessage: HandyJSON {
    var type: CMessageType = CMessageType.unknow; // CMessageType
    var payload: Any? = nil;
    
    var strPayload: String? {
        return payload as? String;
    }
    var dictPayload: NSDictionary? {
        return payload as? NSDictionary;
    }
}

struct CMessagePayloadNetwork: HandyJSON {
    var url:String = "";
    var req: String = "";
    var rsp: String = "";
}

struct CMessagePayload: HandyJSON {
    enum DownloadEvent:String,HandyJSONEnum {
        case start = "start"
        case data = "data"
        case end = "end"
        case unknow = "unknow"
    }
    enum Subject: String, HandyJSONEnum {
        case download = "download"
        case hook = "hook"
        case network = "network"
        case unknow = "unknow"
    }
    var subject: Subject = Subject.unknow;
    var event: DownloadEvent = DownloadEvent.unknow;
    var session: String = "";
    var network: CMessagePayloadNetwork? = nil;
}

struct CMessageError: HandyJSON {
    var type: CMessageType = CMessageType.error;
    
    //for error
    var description: String = "";
    var fileName: String = "";
    var lineNumber: String = "";
    var columnNumber:Int = 0;
    var stack: String = "";
}


