//
//  databases.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 17/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

class DatabasesRequest: BaseRequest {
    
    init() {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "show"]
        super.init(parameters: parameters)
    }
}

class DatabasesResponse: Decodable {
    var moderators: [DatabasesModel]
    let total: Int
    let hasMore: Bool
    let page: Int
    
    enum CodingKeys: String, CodingKey {
        case moderators = "items"
        case hasMore = "has_more"
        case total
        case page
    }
}

class DatabasesNbtablesResponse: Decodable {
    var nbtables: Int
    enum CodingKeys: String, CodingKey {
        case nbtables = "total"
    }
}

class DatabasesModel: Decodable {
    let dbname: String
    var tables: [TablesModel]!
    var nbTables: Int!
    
    init(dbname: String) {
        self.dbname = dbname
        self.tables = [TablesModel]()
        self.nbTables = 0
    }
    
    init() {
        self.dbname = ""
        self.tables = [TablesModel]()
        self.nbTables = 0
    }
    
    enum CodingKeys: String, CodingKey {
        case dbname
    }
    
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dbname = try container.decoder(String.self, forKey: .dbname)
        self.init(dbname: dbname)
    }
    
    func fetch(_ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient()
        let request = DatabasesRequest()
        
        client.fetch(request: request, dataResponse: DatabasesResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetch(_ adresse: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = DatabasesRequest()
        
        client.fetch(request: request, dataResponse: DatabasesResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetchShowNbtables(_ adresse: String, _ nomdatabase: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = DatabasesRequest()
        request.addParameters(["count": "1", "database": nomdatabase])
        request.parameters["method"] = "showTables"
        client.fetch(request: request, dataResponse: DatabasesNbtablesResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response) :
                    self.nbTables = (response as! DatabasesNbtablesResponse).nbtables
                    completion(result)
                case .failure(_):
                    completion(result)
                }
            }
        })
    }
}
