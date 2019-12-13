//
//  sauvegarde.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 13/12/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let startSauvegarde   = Notification.Name("startSauvegarde")
    static let dumpTable         = Notification.Name("dumpTable")
    static let nextTable         = Notification.Name("nextTable")
}

class sauvegarde: parentWC {
    let server: Server!
    let database: DatabasesModel!
    var directory: String!
    var currentPage: Int!
    var queueSauvegarde: DispatchQueue!
    var file: CFile!

    @IBOutlet weak var ctlFilename: NSTextField!
    @IBOutlet weak var labelSauvegarde: NSTextField!
    @IBOutlet weak var jaugeDump: NSLevelIndicator!
    @IBOutlet weak var jaugeLabel: NSTextField!
    @IBOutlet weak var btAnnuler: NSButton!
    @IBOutlet weak var btSauvegarder: NSButton!
    @IBOutlet weak var waitIndicator: NSProgressIndicator!
    
    init (_ server: Server) {
        self.server = server
        self.database = nil
        directory = nil
        super.init(window: nil)
    }
    
    init (_ server: Server, _ database: DatabasesModel) {
        self.server = server
        self.database = database
        directory = nil
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        self.server = nil
        self.database = nil
        directory = nil
        super.init(coder: coder)
    }
    
    override func windowDidLoad() {
       window?.center()
        super.windowDidLoad()
        labelSauvegarde.stringValue = ""
        jaugeDump.isHidden = true
        jaugeLabel.stringValue = ""
        window?.title = "Sauvegarde de " + (server?.nom)! + "/" + (database == nil ? "Toutes les Bases de données" :(database?.dbname)!)
        ctlFilename.stringValue = (server?.nom)! + "_" + (database == nil ? "<BDD>" : (database?.dbname)!) + "_" + cDates.dateDuJour(true) + "_" + cDates.heureDuJour(true) + ".sql"
        //if directory == nil {
            //chooseDirectory(self)
        //}
        self.btSauvegarder.state = NSControl.StateValue.on
        self.btSauvegarder.target = self
        self.btSauvegarder.action = #selector(self.sauvegarder(_:))
        NotificationCenter.default.addObserver(self, selector: #selector(notificationTableSuivante(_:)), name: .nextTable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationDump(_:)), name: .dumpTable, object: nil)
    }
    
    @IBAction func chooseDirectory(_ sender: Any) {let panel = NSOpenPanel()
        panel.isFloatingPanel = true
        panel.showsHiddenFiles = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.title = "Répertoire de sauvegarde"
        window?.makeFirstResponder(panel)
        panel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                self.directory = panel.directoryURL!.path
                self.btSauvegarder.action = #selector(self.sauvegarder(_:))
                NotificationCenter.default.addObserver(self, selector: #selector(self.notificationTableSuivante(_:)), name: .nextTable, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.notificationDump(_:)), name: .dumpTable, object: nil)
                panel.close()
            } else {
                self.closeWindow()
                self.close()
            }
        }
    }
    
    @IBAction func sauvegarder(_ sender: NSButton) {
        let path = directory! +  "/" + ctlFilename.stringValue
        Swift.print("sauvegarde sur \(path)")
        if !FileManager.default.fileExists(atPath: path) {
            file = CFile(directory, ctlFilename.stringValue)
            if file.create() {
                sauvegarderBase(database)
                return;
                TablesModel().fetch((server.adresse)!, database.dbname, {
                    result in
                    switch result {
                    case .failure:
                        DispatchQueue.main.async {
                        }
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.waitIndicator.startAnimation(self)
                            self.database.tables = (response as! TablesResponse).moderators
                            self._debutFichier()
                            for table in self.database.tables {
                                self.queueSauvegarde = DispatchQueue(label: "PR.adminSQL.sauvegarde", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                                self.queueSauvegarde.async {
                                    self.sauvegardeTable(table)
                                }
                                break
                            }
                        }
                        
                    }
                })
            }
            
        }
    }
    
    func sauvegarderBase(_ aDatabase: DatabasesModel) {
        TablesModel().fetch((server.adresse)!, database.dbname, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                }
            case .success(let response):
                DispatchQueue.main.async {
                    self.waitIndicator.startAnimation(self)
                    self.database.tables = (response as! TablesResponse).moderators
                    self._debutFichier()
                    for table in self.database.tables {
                        self.queueSauvegarde = DispatchQueue(label: "PR.adminSQL.sauvegarde", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                        self.queueSauvegarde.async {
                            self.sauvegardeTable(table)
                        }
                        break
                    }
                }
                
            }
        })
    }
}

//MARK: Ecritures
extension sauvegarde {
    func _debutFichier () {
        let dbName = database.dbname
        file.ecrire("/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;")
        file.ecrire("/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;")
        file.ecrire("/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;")
        file.ecrire("/*!40101 SET NAMES utf8 */;")
        file.sautDeLigne()
        
        file.ecrire("/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;")
        file.ecrire("/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;")
        file.ecrire("/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;")
        file.sautDeLigne()
        
        file.ecrire("--")
        file.ecrire("-- Create schema " + dbName)
        file.ecrire("--")
        file.sautDeLigne()
        
        file.ecrire("CREATE DATABASE IF NOT EXISTS " + dbName + ";")
        file.ecrire("USE " + dbName + ";")
        file.sautDeLigne()
    }
    
    func _enteteTable(_ table: TablesModel) {
        let dbName = database.dbname
        let tblName = (table.tblname)
        
        file.sautDeLigne()
        file.ecrire("--")
        file.ecrire("-- Definition of table `" + dbName + "`.`" + tblName + "`")
        file.ecrire("--")
        file.sautDeLigne()
        
        file.ecrire("DROP TABLE IF EXISTS `" + dbName + "`.`" + tblName + "`;")
    }
    
    func _createTable(_ table: TablesModel, _ rep: TableResponse) {
        // Exécuté sous queueSauvegarde
        // Apelle dumpTable si les champs sont obtenus
        let dbName = database.dbname
        let tblName = table.tblname
        let txtCreate = rep.text.components(separatedBy: "\n")
        for row in 0...txtCreate.count-1 {
            var text = txtCreate[row]
            if row == txtCreate.count-1 {
                text += ";"
            }
            file.ecrire(text)
        }
        file.sautDeLigne()
        
        FieldsModel().fetchShow((server.adresse)!, dbName, tblName, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                }
            case .success(let response) :
                let rep = response as! FieldsResponse
                table.fields = rep.moderators
                self.queueSauvegarde.async {
                    self.dumpTable(table)
                }
            }
        })
    }
    
    func _enteteDumpTable(_ table: TablesModel) {
        let dbName = database.dbname
        let tblName = table.tblname
        
        file.ecrire("--")
        file.ecrire("-- Dumping data for table `" + dbName + "`.`" + tblName + "`")
        file.ecrire("--")
        file.sautDeLigne()
        
        file.ecrire("/*!40000 ALTER TABLE `" + tblName + "` DISABLE KEYS */;")
        file.ecrire("LOCK TABLES `" + tblName + "` WRITE;")
    }
    
    func _dumpTable (_ table: TablesModel, _ rep: DumpTableResponse) {
        // Exécuté dans queueSauvegarde
        let dbName = self.database.dbname
        let tblName = table.tblname
        var jaugeValue: Double!
        
        if currentPage == 1 && rep.moderators.count > 0 {
            _enteteDumpTable(table)
            DispatchQueue.main.async {
                self.jaugeDump.maxValue = Double(rep.total)
            }
        }
        currentPage = rep.page + 1
        DispatchQueue.main.async {
            jaugeValue = self.jaugeDump.doubleValue
        }
        if rep.moderators.count > 0 {
            file.sautDeLigne()
            file.ecrire("INSERT INTO `" + dbName + "`.`" + tblName + "` VALUES")
            for index in 0...rep.moderators.count-1 {
                let db = rep.moderators[index]
                var valeurs = [String]()
                for index in 0...db.row.count-1 {
                    let valeur = db.row[index]
                    switch table.fields[index].Tipe {
                    case "A":
                        let str = (valeur as! String).replacingOccurrences(of: "'", with: "\\'")
                        valeurs.append("'" + str + "'")
                    case "N":
                        valeurs.append(valeur as! String)
                    default:
                        valeurs.append("null")
                    }
                }
                var str = "(" + valeurs.joined(separator: ", ") + ")"
                if index < rep.moderators.count-1 {
                    str = str + ","
                } else {
                    str = str + ";"
                }
                self.file.ecrire(str)
                DispatchQueue.main.async {
                    jaugeValue += 1
                    self.jaugeDump.doubleValue = jaugeValue
                    self.jaugeLabel.stringValue = String(Int(self.jaugeDump.doubleValue)) + " / " + String(rep.total)
                }
            }
            if rep.hasMore == 1 {
                let info = ["table": table as Any]
                NotificationCenter.default.post(name: .dumpTable, object: self, userInfo: info)
            } else {
                _finDumpTable(table)
                let info = ["table": table]
                NotificationCenter.default.post(name: .nextTable, object: self, userInfo: info)
            }
        } else {
            let info = ["table": table]
            NotificationCenter.default.post(name: .nextTable, object: self, userInfo: info)
        }
    }
    
    func _finDumpTable(_ table: TablesModel) {
        // Exécuté dans queueSauvegarde
        let tblName = table.tblname
        file.sautDeLigne()
        file.ecrire("UNLOCK TABLES;")
        file.ecrire("/*!40000 ALTER TABLE `" + tblName + "` ENABLE KEYS */;")
        file.sautDeLigne();
    }
    
    func _finDeFichier () {
        file.sautDeLigne()
        file.ecrire("/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;")
        file.ecrire("/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;")
        file.ecrire("/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;")
        file.ecrire("/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;")
        file.ecrire("/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;")
        file.ecrire("/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;")
        file.ecrire("/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;")
        
        
        DispatchQueue.main.async {
            self.labelSauvegarde.stringValue = "Sauvegarde terminée"
            self.jaugeDump.isHidden = true
            self.jaugeLabel.stringValue = ""
            self.waitIndicator.stopAnimation(self)
        }
        
        file.close()
    }
}

//MARK: Opérations
extension sauvegarde {
    func sauvegardeTable(_ table: TablesModel) {
        // Exécuté dans queueSauvegarde
        // séquence: 1. _createTable
        // 2. dumpTable
        let dbName = database.dbname
        let tblName = table.tblname
        
        DispatchQueue.main.async {
            if self.jaugeDump.isHidden {
                self.labelSauvegarde.stringValue = "Table " + tblName
                self.labelSauvegarde.needsDisplay = true
                self.jaugeDump.minValue = 0
                self.jaugeDump.maxValue = 0
                self.jaugeDump.doubleValue = 0
                self.jaugeDump.stringValue = ""
                self.jaugeDump.isHidden = false
                self.jaugeLabel.stringValue = ""
            }
        }
        
        _enteteTable(table)
        currentPage = 1
        
        TableModel().fetchCreate((server.adresse)!, dbName, tblName, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                }
            case .success(let response):
                self.queueSauvegarde.async {
                    self._createTable(table,  response as! TableResponse)
                }
            }
        })
    }
    
    func dumpTable (_ table: TablesModel) {
        // Exécuté dans queueSauvegarde
        let dbName = database.dbname
        let tblName = table.tblname
        
        DumpTableModel().fetch((server.adresse)!, dbName, tblName, currentPage, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    Swift.print("Echec dump table \(tblName)")
                }
            case .success(let response):
                self.queueSauvegarde.async {
                    self._dumpTable(table, response as! DumpTableResponse)
                }
            }
        })
    }
    
    @objc func notificationDump (_ notification: Notification) {
        let userinfo = notification.userInfo as! [String: Any]
        let table = userinfo["table"] as! TablesModel
        queueSauvegarde.async {
            self.dumpTable(table)
        }
    }
    
    func tableSuivante(_ table: TablesModel) {
        for index in 0...database.tables.count-2 {
            if database.tables[index].tblname == table.tblname {
                DispatchQueue.main.async {
                    self.jaugeDump.isHidden = true
                    self.queueSauvegarde.async {
                        self.sauvegardeTable(self.database.tables[index+1])
                    }
                }
                return
            }
        }
        _finDeFichier()
    }
    
    @objc func notificationTableSuivante (_ notification: Notification) {
        let userinfo = notification.userInfo as! [String: Any]
        let table = userinfo["table"] as! TablesModel
        tableSuivante(table)
    }
}
