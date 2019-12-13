//
//  CTextFields.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 28/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import AppKit

@IBDesignable class CTextfield: NSTextField, controlProtocol {
    var _parent: parentWC!
    var _obligatoire = false
    
    var parent: parentWC? {
        get {
            return _parent
        }
        set {
            _parent = newValue
        }
    }
    
    @IBInspectable var obligatoire: Bool {
        get {
            return _obligatoire
        }
        set (aValue) {
            _obligatoire = aValue
        }
    }
    
    var controller: parentWC? {
        get {
            return _parent!
        }
    }
    
    override open func becomeFirstResponder() -> Bool {
        if _parent.currentControl != nil && _parent.currentControl != self {
            var indexControl: Int = -1
            var indexCurrent: Int = -1
            for ix in 0..._parent.controls.count-1 {
                if _parent.controls[ix] == self {
                    indexControl = ix
                }
                if _parent.controls[ix] == _parent.currentControl {
                    indexCurrent = ix
                }
                if indexControl != -1 && indexCurrent != -1 {
                    break
                }
            }
            if indexCurrent < indexControl {
                _parent.verifControl(_parent.currentControl)
            } else {
                _parent.masquerErreurSaisie()
            }
        }
        let bRes = super.becomeFirstResponder()
        if bRes {
            _parent.currentControl = self
        }
        return bRes
    }
}

extension CTextfield {
    func verifControl() -> String? {
        if obligatoire && stringValue == "" {
            return "Zone obligatoire"
        } else {
            return nil
        }
    }
}
