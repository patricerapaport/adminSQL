//
//  CFile.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 07/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

class CFile: NSObject {
    var directory: String!
    var filename: String!
    var handle: FileHandle!
    
    init (_ directory: String, _ filename: String) {
        self.directory = directory
        self.filename  = filename
        super.init()
    }
    
    static func isSQL(_ path: String) -> Bool {
        let pieces = path.components(separatedBy: ".")
        return pieces.count > 0 && pieces[pieces.count-1].lowercased() == "sql"
    }
    
    static func explodeName (_ path: String) -> [String: String] {
        if !isSQL(path) {
            return ["file": path]
        } else {
            var rep = [String: String]()
            let pieces = path.components(separatedBy: ".")
            let paths = pieces[0].components(separatedBy: "_")
            
            for index in stride(from: paths.count, to: 0, by: -1) {
                let part = paths[index-1]
                if !rep.keys.contains("time") {
                    rep["time"] = part.substr(0, 1) + ":" + part.substr(2, 3) + ":" + part.substr(4, 5)
                } else if !rep.keys.contains("date") {
                    rep["date"] = part.substr(6, 7) + "/" + part.substr(4, 5) + "/" + part.substr(0, 3)
                } else if !rep.keys.contains("database") {
                    rep["database"] = part
                } else {
                    rep["server"] = part
                }
            }
            return rep
        }
    }
    
    func create() -> Bool {
        let path = directory! +  "/" + filename
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            if !FileManager.default.fileExists(atPath: path) {
                Swift.print("Echec de création de \(path)")
                return false
            } else {
                handle = FileHandle(forWritingAtPath: path)
                return handle != nil
            }
        } else {
            return false
        }
    }
    
    func sautDeLigne() {
        handle.write("\n".data(using: .utf8)!)
    }
    
    func ecrire (_ text: String) {
        handle.write(text.data(using: .utf8)!)
        sautDeLigne()
    }
    
    func close() {
        handle.closeFile()
    }
}
