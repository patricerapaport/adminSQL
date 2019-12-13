//
//  FieldsTableCellView.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 04/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class FieldsTableCellView: NSTableCellView {
    @IBOutlet weak var tipe: NSTextField!
    @IBOutlet weak var isnull: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
