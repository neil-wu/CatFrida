//
//  Hud.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/11.
//  Copyright © 2021 nw. All rights reserved.
//

import Foundation
import AppKit

final class Hud {
    
    static func initHud() {
        FNHUD.setup()
    }
    
    static func toast(_ str: String, in root: NSView?) {
        if let root = root {
            DispatchQueue.main.async {
                FNHUD.showMessage(str, in: root)
            }
        }
    }
}

extension NSView {
    func toast(_ str: String) {
        Hud.toast(str, in: self)
    }
}

extension NSViewController {
    func toast(_ str: String) {
        Hud.toast(str, in: self.view)
    }
    func showLoading(tip: String?) {
        let msg: String = tip ?? ""
        DispatchQueue.main.async {
            FNHUD.showLoading(msg, in: self.view)
        }
    }
    
    func hideLoading(tip: String?) {
        FNHUD.hide()
        if let tip = tip, !tip.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.toast(tip)
            }
        }
    }
}
