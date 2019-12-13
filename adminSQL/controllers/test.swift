//
//  test.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 13/12/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class test: NSWindowController {
    
    
    override open var windowNibName: NSNib.Name? {
        let els = className.components(separatedBy: ".")
        if els.count > 1 {
            return els[1]
        } else {
            return els[0]
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
       
    
    }
    @IBAction func Tester(_ sender: Any) {
        Swift.print("test activé")
    }
  
    
}
