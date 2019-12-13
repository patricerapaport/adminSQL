//
//  explorer.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 25/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class explorer: NSWindowController {

    @IBOutlet weak var btSupprimer: NSToolbarItem!
    @IBOutlet weak var btOuvrir: NSToolbarItem!
    @IBOutlet weak var btRecuperer: NSToolbarItem!
    @IBOutlet weak var tableSauvegardes: NSTableView!
    var fichiers: [String]!
    var path: String!
    var sortDescriptors: [NSSortDescriptor]!
    
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

        path = returnPath()
        tableSauvegardes.delegate = self
        tableSauvegardes.dataSource = self
        btSupprimer.action = nil
        btRecuperer.action = nil
        sortDescriptors = [NSSortDescriptor]()
        sortDescriptors.append(NSSortDescriptor(key: "server", ascending: true))
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            fichiers = [String]()
            for url in contents {
                if url.contains(".sql") {
                    fichiers.append(url)
                }
            }
            
            //fichiers = contents.map { return URL(string: path)!.appendingPathComponent($0) }
        } catch {
            fichiers = []
        }
        fichiers = fichiers.sorted() {
            $0 < $1
        }
        DispatchQueue.main.async {
            self.tableSauvegardes.sortDescriptors = self.sortDescriptors
            self.tableSauvegardes.reloadData()
        }
    }
    
    func returnPath() -> String {
        let dir = FileManager.default.homeDirectoryForCurrentUser
        return dir.path + "/Documents"
    }
}

//MARK: Opérations
extension explorer {
    @IBAction func Suppression(_ sender: Any) {
        if messageBox("Etes vous certain de supprimer cette sauvegarde?").runModal() {
            let path = returnPath() + "/" + fichiers[tableSauvegardes.selectedRow]
            Swift.print("suppression de \(path)")
            do {
                try FileManager.default.removeItem(atPath: path)
                fichiers.remove(at: tableSauvegardes.selectedRow)
                DispatchQueue.main.async {
                    self.tableSauvegardes.reloadData()
                }
            } catch {
                _ = messageBox("Suppression impossible", withOK: true).runModal()
            }
        } else {
            DispatchQueue.main.async {
                self.btSupprimer.isEnabled = true
                self.btSupprimer.action = #selector(self.Suppression(_:))
            }
        }
    }
    
    @IBAction func ouvrirFichier(_ sender: Any) {
        if tableSauvegardes.selectedRow != -1 {
            let wc = analyzeSauvegarde(fichiers[tableSauvegardes.selectedRow])
            wc.showWindow(self)
        }
    }
    
    @IBAction func recuperer(_ sender: Any) {
        if tableSauvegardes.selectedRow != -1 {
            recuperation(fichiers[tableSauvegardes.selectedRow]).showWindow(self)
        }
    }
}

//MARK: tableViewDatasource
extension explorer: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        if fichiers == nil {
            return 0
        } else {
            return fichiers.count
        }
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier)!.rawValue), owner: self) as! NSTableCellView? {
            //let nom = fichiers[row].substr(1+path.count, nil)
            if !CFile.isSQL(fichiers[row]) {
                if tableColumn?.identifier.rawValue == "database" {
                    cell.textField?.stringValue = fichiers[row]
                } else {
                    cell.textField?.stringValue = ""
                }
            } else {
                let dict = CFile.explodeName(fichiers[row])
                if dict.keys.contains((tableColumn?.identifier.rawValue)!) {
                    cell.textField?.stringValue = dict[(tableColumn?.identifier.rawValue)!]!
                } else {
                    cell.textField?.stringValue = ""
                }
            }
            return cell
        }
        return nil
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        if tableSauvegardes.selectedRow != -1 {
            btSupprimer.action = #selector(Suppression(_:))
            btRecuperer.action = #selector(recuperer(_:))
        } else {
            btSupprimer.action = nil
            btRecuperer.action = nil
        }
    }
}
