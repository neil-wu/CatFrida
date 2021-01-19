//
//  CAppRpc.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/11.
//  Copyright © 2021 nw. All rights reserved.
//

import Foundation

enum CAppRpc {
    case info //app info
    case modules
    case classes // all OC classes
    case ownClasses // app only classes
    case inspect(className: String)
    
    case ls(path: String)
    case appBundlePath
    case appDataPath
    case dumpdecrypted(module: String)
    case download(path: String)
    
    case exports(module: String)
    case imports(module: String)
    
    case cookies
    case dumpWindow
    case dumpKeyChain
    case userDefaults
    
    var rpcFuncName: String {
        switch self {
        case .info: return "info"
        case .modules: return "modules"
        case .classes: return "classes"
        case .ownClasses: return "ownClasses"
        case .inspect(_): return "inspect"
        case .ls(_): return "ls"
        case .appBundlePath: return "appBundlePath"
        case .appDataPath: return "appDataPath"
        case .dumpdecrypted(_): return "dumpdecrypted"
        case .download(_): return "download"
        case .exports(_): return "exports"
        case .imports(_): return "imports"
        case .cookies: return "cookies"
        case .dumpWindow: return "dumpWindow"
        case .dumpKeyChain: return "dumpKeyChain"
        case .userDefaults: return "userDefaults"
        }
    }
    var rpcFuncArgs:[Any] {
        switch self {
        case .inspect(let className): return [className]
        case .ls(let path): return [path]
        case .download(let path): return [path]
        case .dumpdecrypted(let module): return [module]
        case .exports(let module): return [module]
        case .imports(let module): return [module]
        default:
            return []
        }
    }
}
