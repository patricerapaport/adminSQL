//
//  main.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 27/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class CDatabases {
    var databases: [DatabasesModel]!
    var tables: [TableModel]!
    var total: Int!
    var nbTables: Int!
    var currentPage = 1
}

class mainController: parentWC {    
    var DBS = [String: CDatabases]()
    var queueNbtables: DispatchQueue!
    var queueShowTables: DispatchQueue!
    var queueNbrows: DispatchQueue!
    var queueFields: DispatchQueue!
    var imgBdd: NSImage!
    var imgTable: NSImage!
    var imgField: NSImage!
    var imgIndex: NSImage!
    var _internalJobSelection: Bool = false
    
    @IBOutlet weak var leftServeur: CComboBox!
    @IBOutlet weak var rightServer: CComboBox!
    @IBOutlet weak var leftTable: NSOutlineView!
    @IBOutlet weak var rightTable: NSOutlineView!
    @IBOutlet weak var leftIndicator: NSProgressIndicator!
    @IBOutlet weak var rightIndicator: NSProgressIndicator!
    @IBOutlet weak var btSauvegarde: NSToolbarItem!
    @IBOutlet weak var btStructure: NSToolbarItem!
    
    @IBOutlet weak var boxGauche: NSBox!
    @IBOutlet weak var boxDroite: NSBox!
    
    
    override open var windowNibName: NSNib.Name? {
        let els = className.components(separatedBy: ".")
        if els.count > 1 {
            return els[1]
        } else {
            return els[0]
        }
    }

    override func windowDidLoad() {
        window?.center()
        super.windowDidLoad()
        
        btSauvegarde.isEnabled = false
        btSauvegarde.action = nil
        btStructure.action = nil

        var options = [cComboOption]()
        if (myApp.delegate as! AppDelegate).servers != nil {
            options.append(cComboOption(key: "-1", value: ""))
            for index in 0...(myApp.delegate as! AppDelegate).servers.count-1 {
                options.append(cComboOption(key: String(index), value: (myApp.delegate as! AppDelegate).servers[index].nom!))
            }
        }
        leftServeur.setDatasource(options)
        rightServer.setDatasource(options)
        imgBdd = NSImage(imageLiteralResourceName: "bdd")
        imgTable = NSImage(imageLiteralResourceName: "table")
        imgField = NSImage(imageLiteralResourceName: "fields")
        imgIndex = NSImage(imageLiteralResourceName: "index")
        positionnerBoxes()
    }
    
    func positionnerBoxes() {
        let frame = window?.contentView!.frame
        let contrainteGauche = NSLayoutConstraint(item: boxGauche as Any, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: frame!.size.width/2)
        let contrainteDroite = NSLayoutConstraint(item: boxDroite as Any, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: frame!.size.width/2)
        window?.contentView?.addConstraints([contrainteGauche, contrainteDroite])
        window?.contentView!.updateConstraints()
        //boxGauche.layer?.frame.size.width = frame!.size.width / 2
        //boxGauche.updateLayer()
    }
    
    @IBAction func voirServeurs(_ sender: Any) {
        myApp.runModal(for: serversWindow().window!)
    }
    
    @IBAction @objc func lancerSauvegarde(_ sender: Any) {
        var combo: CComboBox!
        test().showWindow(self)
        return;
        let outline = leftTable.selectedRow != -1 ? leftTable : rightTable
        if leftTable.selectedRow == -1 && rightTable.selectedRow == -1 {
            combo = leftServeur.getIndex() != -1 ? leftServeur : rightServer
        } else {
            combo   = leftTable.selectedRow != -1 ? leftServeur : rightServer
        }
        let server = (myApp.delegate as! AppDelegate).servers[combo!.indexOfSelectedItem-1]
        if outline!.selectedRow != -1 {
            let database = outline!.item(atRow: outline!.selectedRow) as! DatabasesModel
            sauvegarde(server, database).showWindow(self)
        } else {
            let vc = sauvegarde(server)
            vc.showWindow(self)
        }
    }
    @IBAction func listeSauvegardes(_ sender: Any) {
        explorer().showWindow(self)
    }
    
    @IBAction func gererStructure(_ sender: Any) {
        let aCombo =  leftTable.selectedRow != -1 ? leftServeur : rightServer
        let outline = leftTable.selectedRow != -1 ? leftTable : rightTable
        let server = (myApp.delegate as! AppDelegate).servers[aCombo!.indexOfSelectedItem-1]
        let item = outline!.item(atRow: outline!.selectedRow)
        let table = item is TablesModel ? item : outline?.parent(forItem: item)
        gererFields(server, table as! TablesModel).showWindow(self)
    }
}

//MARK: Gestion comboBox
extension mainController {
    @objc override func comboSelectionDisdChange (_ aCombo: CComboBox) {
        // 1 ... déterminer l'adresse du serveur
        let server = (myApp.delegate as! AppDelegate).servers[aCombo.indexOfSelectedItem-1]
        let client = DatabasesModel()
        let indicator = aCombo == leftServeur ? leftIndicator : rightIndicator
        indicator?.startAnimation(self)
        client.fetch(server.adresse!, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    _ = messageBox("Impossible d'accéder aux BDD", withOK: true).runModal()
                    indicator?.stopAnimation(self)
                }
            case .success(let response):
                DispatchQueue.main.async {
                    self.btSauvegarde.isEnabled = true
                    self.btSauvegarde.action = #selector(self.lancerSauvegarde(_:))
                    let rep = response as! DatabasesResponse
                    let DB = CDatabases()
                    DB.currentPage += 1
                    
                    DB.databases = [DatabasesModel]()
                    DB.total = rep.total
                    DB.databases.append(contentsOf: rep.moderators)
                    let tbl: NSOutlineView!
                    let side: String!
                    if aCombo == self.leftServeur {
                        self.DBS["left"] = DB
                        tbl = self.leftTable
                        side = "left"
                    } else {
                        self.DBS["right"] = DB
                        tbl = self.rightTable
                        side = "right"
                    }
                    tbl.dataSource = self
                    tbl.delegate = self
                    tbl.reloadData()
                    self.queueNbtables = DispatchQueue(label: "PR.adminSQL", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                    self.queueNbtables.async {
                        self.askForNbtables(side, server.adresse!, 0)
                    }
                }
            }
        })
    }
}

//MARK: queues
extension mainController {
    func askForNbtables(_ side: String, _ adresse: String, _ row: Int) {
        let base = DBS[side]
        let db = base?.databases[row]
        let client = DatabasesModel()
        client.fetchShowNbtables(adresse, (db?.dbname)!, {
            result in
            switch result {
            case .failure :
                self.queueNbtables = nil
            case .success(let response):
                let rep = response as! DatabasesNbtablesResponse
                self.DBS[side]?.databases[row].nbTables = rep.nbtables
                let tbl = side == "left" ? self.leftTable : self.rightTable
                 DispatchQueue.main.async {
                    tbl?.reloadItem(db)
                }
                if row < (base?.databases.count)!-1 {
                    self.askForNbtables(side, adresse, row+1)
                } else {
                    let indicator = side == "left" ? self.leftIndicator : self.rightIndicator
                    indicator?.stopAnimation(self)
                    self.queueNbtables = nil
                }
            }
        })
    }
    
    func askForTables(_ side: String, _ adresse: String, _ dbname: String) {
        let indicator = side == "left" ? leftIndicator : rightIndicator
        DispatchQueue.main.async {
            if (indicator?.isIndeterminate)! {
                indicator?.startAnimation(self)
            }
        }
        TablesModel().fetch(adresse, dbname, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                }
            case .success(let response):
                DispatchQueue.main.async {
                    let rep = response as! TablesResponse
                    for db in (self.DBS[side]?.databases!)! {
                        if db.dbname == dbname {
                            db.tables = rep.moderators
                            for table in db.tables {
                                table.dbname = dbname
                            }
                            DispatchQueue.main.async {
                                let outline = side == "left" ? self.leftTable : self.rightTable
                                outline?.collapseItem(db)
                                outline?.expandItem(db)
                            }
                            break
                        }
                    }
                    
                    self.queueShowTables = nil
                    self.queueNbrows = DispatchQueue(label: "PR.adminSQL.nbrows", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                    self.queueNbrows.async {
                        self.askForNbenreg(side, adresse, dbname, 0)
                    }
                }
                
            }
        })
    }
    
    func askForNbenreg (_ side: String, _ adresse: String, _ dbname: String, _ row: Int) {
        for db in (DBS[side]?.databases)! {
            if db.dbname == dbname {
                TablesModel().fetchNbenreg(adresse, dbname, db.tables![row].tblname, {
                    result in
                    switch result {
                    case .failure:
                        DispatchQueue.main.async {
                        }
                    case .success(let response):
                        DispatchQueue.main.async {
                            let rep = response as! TablesNbenregResponse
                            db.tables![row].nbenreg = rep.nbenreg
                            DispatchQueue.main.async {
                                let outline = side == "left" ? self.leftTable : self.rightTable
                                outline?.reloadItem(db.tables[row])
                            }
                            if row < db.tables.count-1 {
                                self.askForNbenreg(side, adresse, dbname, row+1)
                            } else {
                                self.queueNbrows.async {
                                    self.askForNbfields(side, adresse, dbname, 0)
                                }
                            }
                        }
                    }
                })
                break
            }
        }
    }
    
    func askForNbfields (_ side: String, _ adresse: String, _ dbname: String, _ row: Int) {
        for db in (DBS[side]?.databases)! {
            if db.dbname == dbname {
                TablesModel().fetchNbfields(adresse, dbname, db.tables![row].tblname, {
                    result in
                    switch result {
                    case .failure:
                        DispatchQueue.main.async {
                        }
                    case .success(let response):
                        DispatchQueue.main.async {
                            let rep = response as! TablesNbenregResponse
                            db.tables![row].nbfields = rep.nbenreg
                            DispatchQueue.main.async {
                                let outline = side == "left" ? self.leftTable : self.rightTable
                                outline?.collapseItem(db)
                                outline?.expandItem(db)
                            }
                            if row < db.tables.count-1 {
                                self.askForNbfields(side, adresse, dbname, row+1)
                            } else {
                                DispatchQueue.main.async {
                                    let indicator = side == "left" ? self.leftIndicator : self.rightIndicator
                                    indicator?.stopAnimation(self)
                                }
                                self.queueNbrows = nil
                            }
                        }
                    }
                })
                break
            }
        }
    }
    
    func askForFields(_ side: String, _ adresse: String, _ item: TablesModel) {
        for db in (DBS[side]?.databases)! {
            if db.dbname == item.dbname {
                for index in 0...db.tables.count-1 {
                    if db.tables[index].tblname == item.tblname {
                        let indicator = side == "left" ? leftIndicator : rightIndicator
                        DispatchQueue.main.async {
                            if (indicator?.isIndeterminate)! {
                                indicator?.startAnimation(self)
                            }
                        }
                        FieldsModel().fetch(adresse, item.dbname, item.tblname, {
                            result in
                                switch result {
                                case .failure:
                                    DispatchQueue.main.async {
                                    }
                        
                                case .success(let response):
                                    DispatchQueue.main.async {
                                        let rep = response as! FieldsResponse
                                        db.tables[index].fields.append(FieldsModel())
                                        db.tables[index].fields.append(contentsOf: rep.moderators)
                                        //DispatchQueue.main.async {
                                        //    let outline = side == "left" ? self.leftTable : self.rightTable
                                        //    outline?.collapseItem(item)
                                        //    outline?.expandItem(item)
                                        //    let animator = side == "left" ? self.leftIndicator : self.rightIndicator
                                        //    animator?.stopAnimation(self)
                                        //}
                                        //self.queueFields = nil
                                        self.queueFields.async {
                                            self.askForIndexes(side, adresse, item)
                                        }
                                    }
                            }
                    
                        })
                        break
                    }
                }
            }
        }
    }
    
    func askForIndexes(_ side: String, _ adresse: String, _ item: TablesModel) {
        for db in (DBS[side]?.databases)! {
            if db.dbname == item.dbname {
                for index in 0...db.tables.count-1 {
                    if db.tables[index].tblname == item.tblname {
                        let indicator = side == "left" ? leftIndicator : rightIndicator
                        DispatchQueue.main.async {
                            if (indicator?.isIndeterminate)! {
                                indicator?.startAnimation(self)
                            }
                        }
                        IndexesModel().fetch(adresse, item.dbname, item.tblname, {
                            result in
                            switch result {
                            case .failure:
                                DispatchQueue.main.async {
                                }
                                
                            case .success(let response):
                                DispatchQueue.main.async {
                                    let rep = response as! IndexesResponse
                                    db.tables[index].indexes.append(IndexesModel())
                                    db.tables[index].indexes.append(contentsOf: rep.moderators)
                                    DispatchQueue.main.async {
                                        let outline = side == "left" ? self.leftTable : self.rightTable
                                        outline?.collapseItem(item)
                                        outline?.expandItem(item)
                                        let animator = side == "left" ? self.leftIndicator : self.rightIndicator
                                        animator?.stopAnimation(self)
                                    }
                                    self.queueFields = nil
                                }
                            }
                            
                        })
                        break
                    }
                }
            }
        }
    }
}

//MARK: tableDelegate et Datasource
extension mainController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if _internalJobSelection {
            _internalJobSelection = false
            return
        }

        let outline = notification.object as! NSOutlineView
        let exOutline = outline == leftTable ? rightTable : leftTable
        let item = outline.item(atRow: outline.selectedRow)
        btStructure.action = item is TablesModel || item is FieldsModel ? #selector(gererStructure(_:)) : nil
        if item is DatabasesModel {
            btSauvegarde.isEnabled = true
            btSauvegarde.action = #selector(lancerSauvegarde(_:))
        } else {
            btSauvegarde.isEnabled = false
            btSauvegarde.action = nil
            return
        }
        
        if exOutline?.selectedRow != -1 {
            _internalJobSelection = true
            exOutline?.deselectRow((exOutline?.selectedRow)!)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        let side = outlineView == leftTable ? "left" : "right"
        if item == nil {
            return (DBS[side]?.databases)!.count
        } else if item is CDatabases {
            return (DBS[side]?.databases)!.count
        } else if item is DatabasesModel {
            if (item as! DatabasesModel).tables.count == 0 && queueShowTables == nil {
                let aCombo = outlineView == leftTable ? leftServeur :rightServer
                let server = (myApp.delegate as! AppDelegate).servers[aCombo!.indexOfSelectedItem-1]
                queueShowTables = DispatchQueue(label: "PR.adminSQL.showTables", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                self.queueShowTables.async {
                    self.askForTables(side, server.adresse!, (item as! DatabasesModel).dbname)
                }
                return 0
            } else {
                return (item as! DatabasesModel).tables.count
            }
        } else if item is TablesModel {
            if (item as! TablesModel).fields.count == 0 && queueFields == nil {
                let aCombo = outlineView == leftTable ? leftServeur :rightServer
                let server = (myApp.delegate as! AppDelegate).servers[aCombo!.indexOfSelectedItem-1]
                queueFields =  DispatchQueue(label: "PR.adminSQL.nbrows", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                self.queueFields.async {
                    self.askForFields(side, server.adresse!, item as! TablesModel)
                }
                return 0
            } else if (item as! TablesModel).indexes.count == 0 && queueFields == nil {
                let aCombo = outlineView == leftTable ? leftServeur :rightServer
                let server = (myApp.delegate as! AppDelegate).servers[aCombo!.indexOfSelectedItem-1]
                if queueFields == nil {
                    queueFields =  DispatchQueue(label: "PR.adminSQL.nbrows", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                }
                self.queueFields.async {
                    self.askForIndexes(side, server.adresse!, item as! TablesModel)
                }
            } else {
                return (item as! TablesModel).fields == nil ? 0 :(item as! TablesModel).fields.count + (item as! TablesModel).indexes.count
            }
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let side = outlineView == leftTable ? "left" : "right"
        if item == nil {
            return DBS[side]?.databases[index] as Any
        } else if item is DatabasesModel {
            return (item as! DatabasesModel).tables[index] as Any
        } else if item is TablesModel {
            let table = item as! TablesModel
            if index < table.fields.count {
                return table.fields![index] as Any
            } else {
                let pseudoIndex = index - table.fields.count
                return table.indexes![pseudoIndex] as Any
            }
        }
        return ""
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is DatabasesModel {
            return (item as! DatabasesModel).nbTables > 0
        } else if item is TablesModel {
            return (item as! TablesModel).nbfields > 0
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        if !(item is FieldsModel) && !(item is IndexesModel){
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bddname"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                if item is DatabasesModel {
                    textField.stringValue = (item as! DatabasesModel).dbname
                } else if item is TablesModel {
                    textField.stringValue = (item as! TablesModel).tblname
                } else {
                    Swift.print("outline tableColumn item type inconnu")
                }
                
                if item is DatabasesModel {
                    view?.imageView!.image = imgBdd
                } else {
                    view?.imageView!.image = imgTable
                }
                (view?.subviews[2] as! NSTextField).stringValue = item is TablesModel && (item as! TablesModel).nbenreg != 0 ? String((item as! TablesModel).nbenreg) : ""
            }
        } else if item is FieldsModel {
            let titre = (item as! FieldsModel).Field == ""
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: titre ? "headerfield" : "fieldname"), owner: self) as? NSTableCellView
            
            if titre {
                view?.backgroundStyle = NSView.BackgroundStyle.raised
            }
            for subview in (view?.subviews)! {
                
                if subview is NSImageView {
                    if titre {
                        (subview as! NSImageView).image = nil
                    } else {
                        (subview as! NSImageView).image = imgField
                    }
                } else if subview is NSTextField {
                    switch (subview as! NSTextField).identifier?.rawValue {
                    case "field":
                        (subview as! NSTextField).stringValue = titre ? "Field" : (item as! FieldsModel).Field
                    case "tipe":
                        (subview as! NSTextField).stringValue = titre ? "Type" : (item as! FieldsModel).sqlTipe
                    case "isnull":
                        (subview as! NSTextField).stringValue = titre ? "Null" : ((item as! FieldsModel).Null == "YES" ? String(format: "%C",cAwesome.icon("check")) : "")

                    case "autoinc":
                        (subview as! NSTextField).stringValue = titre ? "AutoInc" : ((item as! FieldsModel).Extra != "" ? String(format: "%C",cAwesome.icon("check")) : "")
                    default: break
                    }
                }
            }
        } else if item is IndexesModel {
            let titre = (item as! IndexesModel).keyname == ""
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: titre ? "headerindex" : "indexname"), owner: self) as? NSTableCellView
            
            if titre {
                view?.backgroundStyle = NSView.BackgroundStyle.raised
            }
            for subview in (view?.subviews)! {
                if subview is NSImageView {
                    if titre {
                        (subview as! NSImageView).image = nil
                    } else {
                        (subview as! NSImageView).image = imgIndex
                    }
                } else if subview is NSTextField {
                    switch (subview as! NSTextField).identifier?.rawValue {
                    case "keyname":
                        (subview as! NSTextField).stringValue = titre ? "Index" : (item as! IndexesModel).keyname
                    case "sequence":
                        (subview as! NSTextField).stringValue = titre ? "Seq." : String((item as! IndexesModel).sequence)
                    case "colonne":
                        (subview as! NSTextField).stringValue = titre ? "Colonne" : (item as! IndexesModel).column
                    default: break
                    }
                }
            }
        } else {
            if item is IndexesModel {
                Swift.print("index à arficher")
            }
        }
        return view
    }
}
