//
//  table.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 19/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

class TableRequest: BaseRequest {
    
    init(forCreate: Int, _ database: String, _ table: String) {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "showCreate", "database": database, "table": table]
        super.init(parameters: parameters)
    }
    
    init(forData: Bool, _ database: String, _ table: String, _ limit: Int, _ page: Int) {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "datas", "database": database, "table": table, "limit": String(limit), "page": String(page), "jointures": "1"]
        super.init(parameters: parameters)
    }
}

class TableResponse: Decodable {
    let nomtable: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case nomtable
        case text
    }
}

class TableModel: Decodable {
    let dbname: String
    let tblname: String
    var data: [NSDictionary]!
    var totalEnreg: Int!
    var currentPage: Int!
    
    init(dbName: String, tblname: String) {
        self.dbname  = dbName
        self.tblname = tblname
    }
    
    init() {
        self.dbname  = ""
        self.tblname = ""
    }
    
    enum CodingKeys: String, CodingKey {
        case dbname
        case tblname
    }
    
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tblname = try container.decoder(String.self, forKey: .tblname)
        let dbname  = try container.decoder(String.self, forKey: .dbname)
        self.init(dbName: dbname, tblname: tblname)
    }
    
    func fetchCreate(_ database: String, _ table: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient()
        let request = TableRequest(forCreate: 1, database, table)
        
        client.fetch(request: request, dataResponse: TableResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetchCreate(_ adresse: String, _ database: String, _ table: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = TableRequest(forCreate: 1, database, table)
        
        client.fetch(request: request, dataResponse: TableResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    func fetchData(_ adresse: String, _ nomdatabase: String, _ nomtable: String, _ limit: Int, _ page: Int,  _ completion: @escaping(Bool, NSDictionary?) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = TableRequest(forData: true, nomdatabase, nomtable, limit, page)
        client.fetch(request: request, completion: {
            res, dict in
            DispatchQueue.main.async {
                completion(res, dict)
            }
        })
    }
}
