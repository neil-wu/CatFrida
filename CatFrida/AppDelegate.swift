//
//  AppDelegate.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/16.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        Hud.initHud()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

