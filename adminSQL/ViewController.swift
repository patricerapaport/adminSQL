//
//  ViewController.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 17/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let maxChargements = 1
    var databases: [DatabasesModel]!
    var tables: [TablesModel]!
    var total: Int!
    var nbTables: Int!
    var currentPage = 1
    @IBOutlet weak var tableDB: NSTableView!
    @IBOutlet weak var tableTbl: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Chargements(0)
    }
    deinit {
        databases.removeAll()
        tables.removeAll()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    open func Chargements (_ numrequete: Int) {
        if numrequete < maxChargements {
            let client = DatabasesModel()
            client.fetch({
                result in
                switch result {
                // 3
                case .failure:
                    DispatchQueue.main.async {
                    }
                // 4
                case .success(let response):
                    DispatchQueue.main.async {
                        let rep = response as! DatabasesResponse
                        self.currentPage += 1
                        
                        self.databases = [DatabasesModel]()
                        self.total = rep.total
                        self.databases.append(contentsOf: rep.moderators)
                        self.tableDB.delegate = self
                        self.tableDB.dataSource = self
                        self.tableDB.reloadData()
                    }
                    
                }
            })
            Chargements(numrequete+1)
        }
    }
}

extension ViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tableDB {
        return total != nil ? total : 0
        } else if tableView == tableTbl {
            return nbTables != nil ? nbTables : 0
        } else {
            return 0
        }
    }
}

extension ViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier)!.rawValue), owner: self) {
            if cell.subviews.count > 0 {
                if tableView == tableDB {
                    (cell.subviews[0] as! NSTextField).stringValue = databases[row].dbname
                } else if tableView == tableTbl {
                    (cell.subviews[0] as! NSTextField).stringValue = tables[row].tblname
                }
            }
            return cell
        } else {
            return nil
        }
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object is NSTableView &&  (notification.object as! NSTableView) == tableDB {
            let database = databases[tableDB.selectedRow].dbname
            (myApp.delegate as! AppDelegate).dbSelected = database
            TablesModel().fetch("127.0.0.1", database, {
                result in
                switch result {
                // 3
                case .failure:
                    DispatchQueue.main.async {
                    }
                // 4
                case .success(let response):
                    DispatchQueue.main.async {
                        let rep = response as! TablesResponse
                        self.currentPage += 1
                        
                        self.tables = [TablesModel]()
                        self.nbTables = rep.total
                        self.tables.append(contentsOf: rep.moderators)
                        self.tableTbl.delegate = self
                        self.tableTbl.dataSource = self
                        self.tableTbl.reloadData()
                    }
                    
                }
            })
        }
    }
}

