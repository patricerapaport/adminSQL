//
//  CLineReader.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 08/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

enum tipeLine: Int {
    case inconnu = 0
    case vierge  = 1
    case commentaire = 2
    case optionsGlobales = 3
    case database = 4
    case tableDef = 5
    case tableDump = 6
}

struct CLigne {
    var tipeline: tipeLine
    var identity: String
    var nblines: Int
    
    init(_ tipeline: tipeLine, _ identity: String, _ nblines: Int) {
        self.tipeline = tipeline
        self.identity = identity
        self.nblines  = nblines
    }
    
    static func tipe (_ aTipe: tipeLine) -> String {
        switch aTipe {
        case .optionsGlobales:
            return "Options"
        case .database:
            return "Database"
        case .tableDef:
            return "table déf."
        case .tableDump:
            return "table rows"
        default:
            return ""
        }
    }
}

struct CLineTable {
    var name: String
}

struct CLineDatabase {
    var name: String!
    var tables: [CLineTable]!
    
    init(_ name: String) {
        self.name = name
        self.tables = [CLineTable]()
    }
}

class CLineRead: LineReader {
    var lines = [CLigne]()
    
    func read() {
        var index = 0
        var lastTipe = CLigne(.inconnu, "", 0)
        var nbAvenir: Int = 0
        var identite = ""
        for line in self {
            index += 1
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            var tipe = getTipeLine(text)
            
            if lines.count == 0 {
                lines.append(tipe)
                lastTipe = tipe
            } else {
                if tipe.tipeline == .commentaire {
                    if lastTipe.tipeline == .tableDump {
                        lines[lines.count-1].nblines += 1 + nbAvenir
                        if tipe.identity != "" {
                            identite = tipe.identity
                        }
                    } else {
                        if tipe.identity != "" {
                            identite = tipe.identity
                        }
                        nbAvenir += 1
                        continue
                    }
                } else if tipe.tipeline == .vierge {
                    if nbAvenir == 0 {
                        lines[lines.count-1].nblines += 1 + nbAvenir
                    } else {
                        nbAvenir += 1
                        continue
                    }
                } else if tipe.tipeline == .inconnu && lastTipe.tipeline == .tableDef {
                    lines[lines.count-1].nblines += 1 + nbAvenir
                } else if tipe.tipeline == .inconnu && lastTipe.tipeline == .tableDump {
                    lines[lines.count-1].nblines += 1 + nbAvenir
                } else if lines[lines.count-1].tipeline == tipe.tipeline {
                    lines[lines.count-1].nblines += 1 + nbAvenir
                } else {
                    tipe.nblines = 1+nbAvenir
                    if identite != "" {
                        tipe.identity = identite
                        identite = ""
                    }
                    lines.append(tipe)
                    lastTipe = tipe
                }
                nbAvenir = 0
            }
        }
        for line in lines {
            Swift.print(line)
        }
    }
    
    func getTipeLine(_ text: String) -> CLigne  {
        if text.substr(0, 2) == "/*!" {
            if text.contains("40000") {
                //return .commentaire
                return CLigne(.commentaire, "", 1)
            } else {
                //return .optionsGlobales
                return CLigne(.optionsGlobales, "", 1)
            }
        } else {
            if text == "" {
                return CLigne(.vierge, "", 1)
            } else if text.substr(0, 1) == "--" {
                var identity = ""
                if text.uppercased().contains("CREATE SCHEMA") {
                    identity = text.substr(17, text.count-1)
                } else if text.contains("Definition of table ") {
                    var parts = text.components(separatedBy: "Definition of table ")
                    parts = parts[1].replacingOccurrences(of: "`", with: "").components(separatedBy: ".")
                    identity = parts[1]
                } else if text.contains("Dumping data for table") {
                    var parts = text.components(separatedBy: "Dumping data for table ")
                    parts = parts[1].replacingOccurrences(of: "`", with: "").components(separatedBy: ".")
                    identity = parts[1]
                }
                return CLigne(.commentaire, identity, 1)
            } else if text.contains("CREATE DATABASE ") || text.contains("USE") {
                return CLigne(.database, "", 1)
            } else if text.contains("DROP TABLE") || text.contains("CREATE TABLE") {
                return CLigne(.tableDef, "", 1)
            } else if text.contains("LOCK TABLE") || text.contains("INSERT TABLE") || text.contains("UNLOCK TABLE") {
                return CLigne(.tableDump, "", 1)
            } else {
                return CLigne(.inconnu, "", 1)
            }
        }
    }
    
    func databaseName() -> CLineDatabase {
        var res: CLineDatabase!
        for line in lines {
            if line.tipeline == .database {
                res = CLineDatabase(line.identity)
            } else if line.tipeline == .tableDef {
                res.tables.append(CLineTable(name: line.identity))
            }
        }
        return res!
    }
}
