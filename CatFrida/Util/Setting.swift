//
//  Setting.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/24.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

fileprivate enum Key: String {
    case customScriptPath = "customScriptPath"
    case customScriptCmd = "customScriptCmd"
}

final class Setting {
    static let shared: Setting = Setting();
    
    init() {
        self.customScriptPath = UserDefaults.standard.string(forKey: Key.customScriptPath.rawValue) ?? "";
        self.customScriptCmd = UserDefaults.standard.string(forKey: Key.customScriptCmd.rawValue) ?? "";
    }
    
    
    var customScriptPath: String {
        didSet {
            UserDefaults.standard.set(customScriptPath, forKey: Key.customScriptPath.rawValue);
            UserDefaults.standard.synchronize();
        }
    }
    
    var customScriptCmd: String {
        didSet {
            UserDefaults.standard.set(customScriptCmd, forKey: Key.customScriptCmd.rawValue);
            UserDefaults.standard.synchronize();
        }
    }
    
}


