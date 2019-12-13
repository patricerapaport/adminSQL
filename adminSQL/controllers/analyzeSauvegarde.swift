//
//  analyzeSauvegarde.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 26/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class cTable {
    var name: String
    var count: Int = 0
    init(_ name: String) {
        self.name = name
    }
}

extension Notification.Name {
    static let majCtrlBdd   = Notification.Name("majCtrlBdd")
}

class analyzeSauvegarde: NSWindowController {
    var fileName: String
    var bddName: String!
    var colsIndexes: NSIndexSet!
    var moderators = [cTable]()
    var theReader: CLineRead!
    
    @IBOutlet weak var crtlSauvegarde: NSTextField!
    @IBOutlet weak var ctrlBddname: NSTextField!
    @IBOutlet weak var table: NSTableView!
    @IBOutlet weak var waitAnimator: NSProgressIndicator!
    @IBOutlet weak var outline: NSOutlineView!
    
    init (_ fileName: String) {
        self.fileName = fileName
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fileName = ""
        super.init(coder: coder)
    }
    
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
        window?.title = fileName
        waitAnimator.startAnimation(self)
        NotificationCenter.default.addObserver(self, selector: #selector(majCtrlBdd(_:)), name: .majCtrlBdd, object: nil)
        crtlSauvegarde.stringValue = fileName
        colsIndexes = NSIndexSet( indexesIn: NSMakeRange(0, table.numberOfColumns))
        table.dataSource = self
        table.delegate = self
        let queue = DispatchQueue(label: "PR.adminSQL", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        queue.async {
            self.start()
        }
        //Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(start), userInfo: nil, repeats: false)
    }
    
     @objc func start () {
        let dir = FileManager.default.homeDirectoryForCurrentUser.path + "/Documents"
        let path = dir + "/" + fileName
        //guard let aReader = CLineRead(path: path) else {
        //    return
        //}
        //aReader.read()
        theReader = CLineRead(path: path)
        if theReader != nil {
            theReader.read()
        }
        
        guard let reader = LineReader(path: path) else {
            return; // cannot open file
        }
        
        var newTable: cTable!
        var insertInto = false
        
        var lines = [NSAttributedString]()
        
        for line in reader {
            lines.append(NSAttributedString(string: line))
            var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if bddName == nil {
                if !text.contains("Create schema") {
                    continue
                }
                let range = text.range(of: "-- Create schema")
                text.removeSubrange(range!)
                bddName = text
                NotificationCenter.default.post(name: .majCtrlBdd, object: self, userInfo: nil)
            } else if newTable == nil {
                if !text.contains("Definition of table") {
                    continue
                }
                let range = text.range(of: "-- Definition of table ")
                text.removeSubrange(range!)
                let parts = text.components(separatedBy: ".")
                let substr = parts[1].dropFirst().dropLast()
                newTable = cTable(String(substr))
                moderators.append(newTable)
                if moderators.count == 1 {
                    DispatchQueue.main.async {
                        self.table.reloadData()
                    }
                } else {
                    let rowIndexes = NSIndexSet( indexesIn: NSMakeRange(moderators.count-1, 1))
                    DispatchQueue.main.async {
                        self.table.reloadData(forRowIndexes: rowIndexes as IndexSet, columnIndexes: self.colsIndexes as IndexSet)
                        self.table.scrollRowToVisible(self.table.numberOfRows-1)
                    }
                }
            } else {
                if text.contains("UNLOCK TABLES;") {
                    let rowIndexes = NSIndexSet( indexesIn: NSMakeRange(moderators.count-1, 1))
                    DispatchQueue.main.async {
                        self.table.reloadData(forRowIndexes: rowIndexes as IndexSet, columnIndexes: self.colsIndexes as IndexSet)
                        self.table.scrollRowToVisible(self.table.numberOfRows-1)
                    }
                    newTable = nil
                } else if text.contains("INSERT INTO") {
                    insertInto = true
                } else if insertInto {
                    newTable.count += 1
                    insertInto = !text.contains(";")
                    if !insertInto {
                        let rowIndexes = NSIndexSet( indexesIn: NSMakeRange(moderators.count-1, 1))
                        DispatchQueue.main.async {
                            self.table.reloadData(forRowIndexes: rowIndexes as IndexSet, columnIndexes: self.colsIndexes as IndexSet)
                            self.table.scrollRowToVisible(self.table.numberOfRows-1)
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async {
            self.table.reloadData()
            self.outline.dataSource = self
            self.outline.delegate = self
            self.outline.reloadData()
            self.waitAnimator.stopAnimation(self)
            self.waitAnimator.isHidden = true
        }
    }
}

//MARK: affichages
extension analyzeSauvegarde {
    @objc func majCtrlBdd (_ notification: Notification) {
        DispatchQueue.main.async {
            self.ctrlBddname.stringValue = self.bddName
        }
    }
}

// MARK: tableViewDelegate
extension analyzeSauvegarde: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return moderators.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier)!.rawValue), owner: self) as! NSTableCellView? {
            
            switch tableColumn?.identifier.rawValue {
            case "tblname":
                cell.textField?.stringValue = moderators[row].name
            case "count":
                cell.textField?.stringValue = moderators[row].count == 0 ? "" : String(moderators[row].count)
                tableView.scrollRowToVisible(row)
            default:
                break
            }
            return cell
        }
        return nil
    }
}

//MARK: outlineDelegate et Datasource
extension analyzeSauvegarde: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1
        } else if item is CLineDatabase {
            return (item as! CLineDatabase).tables!.count
        } else if item is CLigne {
            return (item as! CLigne).nblines
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return theReader!.databaseName()
        } else if item is CLineDatabase {
            return (item as! CLineDatabase).tables![index]
        } else {
            return ""
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is CLineDatabase {
            return (item as! CLineDatabase).tables!.count > 0
        } else if item is CLigne {
            return (item as! CLigne).nblines > 1
        } else {
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "noeud"), owner: self) as? NSTableCellView
        if item is CLineDatabase {
            view?.textField?.stringValue = (item as! CLineDatabase).name
        } else if item is CLineTable {
            view?.textField?.stringValue = (item as! CLineTable).name
        } else {
            Swift.print(item)
        }
        return view
    }
}
