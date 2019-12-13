//
//  parentWC.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 30/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class parentWC: NSWindowController {
    public var errorPopover: NSPopover!
    var controls = [NSControl]()
    var currentControl: NSControl!
    var _eventMonitor: Any!
    var _isModal = false
    
    override open var windowNibName: NSNib.Name? {
        let els = className.components(separatedBy: ".")
        if els.count > 1 {
            return els[1]
        } else {
            return els[0]
        }
    }
    
    func closeWindow (){
        NotificationCenter.default.removeObserver(self)
        if _eventMonitor != nil {
            NSEvent.removeMonitor(_eventMonitor as Any)
        }
        if _isModal {
            myApp.stopModal()
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        addControls((window?.contentView)!)
    }
    
    func addControls(_ aContainer: NSView) {
        for control in aContainer.subviews {
            if control is controlProtocol {
                (control as! controlProtocol).parent = self
            }
            if control.subviews.count > 0 {
                addControls(control)
            } else {
                if control is NSControl {
                    controls.append(control as! NSControl)
                }
            }
        }
    }
}

//MARK: Gestion erreurs
extension parentWC {
    public func erreurSaisie(_ aControl: NSControl, _ aText: String) {
        if errorPopover == nil {
            let errorController = cErrorController()
            errorController.setError(aText)
            errorPopover = NSPopover()
            errorPopover.contentViewController = errorController
        }
        errorPopover.show(relativeTo: aControl.bounds, of: aControl, preferredEdge: NSRectEdge(rawValue: 0)!)
    }
    
    public func masquerErreurSaisie() {
        if errorPopover != nil &&  errorPopover.isShown {
            errorPopover.close()
            errorPopover = nil
        }
    }
    
    @objc func delayFocus(_ aControl: NSControl, _ aText: String) {
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(aControl)
            self.erreurSaisie(aControl, aText)
        }
    }
    
    @objc open func verifControl(_ aControl: NSControl) {
        masquerErreurSaisie()
    }
}

//MARK: Gestion comboboxes
extension parentWC {
    @objc func comboSelectionDisdChange (_ aCombo: CComboBox) {
        
    }
}

//MARK: NSWindowDelegate
extension parentWC: NSWindowDelegate {
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeWindow()
        return true
    }
}
