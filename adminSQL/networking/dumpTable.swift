//
//  dumpTable.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 20/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

class DumpTableRequest: BaseRequest {
    
    init(_ database: String, _ table: String, _ page: Int) {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "dumpTable", "database": database, "table": table, "page": String(page)]
        super.init(parameters: parameters)
    }
}

class DumpTableResponse: Decodable {
    var moderators: [DumpTableModel]
    let total: Int
    let hasMore: Int
    let page: Int
    
    enum CodingKeys: String, CodingKey {
        case moderators = "items"
        case hasMore = "has_more"
        case total
        case page
    }
}

struct FieldValeurs: Decodable {
    var fieldValue: Any?
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        fieldValue = try? container.decode(String.self)
        if fieldValue == nil {
            fieldValue = try? container.decode(Int.self)
            if fieldValue == nil {
                fieldValue = "null"
            }
        }
    }
}

fileprivate struct DummyCodable: Codable {}


class DumpTableModel: Decodable {
    let row: [Any?]
    
    init(row: [Any]) {
        self.row  = row
    }
    
    init() {
        self.row  = [Any]()
    }
    
    enum CodingKeys: String, CodingKey {
        case row
    }
    
    
    required convenience init(from decoder: Decoder) throws {
        //var container = try decoder.container(keyedBy: CodingKeys.self)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var container = try values.nestedUnkeyedContainer(forKey: .row)
        var row = [Any]()
        if let count = container.count {
            row.reserveCapacity(count)
        }
        while !container.isAtEnd {
            if let element = try? container.decode(String.self) {
                row.append(element)
            } else {
                _ = try container.decode(DummyCodable.self)
                row.append("NULL")
            }
        }
        self.init(row: row)
        //self.init()
    }
    
    func fetch(_ database: String, _ table: String, _ page: Int, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient()
        let request = DumpTableRequest(database, table, page)
        
        client.fetch(request: request, dataResponse: DumpTableResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetch(_ adresse: String, _ database: String, _ table: String, _ page: Int, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = DumpTableRequest(database, table, page)
        
        client.fetch(request: request, dataResponse: DumpTableResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
}
