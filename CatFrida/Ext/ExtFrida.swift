//
//  ExtFrida.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/17.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

extension Device {
    
    var cfShowingName: String {
        return "\(self.kind):\(self.name)(\(self.id))";
    }
    
}

extension ApplicationDetails {
    
    var cfIsAppleSysApp: Bool {
        return self.identifier.hasPrefix("com.apple")
    }
    
    func cfContains(str: String) -> Bool {
        return self.name.contains(str) || self.identifier.contains(str)
    }
    
}



