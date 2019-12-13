//
//  dates.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 22/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

open class cDates {
    var jj: Int!
    var mm: Int!
    var aa: Int!
    static var tblMois = ["1", "Janvier", "2", "Février", "3", "Mars", "4", "Avril", "5", "Mai", "6", "Juin", "7", "Juillet", "8", "Août", "9", "Septembre", "10", "Octobre", "11", "Novembre", "12", "Décembre"]
    static var tblMoisAbrege = ["1", "Jan ", "2", "Fév ", "3", "Mars", "4", "Avr ", "5", "Mai ", "6", "Juin", "7", "Juil", "8", "Août", "9", "Sept", "10", "Oct ", "11", "Nov ", "12", "Déc "]
    static var dictMois = ["1": "Janvier", "2": "Février", "3": "Mars", "4": "Avril", "5": "Mai", "6": "Juin", "7": "Juillet", "8": "Août", "9": "Septembre", "10": "Octobre", "11": "Novembre", "12": "Décembre"]
    static var dictMoisAbrege = ["1": "Jan ", "2": "Fév ", "3": "Mars", "4": "Avr", "5": "Mai ", "6": "Juin", "7": "Juil", "8": "Août", "9": "Sept", "10": "Oct ", "11": "Nov ", "12": "Déc "]
    
    init(_ dt: String) {
        if dt.contains("-") {
            let els = dt.components(separatedBy: "-")
            aa = Int(els[0])
            mm = Int(els[1])
            jj = Int(els[2])
        }
        else
            if dt.contains("/") {
                let els = dt.components(separatedBy: "/")
                jj = Int(els[0])
                mm = Int(els[1])
                aa = Int(els[2])
        }
    }
    
    init (jj: Int, mm: Int, aa: Int) {
        self.jj = jj
        self.mm = mm
        self.aa = aa
    }
    
    func toSQL () -> String {
        if (aa == nil || mm == nil || jj == nil) {
            return ""
        } else {
            return String(format: "%04d-%02d-%02d", aa, mm, jj)
        }
    }
    
    func toSsaisie () -> String {
        if jj != nil && mm != nil && aa != nil {
            return String(format: "%02d/%02d/%04d", jj, mm, aa)
        } else {
            return ""
        }
    }
    
    static func diffmois (dtdeb: String, dtfin: String) -> Int {
        let deb = cDates(dtdeb)
        let fin = cDates(dtfin)
        var res = 0
        while deb.aa < fin.aa {
            res = res + 12 - deb.mm
            deb.mm = 0
            deb.aa = deb.aa + 1
        }
        res = fin.mm - deb.mm
        return res
    }
    
    static func dateDuJour (_ sansTirets: Bool = false) -> String {
        let now = Date()
        let format = DateFormatter()
        format.dateFormat =  sansTirets ? "yyyyMMdd" : "yyyy-MM-dd"
        return format.string(from: now)
    }
    
    static func heureDuJour(_ sansTirets: Bool = false) -> String {
        let now = Date()
        let format = DateFormatter()
        format.dateFormat =  sansTirets ? "HHmmss" : "HH-mm-ss"
        return format.string(from: now)
    }
    
    static func moisDuJour() -> Int {
        return cDates(cDates.dateDuJour()).mm
    }
    
    static func anneeDuJour() ->Int {
        return cDates(cDates.dateDuJour()).aa
        
    }
    
    static func finmois(aa: Int, mm: Int) ->Int {
        switch(mm) {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31;
        case 4, 6, 9, 11:
            return 30;
        case 2:
            return aa % 400 == 0 || (aa % 100 != 0 && aa % 4 == 0) ? 29 : 28;
        default:
            return 0;
        }
    }
    
    func incrementerMois (nbmois: Int) {
        let estFinmois = jj == cDates.finmois(aa: aa, mm: mm)
        mm = mm + nbmois
        while mm > 12 {
            mm = 1
            aa = aa + 1
        }
        if estFinmois {
            jj = cDates.finmois(aa: aa, mm: mm)
        }
    }
    
    func decrementerMois (nbmois: Int) {
        let estFinmois = jj == cDates.finmois(aa: aa, mm: mm)
        mm = mm - nbmois
        while mm < 1 {
            mm = mm + 12
            aa = aa - 1
        }
        if estFinmois {
            jj = cDates.finmois(aa: aa, mm: mm)
        }
    }
}
