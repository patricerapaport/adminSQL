//
//  iconsAwesome.swift
//  essaiIntegre
//
//  Created by Patrice Rapaport on 28/10/2018.
//  Copyright © 2018 Patrice Rapaport. All rights reserved.
//

import Foundation

let fa_check = 0xF00C
let fa_lock  = 0xF023
let fa_first = 0xF100
let fa_last  = 0xF101
let fa_previous = 0xF104
let fa_next  = 0xF105
let fa_doc   = 0xF016
let fa_docs  = 0xF0C5

struct cAwesome {
    static func String (_ aIcon: Int) -> String {
        switch aIcon {
        case fa_check : return "check"
        case fa_lock: return "lock"
        case fa_first: return "first"
        case fa_last: return "last"
        case fa_previous: return "previous"
        case fa_next: return "next"
        case fa_doc: return "doc"
        case fa_docs: return "docs"
        default: return ""
        }
    }
    
    static func icon (_ aString: String) -> Int {
        switch aString.lowercased() {
        case "check" : return fa_check
        case "lock": return fa_lock
        case "first": return fa_first
        case "last": return fa_last
        case "previous": return fa_previous
        case "next": return fa_next
        case "doc": return fa_doc
        case "docs": return fa_docs
        default: return 0
        }
    }
}

