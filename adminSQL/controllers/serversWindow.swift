//
//  servers.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 27/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa
import Foundation

class serversWindow: parentWC {
    
    @IBOutlet weak var tableServers: NSTableView!
    @IBOutlet weak var ctrlNom: CTextfield!
    @IBOutlet weak var ctrlAdresse: CTextfield!
    @IBOutlet weak var ctrlServerBDD: CTextfield!
    @IBOutlet weak var ctrlLogin: CTextfield!
    @IBOutlet weak var ctrlPwd: CTextfield!
    @IBOutlet weak var btNouveau: NSButton!
    @IBOutlet weak var btModifier: NSButton!
    @IBOutlet weak var btSupprimer: NSButton!
    @IBOutlet weak var btAnnuler: NSButton!
    @IBOutlet weak var btSauvegarder: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        _isModal = true
        _eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.myKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }

        tableServers.delegate = self
        tableServers.dataSource = self
        
        ctrlNom.delegate = self
        ctrlAdresse.delegate = self
        
        tableServers.reloadData()
        if tableServers.numberOfRows == 0 {
            etatDetermine()
        } else {
            etatIndetermine()
        }
    }
}

//MARK: Opérations
extension serversWindow {
    func enableCtrls(_ bRes: Bool) {
        ctrlNom.isEnabled = bRes
        ctrlAdresse.isEnabled = bRes
        ctrlServerBDD.isEnabled = bRes
        ctrlLogin.isEnabled = bRes
        ctrlPwd.isEnabled = bRes
    }
    
    func etatDetermine() {
        btNouveau.isEnabled = false
        btModifier.isEnabled = false
        btSupprimer.isEnabled = false
        btAnnuler.isEnabled = true
        btSauvegarder.isEnabled = true
        enableCtrls(true)
        _ = ctrlNom.becomeFirstResponder()
    }
    
    func etatIndetermine() {
        btNouveau.isEnabled = true
        btModifier.isEnabled = true
        btSupprimer.isEnabled = true
        btAnnuler.isEnabled = false
        btSauvegarder.isEnabled = false
        enableCtrls(false)
    }
    
    @IBAction func nouveau(_ sender: Any) {
        tableServers.deselectRow(tableServers.selectedRow)
        etatDetermine()
    }
    
    @IBAction func modifier(_ sender: Any) {
        if tableServers.selectedRow != -1 {
            etatDetermine()
        }
    }
    
    @IBAction func supprimer(_ sender: Any) {
        if tableServers.selectedRow != -1 && messageBox("Etes vous certain de supprimer le serveur " + ctrlNom.stringValue + "?").runModal() {
            AppDelegate.viewContext.delete((myApp.delegate as! AppDelegate).servers[tableServers.selectedRow])
            (myApp.delegate as! AppDelegate).servers.remove(at: tableServers.selectedRow)
            try? AppDelegate.viewContext.save()
            tableServers.reloadData()
        }
    }
    
    @IBAction func annuler(_ sender: Any) {
        tableServers.deselectRow(tableServers.selectedRow)
        etatIndetermine()
    }
    
    @IBAction func sauvegarder(_ sender: Any) {
        //for control in controls {
            
        //}
        var rowIndexes: NSIndexSet!
        let colsIndexes = NSIndexSet( indexesIn: NSMakeRange(0, tableServers.numberOfColumns))
        if tableServers.selectedRow == -1 {
            let server = Server(context: AppDelegate.viewContext)
            server.nom       = ctrlNom.stringValue
            server.adresse   = ctrlAdresse.stringValue
            server.serverBDD = ctrlServerBDD.stringValue
            server.login     = ctrlLogin.stringValue
            server.pwd       = ctrlPwd.stringValue
            try? AppDelegate.viewContext.save()
            (myApp.delegate as! AppDelegate).servers.append(server)
            tableServers.reloadData()
            //rowIndexes = NSIndexSet( indexesIn: NSMakeRange((myApp.delegate as! AppDelegate).servers.count-1, 1))
        } else {
            let server = (myApp.delegate as! AppDelegate).servers[tableServers.selectedRow]
            server.nom       = ctrlNom.stringValue
            server.adresse   = ctrlAdresse.stringValue
            server.serverBDD = ctrlServerBDD.stringValue
            server.login     = ctrlLogin.stringValue
            server.pwd       = ctrlPwd.stringValue
            try? AppDelegate.viewContext.save()
            (myApp.delegate as! AppDelegate).servers[tableServers.selectedRow] = server
            rowIndexes = NSIndexSet( indexesIn: NSMakeRange(tableServers.selectedRow, 1))
            tableServers.reloadData(forRowIndexes: rowIndexes as IndexSet, columnIndexes: colsIndexes as IndexSet)
        }
        
        etatIndetermine()
    }
}

// MARK: tableViewDelegate
extension serversWindow: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        if (myApp.delegate as! AppDelegate).servers == nil {
            return 0
        } else {
            return (myApp.delegate as! AppDelegate).servers.count
        }
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier)!.rawValue), owner: self) as! NSTableCellView? {
            cell.textField?.stringValue = (myApp.delegate as! AppDelegate).servers[row].nom!
            return cell
        } else {
            return nil
        }
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        if tableServers.selectedRow == -1 {
            for control in controls {
                control.stringValue = ""
            }
            btNouveau.isEnabled = true
            btModifier.isEnabled = false
            btSupprimer.isEnabled = false
        } else {
            let server = (myApp.delegate as! AppDelegate).servers[tableServers.selectedRow]
            ctrlNom.stringValue = server.nom!
            ctrlAdresse.stringValue = server.adresse!
            ctrlServerBDD.stringValue = server.serverBDD!
            ctrlLogin.stringValue = server.login!
            ctrlPwd.stringValue = server.pwd!
            btNouveau.isEnabled = true
            btModifier.isEnabled = true
            btSupprimer.isEnabled = true
        }
    }
}

//MARK: NSTextFieldDelegate
extension serversWindow: NSTextFieldDelegate {
    @objc override func verifControl(_ aControl: NSControl) {
        if aControl is controlProtocol {
            let str = (aControl as! controlProtocol).verifControl()
            if str != nil {
                let queue = DispatchQueue(label: "PR.adminSQL", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
                queue.async {
                    self.delayFocus(self.currentControl, "Zone obligatoire")
                }
            }
        }
        super.verifControl(aControl)
    }
    
    @objc func myKeyDown(with event: NSEvent) -> Bool {
        if (window?.isMainWindow)! {
            //Swift.print("keydown \(event)")
            if event.modifierFlags.contains(.command) {
                if event.characters == "w" {
                    closeWindow()
                    close()
                    return true
                }
                return false
            }
        }
        return false
    }
    
}
