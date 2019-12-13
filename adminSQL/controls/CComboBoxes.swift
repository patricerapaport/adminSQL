//
//  CComboBoxes.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 30/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class cComboOption {
    var cle: String
    var valeur: String
    
    init (key: String, value: String) {
        cle=key
        valeur=value
    }
    
    func equal (key: String)->Bool {
        return key == cle
    }
    
    func equal (value: String) ->Bool {
        return valeur == value
    }
    
    func equalsPartiel (partialValue: String) -> String? {
        //let index = valeur.index(valeur.startIndex, offsetBy: partialValue.count)
        if partialValue.lowercased() == valeur.substr(0, partialValue.count-1).lowercased() {
            return valeur
        }
        return nil
    }
}

class CComboBox: NSComboBox, controlProtocol {
    var _options: [cComboOption]!
    var _parent: parentWC!
    
    var parent: parentWC? {
        get {
            return _parent
        }
        set {
            _parent = newValue
        }
    }
    
    func setDatasource (_ source: [cComboOption]) {
        _options = source
        dataSource = self
        delegate   = self
    }
    
    var controller: parentWC? {
        get {
            return _parent!
        }
    }
    
    func verifControl() -> String? {
        return nil
    }
}

//MARK: Gestion des index
extension CComboBox {
    // retourne l'index pour une valeur donnée
    func getIndex(valeur: String) -> Int {
        if _options != nil && (_options?.count)! > 0 {
            for i in 0...(_options?.count)!-1 {
                if (_options?[i].equal(value: valeur))! {
                    return i
                }
            }
        } else {
            return -1
        }
        return -1
    }
    
    func getIndex() -> Int {
        return getIndex(valeur: stringValue)
    }
    
    func selectionDidChange() {
        _parent.comboSelectionDisdChange(self)
    }
    
    func selectbyText(_ str: String) {
        for index in 0..._options.count-1 {
            if _options[index].equal(value: str) {
                self.selectItem(at: index)
                return
            }
        }
    }
}

//MARK: Datasource et Delegate
extension CComboBox: NSComboBoxDelegate, NSComboBoxDataSource {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if _options == nil {
            return 0
        } else {
            return _options.count
        }
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if _options == nil  || index == -1 {
            return super.itemObjectValue(at: index)
        } else if (_options?.count)! > index {
            return _options?[index].valeur
        } else {
            return ""
        }
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return getIndex(valeur: string)
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        _parent.comboSelectionDisdChange(notification.object as! CComboBox)
    }
    
    //optional public func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String?
}
