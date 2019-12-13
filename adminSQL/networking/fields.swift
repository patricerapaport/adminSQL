//
//  fields.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 21/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

class FieldsRequest: BaseRequest {
    
    init(forCreate: Int, _ database: String, _ table: String) {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "showFields", "database": database, "table": table, "jointures": "1"]
        super.init(parameters: parameters)
    }
}

class FieldsResponse: Decodable {
    var moderators: [FieldsModel]
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

class FieldsModel: Decodable {
    let Field: String
    var Tipe: String
    var sqlTipe: String
    let collation: String
    let Null: String
    let Key: String
    let Default: String
    let Extra: String

    
    init(Field: String, Tipe: String, collation: String, Null: String, Key: String, Default: String, Extra: String) {
        self.Field      = Field
        self.sqlTipe    = Tipe
        if Tipe == "text" || (Tipe.count > 7 && Tipe.substring(1, 7) == "varchar") {
            self.Tipe = "A"
        } else if Tipe.substring(1, 3) == "int" {
            self.Tipe = "N"
        } else {
            self.Tipe = "A"
        }
        self.collation  = collation
        self.Null       = Null
        self.Key        = Key
        self.Default    = Default
        self.Extra      = Extra
    }
    
    init() {
        self.Field      = ""
        self.Tipe       = ""
        self.sqlTipe    = ""
        self.collation  = ""
        self.Null       = ""
        self.Key        = ""
        self.Default    = ""
        self.Extra      = ""
    }
    
    enum CodingKeys: String, CodingKey {
        case Field
        case Tipe   = "Type"
        case collation = "Collation"
        case Null
        case Key
        case Default
        case Extra
    }
    
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let Field = try container.decoder(String.self, forKey: .Field)
        let Tipe  = try container.decoder(String.self, forKey: .Tipe)
        let collation = try container.decoder(String.self, forKey: .collation)
        let Null  = try container.decode(String.self, forKey: .Null)
        let Key  = try container.decode(String.self, forKey: .Key)
        var Default  = try? container.decode(String.self, forKey: .Default)
        let Extra  = try container.decode(String.self, forKey: .Extra)
        if Default == nil {
            Default = "Null"
        }
        self.init(Field: Field, Tipe: Tipe, collation: collation, Null: Null, Key: Key, Default: Default!, Extra: Extra)
    }
    
    func fetch(_ adresse: String, _ database: String, _ table: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = FieldsRequest(forCreate: 0, database, table)
        
        client.fetch(request: request, dataResponse: FieldsResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetchShow(_ database: String, _ table: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient()
        let request = FieldsRequest(forCreate: 1, database, table)
        
        client.fetch(request: request, dataResponse: FieldsResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetchShow(_ adresse: String, _ database: String, _ table: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = FieldsRequest(forCreate: 1, database, table)
        
        client.fetch(request: request, dataResponse: FieldsResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
}
