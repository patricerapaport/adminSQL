//
//  errorController.swift
//  essaiIntegre
//
//  Created by Patrice Rapaport on 29/09/2018.
//  Copyright © 2018 Patrice Rapaport. All rights reserved.
//

import Cocoa

class cErrorController: NSViewController {
    var textField: NSTextField?
    var errorText: String = ""
    
    override func loadView() {
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.yellow.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField = NSTextField()
        let font = textField?.font
        let attributes = [NSAttributedString.Key.font: font!] as [NSAttributedString.Key : Any]
        let size = (errorText as NSString).size(withAttributes: attributes)
        
        textField!.frame = NSRect(x: 2, y: 2, width: size.width+4, height: size.height)
        textField!.isBezeled = false
        textField!.drawsBackground = true
        textField!.backgroundColor = NSColor.clear
        textField!.isEditable = false
        textField!.isSelectable = false
        textField!.stringValue = errorText
        
        view.frame = CGRect(origin: .zero, size: CGSize(width: size.width+10, height: size.height+4))
        self.view.addSubview(textField!)
    }

    func setError(_ msg: String) {
        errorText = msg
    }
}
