//
//  indexes.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 12/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

class IndexesRequest: BaseRequest {
    
    init(forCreate: Int, _ database: String, _ table: String) {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "showIndexes", "database": database, "table": table]
        super.init(parameters: parameters)
    }
}

class IndexesResponse: Decodable {
    var moderators: [IndexesModel]
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

class IndexesModel: Decodable {
    let keyname: String
    var sequence: Int
    var column: String
    
    init(keyname: String, sequence: String, column: String) {
        self.keyname      = keyname
        self.sequence     = sequence.toInt()
        self.column       = column
    }
    
    init() {
        self.keyname     = ""
        self.sequence    = 0
        self.column      = ""
    }
    
    enum CodingKeys: String, CodingKey {
        case keyname    = "Key_name"
        case sequence   = "Seq_in_index"
        case column     = "Column_name"
    }
    
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keyname = try container.decoder(String.self, forKey: .keyname)
        let sequence  = try container.decoder(String.self, forKey: .sequence)
        let column = try container.decoder(String.self, forKey: .column)
        self.init(keyname: keyname, sequence: sequence, column: column)
    }
    
    func fetch(_ adresse: String, _ database: String, _ table: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = IndexesRequest(forCreate: 0, database, table)
        
        client.fetch(request: request, dataResponse: IndexesResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
}
