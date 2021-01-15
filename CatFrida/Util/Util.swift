//
//  Config.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/17.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import Cocoa

typealias NWVoidBlock = () ->(Void);
typealias NWIntBlock = (Int) ->(Void);
typealias NWSuccessBlock = (Bool) ->(Void);
typealias NWStringBlock = (String) ->(Void);
typealias NWStringArrayBlock = ([String]) ->(Void);
typealias NWIndexPathBlock = (IndexPath) ->(Void);
typealias NWDateBlock = (Date) ->(Void);

/*
enum CEvt: String {
    //case defaultScriptDestroyed = "CEvtDefaultScriptDestroyed"
    
    var notify : Notification.Name  {
        return Notification.Name(rawValue: self.rawValue )
    }
}*/

@discardableResult
func showAlert(question: String, text: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = NSAlert.Style.warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
}



struct Util {
    static func readbleByteSize(_ byteCount: Int64) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll] // optional: restricts the units to MB only
        bcf.countStyle = .file
        let str: String = bcf.string(fromByteCount: byteCount)
        return str
    }
    
    
    static func copyStr(_ str: String) {
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
}
