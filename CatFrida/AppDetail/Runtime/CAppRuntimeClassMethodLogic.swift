//
//  CAppRuntimeClassMethodLogic.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/7.
//  Copyright © 2021 nw. All rights reserved.
//

import Foundation
import AppKit

final class CAppRuntimeClassMethodLogic: NSObject, NSTabViewDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    var methodList:[String] = []
    var protoList:[String] = []
    var classTypeName: String = ""
    
    var protoDesc: String {
        return protoList.joined(separator: ", ")
    }
    
    func bindTable(_ table: NSTableView) {
        table.delegate = self
        table.dataSource = self
    }
    
    func updateInfo(_ info: NSDictionary, type: String) {
        classTypeName = type
        
        if let arr = info["methods"] as? [String] {
            methodList = arr
        }
        
        if let arr = info["proto"] as? [String] {
            protoList = arr
        }
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return methodList.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCell"
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        let name = methodList[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = name
            cellIdentifier = CellIdentifiers.NameCell
        }
        
        // 3
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier);
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.toolTip = text;
            return cell
        }
        
        return nil;
    }
    
    
    func makeDumpDesc() -> String {
        let str: String = "\(classTypeName) : \(protoDesc)\n" + methodList.joined(separator: "\n")
        return str
    }
    
}
