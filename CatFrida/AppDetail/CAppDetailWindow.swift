//
//  CAppDetailWindow.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/20.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import Cocoa

final class CAppDetailWindow: NSWindowController {
    
    deinit {
        print("~~~ CAppDetailWindow")
        if let vc = self.contentViewController as? CAppDetailViewController {
            vc.releaseRes();
        }
    }
    override func windowDidLoad() {
        super.windowDidLoad();
        
        //self.window?.title = "hello";
    }
    
    
    
}
