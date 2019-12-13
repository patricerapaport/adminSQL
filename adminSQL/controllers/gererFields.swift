//
//  gererFields.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 09/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class gererFields: parentWC {
    var server: Server!
    var table: TablesModel!
    var limitDonnees: Int = 20
    var queue: DispatchQueue!
    var avecNumrow: Bool = false
    
    @IBOutlet weak var tableFields: NSTableView!
    @IBOutlet weak var tableIndexes: NSTableView!
    @IBOutlet weak var tableDonnees: CTableView!
    @IBOutlet weak var scrollViewDonnees: NSScrollView!
    @IBOutlet weak var donnesWaitAnimator: NSProgressIndicator!
    
    init(_ server: Server, _ table: TablesModel) {
        self.server = server
        self.table = table
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        self.server = nil
        self.table = nil
        super.init(coder: coder)
    }
    
    deinit {
        self.table = nil
        self.server = nil
        if queue != nil {
            queue = nil
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "Structure de " + table.tblname + " sur " + server.nom! + "." + table.dbname
        
        tableFields.delegate = self
        tableFields.dataSource = self
        tableIndexes.delegate = self
        tableIndexes.dataSource = self
        tableDonnees.delegate = self
        tableDonnees.dataSource = self
        tableDonnees.scrollViewDelegate = self
avecNumrow = true
        if table.fields.count == 0 {
            FieldsModel().fetch(server.adresse!, table.dbname, table.tblname, {
                result in
                switch result {
                case .failure:
                    DispatchQueue.main.async {
                    }
                    
                case .success(let response):
                    DispatchQueue.main.async {
                        let rep = response as! FieldsResponse
                        self.table.fields.append(FieldsModel())
                        self.table.fields.append(contentsOf: rep.moderators)
                        self.tableFields.reloadData()
                        if self.table.indexes.count == 0 {
                            self.askForIndexes()
                        } else {
                            self.tableIndexes.reloadData()
                        }
                    }
                    
                }
                
            })
        } else {
            DispatchQueue.main.async {
                self.tableFields.reloadData()
                self.tableIndexes.reloadData()
                self.preparerTableDonnees()
            }
        }
    }
   
    func askForIndexes() {
        IndexesModel().fetch(server.adresse!, table.dbname, table.tblname, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    _ = messageBox("Impossible de lire les index", withOK: true).runModal()
                }
            case .success(let response):
                let rep = response as! IndexesResponse
                self.table.indexes.append(IndexesModel())
                self.table.indexes.append(contentsOf: rep.moderators)
                self.tableIndexes.reloadData()
                self.preparerTableDonnees()
            }
        })
    }
    
    func preparerTableDonnees() {
        donnesWaitAnimator.startAnimation(self)
        for column in tableDonnees.tableColumns {
            tableDonnees.removeTableColumn(column)
        }
        if avecNumrow {
            let column = CTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "_nrow"))
            column.width = 60
            column.setTitle("row", .right)
            tableDonnees.addTableColumn(column)
        }
        for index in 1...table.fields.count-1 {
            let field = table.fields[index]
            let column = CTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: field.Field))
            column.width = field.Tipe == "N" ? 60 : 120
            column.setTitle(field.Field, field.Tipe == "N" ? .right: .left)
            tableDonnees.addTableColumn(column)
        }

        if table.currentPage == nil {
            table.currentPage = 0
            table.limit = tableDonnees.nbRowsAffichees()
            table.nbPagesInMemory = 3
        }
        table.initialFetch(tableDonnees, server.adresse!, completion: {
            res in
            self.donnesWaitAnimator.stopAnimation(self)
        })
        
    }
}

// MARK: TabviewDelegate
extension gererFields: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if tabViewItem!.identifier as! String == "indexes" {
            if tableIndexes.numberOfRows == 0 {
                DispatchQueue.main.async {
                    self.tableIndexes.reloadData()
                }
            }
        } else if tabViewItem!.identifier as! String == "data" {
            if tableDonnees.numberOfRows == 0 {
                DispatchQueue.main.async {
                    self.tableDonnees.reloadData()
                }
            }
        }
    }
}

// MARK: ScrollViewDelegate
extension gererFields: CScrollViewDelegate {
    func scroll(_ tableView: CTableView, _ sens: Int, _ delta: CGFloat) {
        return
        if tableView == tableDonnees {
            if sens == 1 {
                //table.premiereRangeeAffichee -= Int(floor(delta))
                let nbLignesDemandees = Int(ceil(-delta))
                Swift.print("table.indexPage = \(table.indexPage)")
                Swift.print("on veut descendre de \(nbLignesDemandees) lignes")
                let indexPage = table.indexPage + nbLignesDemandees
                let lastIndex = indexPage + table.limit
                Swift.print("indexpage devient donc: \(indexPage)")
                Swift.print("la dernière ligne affichée sera \(lastIndex)")
                Swift.print("indexPage + data.count = \(indexPage + table.data.count)")
                if !table.rowLoaded(lastIndex) {
                    Swift.print("Cette dernière ligne n'est pas en mémoire")
                } else {
                    Swift.print("Cette dernière ligne est en mémoire on va donc réaffichier les lignes de \(indexPage) à \(lastIndex)")
                    tableView.beginUpdates()
                    var first: Int!
                    var last: Int!
                    for index in indexPage...lastIndex {
                        if index >  indexPage+table.limit-1 {
                            if first == nil {
                                first = index-1
                            }
                            last = index-1
                        }
                    }
                    Swift.print("va construire indexset en \(String(describing: first))...\(String(describing: last))")
                    //tableView.insertRows(at: NSIndexSet(indexesIn: NSRange(first...last)) as IndexSet, withAnimation: .slideDown)
                    table.indexPage = first
                    tableView.endUpdates()
                    tableView.reloadData(forRowIndexes: NSIndexSet(indexesIn: NSRange(indexPage...lastIndex)) as IndexSet, columnIndexes: NSIndexSet(indexesIn: NSRange(0...tableView.tableColumns.count-1)) as IndexSet)
                    tableView.scrollRowToVisible(lastIndex)
                }
            } else {
                //if table.premiereRangeeAffichee > 0 {
                //    table.premiereRangeeAffichee += Int(ceil(delta))
                //}
            }
            //let pageDemandee = table.pageDemandee(table.premiereRangeeAffichee)
            return
            if sens == 1 {
                TableModel().fetchData(server.adresse!, table.dbname, table.tblname, limitDonnees, 1+table.currentPage, {
                    res, dict in
                    if res {
                        if self.table.data == nil {
                            self.table.data = [NSDictionary]()
                        }
                        //self.table.totalEnreg = dict!["total"] as? Int
                        self.table.data.append(contentsOf: dict!["items"] as! [NSDictionary])
                        self.table.indexPage = self.table.currentPage
                        self.table.currentPage += 1
                        self.tableDonnees.reloadData()
                    }
                })
            }
        }
    }
    
    func resizeView(_ tableView: CTableView) {
        Swift.print("resize: \(tableDonnees.nbRowsAffichees())")
    }
    
}


// MARK: TableviewDelegate
extension gererFields: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if table == nil {
            return 0
        } else {
            if tableView == tableFields {
                return table.fields.count > 0 ? table.fields.count-1 : 0
            } else if tableView == tableIndexes {
                return table.indexes.count > 0 ? table.indexes.count-1 : 0
            } else {
                if table.totalEnreg == nil {
                    return 0
                } else {
                    return table.totalEnreg
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return false
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView != tableDonnees {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier)!.rawValue), owner: self) as! NSTableCellView? {
            
            if tableView == tableFields {
                switch tableColumn?.identifier.rawValue {
                case "field":
                    cell.textField?.stringValue = table.fields[row+1].Field
                case "tipe":
                    cell.textField?.stringValue = table.fields[row+1].sqlTipe
                case "collation":
                    cell.textField?.stringValue = table.fields[row+1].collation
                case "null":
                    cell.textField?.stringValue = table.fields[row+1].Null
                case "defaut":
                    cell.textField?.stringValue = table.fields[row+1].Default
                case "extra":
                    cell.textField?.stringValue = table.fields[row+1].Extra
                default:
                    break
                }
            } else if tableView == tableIndexes {
                switch tableColumn?.identifier.rawValue {
                case "keyname":
                    cell.textField?.stringValue = table.indexes[row+1].keyname
                case "sequence":
                    cell.textField?.stringValue = String(table.indexes[row+1].sequence)
                case "colonne":
                    cell.textField?.stringValue = table.indexes[row+1].column
                default:
                    break
                }
            }
            return cell
            }
            return nil
        } else {
            if avecNumrow && tableColumn == tableView.tableColumns[0] {
                let textfield = NSTextField(string: String(row))
                textfield.isBordered = false
                textfield.alignment = .right
                let cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: 17))
                cell.addSubview(textfield)
                (cell.subviews[0] as! NSTextField).alignment = .right
                cell.textField = textfield
                cell.textField?.stringValue = String(row)
                cell.textField?.alignment = .right
                
                return cell
            }
            if table.fetchingData {
    if tableColumn == tableView.tableColumns[0] {
    Swift.print("row \(row) table isFecthing data0,,")
    }
                return nil
            }
            if !table.rowLoaded(row) {
                if tableColumn == tableView.tableColumns[avecNumrow ? 1 : 0] {
                    donnesWaitAnimator.startAnimation(self)
                    queue = DispatchQueue(label: "PR.adminSQL.fetch", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                    queue.async {
                        self.table!.fetch(tableView, row, completion: {
                            res in
                            DispatchQueue.main.async {
                                self.donnesWaitAnimator.stopAnimation(self)
                                self.queue = nil
                            }
                        })
                    }
                }
                return nil
            }
            
if row > table.indexPage+table.data.count-1 {
    Swift.print("Il y a un loupé pour row:\(row)")
    return nil
}
            
            let dict = table.data[row-table.indexPage]
            var valeur = dict[tableColumn?.identifier.rawValue ?? ""]
            if valeur is NSNull {
                valeur = ""
            } else {
                valeur = valeur == nil ? "" : valeur as! String
            }
            
            //let textfield = NSTextField(string: tableColumn is CTableColumn ? (tableColumn as! CTableColumn).cellValue(valeur as! String) : valeur as! String)
            
            let textfield = NSTextField(string: valeur as! String)
            textfield.isBordered = false
            if tableColumn! is CTableColumn {
                textfield.alignment = (tableColumn as! CTableColumn)._alignment
                textfield.frame.size.width = (tableColumn?.width)!-8
                textfield.frame.origin.x = 4
            }
            let cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: 17))
            cell.addSubview(textfield)
            return cell
        }
    }
    
}

