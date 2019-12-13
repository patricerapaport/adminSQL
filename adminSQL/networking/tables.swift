//
//  tables.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 17/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

class TablesRequest: BaseRequest {
    
    init(_ database: String) {
        let parameters =  ["cmd": "cmd", "nomtable": "databases", "method": "showtables", "database": database]
        super.init(parameters: parameters)
    }
}

class TablesResponse: Decodable {
    var moderators: [TablesModel]
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

class TablesNbenregResponse: Decodable {
    var nbenreg: Int
    enum CodingKeys: String, CodingKey {
        case nbenreg = "total"
    }
}

class TablesModel: Decodable {
    var adresse: String!
    var dbname: String!
    let tblname: String
    var nbenreg: Int!
    var fields: [FieldsModel]!
    var indexes: [IndexesModel]!
    var data: [NSDictionary]!
    var nbfields: Int!
    var totalEnreg: Int!
    var currentPage: Int!
    var indexPage: Int = 0
    var limit: Int!
    var nbPagesInMemory: Int!
    var fetchingData: Bool = false
    
    var _tableView: NSTableView!
    var _rows: [NSDictionary]!
    var _firstRow: Int = 0
    var _amountToFetch: Int!
    
    init(tblname: String) {
        self.dbname = ""
        self.tblname = tblname
        self.nbenreg = 0
        self.nbfields = 0
        self.fields = [FieldsModel]()
        self.indexes = [IndexesModel]()
    }
    
    init() {
        self.dbname = ""
        self.tblname = ""
        self.nbenreg = 0
        self.nbfields = 0
        self.fields = [FieldsModel]()
        self.indexes = [IndexesModel]()
    }
    
    deinit {
        if data != nil {
            data.removeAll()
            data = nil
        }
        if fields != nil {
            fields.removeAll()
            fields = nil
            
        }
        if indexes != nil {
            indexes.removeAll()
            indexes = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case tblname
    }
    
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tblname = try container.decoder(String.self, forKey: .tblname)
        self.init(tblname: tblname)
    }
    
    func fetch(_ adresse: String, _ database: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = TablesRequest(database)
        
        client.fetch(request: request, dataResponse: TablesResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                completion(result)
            }
        })
    }
    
    func fetchNbenreg(_ adresse: String, _ nomdatabase: String, _ nomtable: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = DatabasesRequest()
        request.addParameters(["database": nomdatabase, "table": nomtable])
        request.parameters["method"] = "nbenreg"
        client.fetch(request: request, dataResponse: TablesNbenregResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response) :
                    self.nbenreg = (response as! TablesNbenregResponse).nbenreg
                    completion(result)
                case .failure(_):
                    completion(result)
                }
            }
        })
    }
    
    func fetchNbfields(_ adresse: String, _ nomdatabase: String, _ nomtable: String, _ completion: @escaping(Result<Decodable, DataResponseError>) -> Void) {
        let client = StackExchangeClient(adresse)
        let request = DatabasesRequest()
        request.addParameters(["database": nomdatabase, "table": nomtable, "count": "1", "nointures": "1"])
        request.parameters["method"] = "showFields"
        client.fetch(request: request, dataResponse: TablesNbenregResponse.self, completion: {
            result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response) :
                    self.nbfields = (response as! TablesNbenregResponse).nbenreg
                    completion(result)
                case .failure(_):
                    completion(result)
                }
            }
        })
    }
    
}

// MARK gestion de l'affichage
extension TablesModel {
    // On doit toujours avec 3 pages en mémoire
    func pageDemandee (_ index: Int) -> Int {
        let iRes = (index+1) / limit
        if (index+1) % limit != 0 {
            return iRes + 1
        } else{
            return iRes
        }
    }
    
    func lastPageEnMemoire() -> Int {
        return currentPage-1+data.count/limit
    }
}

// MARK: tetstDatasource
extension TablesModel {
    func destroyPageData(_ index: Int) {
        data.removeSubrange(index..<index+min(limit, data.count))
    }
    
    func rowLoaded (_ row: Int) -> Bool {
        return row >= indexPage && row < indexPage + data.count
    }
    
    func fetch(_ tableview: NSTableView, _ row: Int, completion: @escaping (Bool) -> Void) {
Swift.print("ca tourne pour row=\(row)")
        if !fetchingData /*|| !rowLoaded(row)*/ {
            fetchingData = true
            // 1 calculate what part of the array has to be destroyed
            if row < indexPage {
                destroyPageData((nbPagesInMemory-1)*limit)
            } else {
               destroyPageData(0)
                self.indexPage += limit
            }
            
            // 2 Fetch data if necessary
            
            TableModel().fetchData(adresse, dbname, tblname, limit,  currentPage+nbPagesInMemory, {
                res, dict in
                self.currentPage += (dict!["items"] as! [NSDictionary]).count / self.limit
                if row < self.indexPage {
                    self.data.insert(contentsOf: dict!["items"] as! [NSDictionary], at: 0)
                    //self.indexPage = row
                } else {
                    self.data.insert(contentsOf:dict!["items"] as! [NSDictionary], at: self.data.count)
                }

                // 3 reload rows
                let rows = NSIndexSet(indexesIn: NSMakeRange(row, self.indexPage+self.data.count-1)) as IndexSet
                let cols = NSIndexSet( indexesIn: NSMakeRange(0, tableview.numberOfColumns)) as IndexSet
                DispatchQueue.main.async {
                    self.fetchingData = false
                    tableview.reloadData(forRowIndexes: rows, columnIndexes: cols)
                }
                completion(res)
            })
        } else {
            completion(false)
        }
    }
    
    func initialFetch (_ tableview: NSTableView, _ adresse: String, completion: @escaping (Bool) -> Void) {
        self.adresse = adresse
        TableModel().fetchData(adresse, dbname, tblname, nbPagesInMemory*limit, 0,  {
            res, dict in
            if res {
                self.totalEnreg = dict!["total"] as? Int
                self.currentPage = 1
                self.data = dict!["items"] as? [NSDictionary]
                DispatchQueue.main.async {
                    tableview.reloadData()
                }
            }
            completion(res)
        })
    }
}
