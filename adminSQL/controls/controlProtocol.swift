//
//  controlProtocol.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 30/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa
protocol controlProtocol: class {
    var parent: parentWC? { get set}
    func verifControl() -> String?
}
