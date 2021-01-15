//
//  CScript.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/20.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation


enum CScriptType: Equatable {
    case testSendOK // just for test
    case testException // just for test
    case testRpc // just for test
    
    case defaultScript // default script, _agent.js
    
    case appInfoDictionary
    case appModule
    case appDataDirectory
    case custom(content:String)
    
    var content: String {
        switch self {
        case .testSendOK:
            return "send('test')"; // test ok
        case .testException:
            return "ObjC.classesNotExists.error;send('fail');"; // test exception
        case .testRpc:
            return "rpc.exports = { add: function(a, b){return a + b;} };"; // test exception
        case .appInfoDictionary:
            return "send(ObjC.classes.NSUserDefaults.alloc().init().dictionaryRepresentation());";
        case .appDataDirectory:
            return "send(ObjC.classes.NSProcessInfo.processInfo().environment().objectForKey_('HOME').toString());"
        case .appModule:
            return "send(Process.enumerateModulesSync());";
        case .defaultScript:
            guard let path = Bundle.main.path(forResource: "_agent", ofType: "js") else {
                Log("fail to load default script, err 1")
                return "";
            }
            guard let content:String = try? String(contentsOfFile: path) else {
                Log("fail to load default script, err 2")
                return "";
            }
            return content;
        case .custom(let content):
            return content;
        }
    }
    
    var typeID: Int {
        switch self {
        case .testSendOK: return 1;
        case .testException: return 2;
        case .testRpc: return 3;
        case .appInfoDictionary: return 4;
        case .appDataDirectory: return 5;
        case .appModule: return 6;
        case .defaultScript: return 7;
        case .custom(let content):
            return content.hash;
        }
    }
    
    static func ==(lhs: CScriptType, rhs: CScriptType) -> Bool {
        return lhs.typeID == rhs.typeID;
    }
}


