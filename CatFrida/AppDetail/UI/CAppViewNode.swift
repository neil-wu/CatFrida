//
//  CAppViewNode.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/12.
//  Copyright © 2021 nw. All rights reserved.
//

import Foundation

final class CAppViewNode: CustomStringConvertible {
    var depth: Int = 0
    var children:[CAppViewNode] = []
    var desc: String = ""
    
    init(depth: Int, desc: String) {
        self.depth = depth
        self.desc = desc
    }
    
    static func buildFrom(line: String) -> CAppViewNode? {
        guard line.starts(with: " ") else {
            // root node
            return CAppViewNode(depth: 0, desc: line)
        }
        
        guard let startIndex = line.firstIndex(of: "<") else {
            return nil
        }
        let prefix: String.SubSequence = line[..<startIndex]
        let desc: String = String(line[startIndex..<line.endIndex])
        var num: Int = 0
        prefix.forEach { (ch) in
            if (ch == "|") {
                num += 1
            }
        }
        return CAppViewNode(depth: num, desc: desc)
    }
    
    var description: String {
        return "\(desc)"
    }
    
    func dump() -> String {
        let intent: String = "  "
        let prefix: String = String(repeating: intent, count: depth)
        
        var str: String = prefix + desc
        for child in children {
            str = str + "\n" + intent + child.dump()
        }
        
        return str;
    }
}

