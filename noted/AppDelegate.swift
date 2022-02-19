//
//  AppDelegate.swift
//  noted
//
//  Created by kazuyuki takahashi on 2022/02/13.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        do {
            try stores().save()
        } catch let e {
            NSAlert(error: e).runModal()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

