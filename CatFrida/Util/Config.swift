//
//  Config.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/24.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import Cocoa

struct Config {
    static var codeFont: NSFont {
        return codeFont(of: 14)
    }
    
    static func codeFont(of size: CGFloat) -> NSFont {
        return NSFont(name: "Consolas", size: size) ?? NSFont.systemFont(ofSize: size)
    }
}
