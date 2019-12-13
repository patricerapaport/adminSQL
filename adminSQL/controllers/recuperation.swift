//
//  recuperation.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 26/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class recuperation: parentWC {
    var fichier: String!
    var reader: LineReader!
    var saveOptions: [String]!
    var server: Server!
    var eof = false
    
    @IBOutlet weak var nomserveurSauvegarde: NSTextField!
    @IBOutlet weak var nomBddSauvegarde: NSTextField!
    @IBOutlet weak var dtHeureSauvegarde: NSTextField!
    @IBOutlet weak var nomServeurRecuperation: CComboBox!
    @IBOutlet weak var nomBddRecuperation: CTextfield!
    @IBOutlet weak var btAnnuler: NSButton!
    @IBOutlet weak var btRecuperer: NSButton!
    @IBOutlet weak var labelAction: NSTextField!
    
    init(_ fichier: String) {
        self.fichier = fichier
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        self.fichier = nil
        super.init(coder: coder)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        var options = [cComboOption]()
        if (myApp.delegate as! AppDelegate).servers != nil {
            options.append(cComboOption(key: "-1", value: ""))
            for index in 0...(myApp.delegate as! AppDelegate).servers.count-1 {
                options.append(cComboOption(key: String(index), value: (myApp.delegate as! AppDelegate).servers[index].nom!))
            }
        }
        nomServeurRecuperation.setDatasource(options)
        
        let dict = CFile.explodeName(fichier)
        nomserveurSauvegarde.stringValue = dict["server"]!
        nomBddSauvegarde.stringValue     = dict["database"]!
        dtHeureSauvegarde.stringValue    = dict["date"]! + " à " + dict["time"]!
        nomServeurRecuperation.selectbyText(dict["server"]!)
        nomBddRecuperation.stringValue  = dict["database"]!
        
        server = (myApp.delegate as! AppDelegate).servers[nomServeurRecuperation.indexOfSelectedItem-1]
        NotificationCenter.default.addObserver(self, selector: #selector(donnees(_:)), name: .dumpTable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(table(_:)), name: .nextTable, object: nil)
    }
}

// MARK: Operations
extension recuperation {
    @IBAction func Annuler(_ sender: Any) {
        closeWindow()
        close()
    }
    
    @IBAction func recuperer(_ sender: Any) {
        btRecuperer.isEnabled = false
        eof = false
        verifDatabase()
    }
    
    func verifDatabase() {
        var bddExiste = false
        DatabasesModel().fetch(server.adresse!, {
            result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    _ = messageBox("Impossible d'accéder aux BDD", withOK: true).runModal()
                }
            case .success(let response):
                let rep = response as! DatabasesResponse
                for DB in rep.moderators {
                    if DB.dbname == self.nomBddRecuperation.stringValue {
                        let text = "La base de données " + DB.dbname + " existe déjà. Désirez vous poursuivre?"
                        if messageBox(text).runModal() {
                            bddExiste = true
                            break
                        } else {
                            self.btRecuperer.isEnabled = true
                            return
                        }
                    }
                }
                let dir = FileManager.default.homeDirectoryForCurrentUser.path + "/Documents"
                let path = dir + "/" + self.fichier
                self.reader = LineReader(path: path)
                self.recupererOptions()
                
                self.createDatabase(bddExiste: bddExiste, completion: {
                    res in
                    if res {
                        self.traiterTable( {
                            res in
                            if res {
                                NotificationCenter.default.post(name: .dumpTable, object: self, userInfo: nil)
                            } else {
                                Swift.print("erreur traitement table")
                            }
                        })
                    }
                })
            }
        })
    }
}

// MARK: Notifications
extension recuperation {
    @objc override func comboSelectionDisdChange (_ aCombo: CComboBox) {
        server = (myApp.delegate as! AppDelegate).servers[nomServeurRecuperation.indexOfSelectedItem-1]
    }
    
    @objc func donnees (_ notification: Notification) {
        let info = notification.userInfo
        let donneeInfo = info != nil ? info!["donnee"] as! String : ""
        
        traiterDonneesTable(lastDonnee: donneeInfo, {
            res in
            
        })
    }
    
    @objc func table(_ notification: Notification) {
        traiterTable({
            res in
            if res {
                if self.eof {
                    _ = messageBox("Récupération terminée", withOK: true).runModal()
                    return
                } else {
                    NotificationCenter.default.post(name: .dumpTable, object: self, userInfo: nil)
                }
            } else {
                Swift.print("erreur traitement table")
            }
        })
    }
}

// MARK: Lecture fichier
extension recuperation {
    func replace(_ text: String, _ occurences: [String], _ replacement: String) -> String {
        var str = text
        for occurence in occurences {
            str = str.replacingOccurrences(of: occurence, with: replacement)
        }
        return str
    }
    
    func recupererOptions() {
        saveOptions = [String]()
        var line = ""
        repeat {
            line = reader.nextLine!
            if line != "\n" {
                line = replace(line, ["/*!40101", "/*!40014", "*/;", "\n"], "")
                saveOptions.append(line)
            }
        } while line != "\n"
    }
    
    func createDatabase(bddExiste: Bool, completion: @escaping(Bool) -> Void) {
        var parameters = ["cmd": "cmd", "nomtable": "databases", "method": "sql", "sql": ""]
        var cmds: [String]!
        if bddExiste {
            cmds = ["drop database " + nomBddRecuperation.stringValue, "create database " + nomBddRecuperation.stringValue]
        } else {
            cmds = ["create database " + nomBddRecuperation.stringValue]
        }
        parameters["sql"] = cmds.joined(separator: ";")
        StackExchangeClient(server.adresse!).send(parameters: parameters, completion: {
            res in
            completion(res)
        })
    }
    
    func traiterTable(_ completion: @escaping(Bool) -> Void) {
        var line: String? = ""
        var cmds = saveOptions
        var cmdCreateTable = ""
        cmds!.append("SET FOREIGN_KEY_CHECKS=0; USE "+nomBddRecuperation.stringValue)
        
        repeat {
            let ligneLue = reader.nextLine
            if ligneLue == nil {
                line = nil
            } else {
                line = replace(ligneLue!, ["\n", ";"], "")
            }
        } while line != nil && line!.substr(0, 3) != "DROP"
        if line == nil {
            eof = true
            completion(true)
            return
        } else {
            let els = replace(line!, ["`"], "").components(separatedBy: ".")
            DispatchQueue.main.async {
                self.labelAction.stringValue = "table " + els[1]
            }
            cmds!.append(replace(line!, [nomBddSauvegarde.stringValue], nomBddRecuperation.stringValue))
        }
        
        repeat {
            line = replace(reader.nextLine!, ["\n", ";"], "")
            if line != "" {
                cmdCreateTable += replace(line!, [nomBddSauvegarde.stringValue], nomBddRecuperation.stringValue)
            }
        } while (line != "")
        cmds!.append(cmdCreateTable)
        
        var parameters = ["cmd": "cmd", "nomtable": "databases", "method": "sql", "sql": ""]
        parameters["sql"] = cmds?.joined(separator: ";")
        StackExchangeClient(server.adresse!).send(parameters: parameters, completion: {
            res in
            completion(res)
            })
    }
    
    func traiterDonneesTable(lastDonnee: String, _ completion: @escaping(Bool) -> Void) {
        var line = ""
        var cmds = saveOptions
        var insertCmd: String!
        var donnees = ""
        var dumpTermine = false
        
        cmds!.append("SET FOREIGN_KEY_CHECKS=0; USE "+nomBddRecuperation.stringValue)
        
        if lastDonnee == "" {
            repeat {
                line = replace(reader.nextLine!, ["\n", ";", "/*!", "*/"], "")
            } while line.substr(0, 4) != "40000" && line.substr(0,12) != "-- Definition"
            
            if line.substr(0, 12) == "-- Definition" {
                // Aucune donnée pour cette table, il faut passer à la table suivante
                completion(true)
                NotificationCenter.default.post(name: .nextTable, object: self, userInfo: nil)
                return
            }
        
            let str1 = replace(line, ["40000"], "")
            cmds!.append(str1)
            donnees = str1 + ";"
            
            repeat {
                line = replace(reader.nextLine!, ["\n", ";", "/*!", "*/"], "")
                if line != "" && line.substr(0, 5) != "INSERT" {
                    donnees += line + ";"
                    cmds!.append(line)
                }
            } while line.substr(0, 5) != "INSERT"
        
            insertCmd = replace(line, [nomBddSauvegarde.stringValue], nomBddRecuperation.stringValue)
            donnees = insertCmd + ";"
        } else {
            donnees = lastDonnee
            insertCmd = replace(lastDonnee, [";"], "")
        }
        var str = insertCmd!
        repeat {
            line = replace(reader.nextLine!, ["\n"], "")
            if line != "" {
                str += line
            }
        } while line != ""
        cmds!.append(str)

        line = replace(reader.nextLine!, ["\n", ";"], "")
        if line == "UNLOCK TABLES" {
            cmds!.append(line)
            line = replace(reader.nextLine!, ["/*!40000 ", " */;", "\n"], "")
            cmds!.append(line)
            dumpTermine = true
        } else if line == "\n" {
            donnees = replace(reader.nextLine!, ["\n"], "")
        }

        var parameters = ["cmd": "cmd", "nomtable": "databases", "method": "sql", "sql": ""]
        parameters["sql"] = cmds?.joined(separator: ";")
        StackExchangeClient(server.adresse!).send(parameters: parameters, completion: {
            res in
            if res {
                if dumpTermine {
                    NotificationCenter.default.post(name: .nextTable, object: self, userInfo: nil)
                } else {
                    let info = ["donnee": donnees as Any]
                    NotificationCenter.default.post(name: .dumpTable, object: self, userInfo: info)
                }
            }
            completion(res)
        })
    }
}
