//
//  CTableView.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 16/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import AppKit

protocol CScrollViewDelegate {
    func scroll(_ tableView: CTableView, _ sens: Int, _ delta: CGFloat)
    func resizeView(_ tableView: CTableView)
}

class CTableColumn: NSTableColumn {
    var _alignment: NSTextAlignment = .left
    
    func setTitle (_ text: String, _ align: NSTextAlignment) {
        _alignment = align
        if _alignment == .left {
            headerCell.attributedStringValue = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 13)])
        } else {
            let paragrapheStyleRight = NSMutableParagraphStyle()
            paragrapheStyleRight.alignment = .right
            headerCell.attributedStringValue = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 13), NSAttributedString.Key.paragraphStyle: paragrapheStyleRight])
        }
    }
    
    func cellValue (_ str: String) -> NSAttributedString {
        if _alignment == .left {
            return NSAttributedString(string: str, attributes: [:])
        } else {
            let paragrapheStyleRight = NSMutableParagraphStyle()
            paragrapheStyleRight.alignment = .right
            return NSAttributedString(string: str, attributes: [NSAttributedString.Key.paragraphStyle: paragrapheStyleRight])
        }
    }
}

class CTableView: NSTableView {
    var scrollViewDelegate: CScrollViewDelegate!
    var cDatasource: CDatasource!
var enumerated = false
    
    func nbRowsAffichees() -> Int {
        var iRes = 0
        iRes = Int(superview!.frame.size.height / rowHeight)-1
        Swift.print ("nbRowsAffichées: \(iRes)")
        return iRes
    }
    
    override func scrollLineDown(_ sender: Any?) {
        Swift.print("scrollLineDown")
    }
    
    override func scrollLineUp(_ sender: Any?) {
        Swift.print("scrollLineUp")
    }
    
    override func scrollWheel(with event: NSEvent) {
        //Swift.print("scrollWheel \(event)")
if !enumerated {
//enumerated = true
//        enumerateAvailableRowViews(availableRowView)
}
        if scrollViewDelegate != nil &&  event.deltaY != 0 {
            scrollViewDelegate.scroll(self, event.deltaY < 0 ? 1 : 0, event.deltaY)
        }
        
        super.scrollWheel(with: event)
    }
    
    override func viewDidEndLiveResize() {
        if scrollViewDelegate != nil {
            scrollViewDelegate.resizeView(self)
        }
        super.viewDidEndLiveResize()
        Swift.print("viewDidEndLiveResize \(frame)")
    }
    
    func availableRowView(_ view: NSTableRowView, row: Int) {
        Swift.print("availableRowView \(row)")
    }
    
    //override func draw(_ dirtyRect: NSRect) {
        //super.draw(dirtyRect)
        //nbRowsAffichees()
    //}
    
}
