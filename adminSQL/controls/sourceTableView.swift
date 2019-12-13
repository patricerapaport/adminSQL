//
//  sourceTableView.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 19/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

protocol CDatasource: NSTableViewDataSource {
    var table: NSTableView {get set}
    var rows: [NSDictionary] {get set}
    var firstRow: Int {get set}
    var totalCount: Int {get set}
    var amountToFetch: Int {get set}
    func getRows(_ nRow: Int)
    func fetch (_ nRow: Int)
}
