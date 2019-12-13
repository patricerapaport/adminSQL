//
//  messageBox.swift
//  essaiIntegre
//
//  Created by Patrice Rapaport on 30/09/2018.
//  Copyright © 2018 Patrice Rapaport. All rights reserved.
//

import AppKit

open class messageBox {
    var alert: NSAlert!
    
    public init (_ aMsg: String) {
        alert = NSAlert()
        alert.informativeText = ""
        alert.messageText = aMsg
        alert.addButton(withTitle: "Non")
        alert.addButton(withTitle: "Oui")
    }
    
    public init (_ aMsg: String, withOK: Bool) {
        alert = NSAlert()
        alert.informativeText = ""
        alert.messageText = aMsg
        alert.addButton(withTitle: "OK")
    }
    
    public func runModal() -> Bool {
        if alert.buttons.count == 2 {
            if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                return true
            } else {
                return false
            }
        } else {
            alert.runModal()
            return true
        }
    }
}
