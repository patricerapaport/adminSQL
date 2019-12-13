//
//  strings.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 21/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

extension String {
    public func toFloat() -> Float {
        if self.count == 0 {
            return 0
        }
        else {
            return (self as NSString).floatValue
        }
    }
    
    public func toDouble() -> Double {
        if self.count == 0 {
            return 0.0
        }
        else {
            return (self as NSString).doubleValue
        }
    }
    
    public func toInt() -> Int {
        if self.count == 0 {
            return 0
        }
        else {
            return Int((self as NSString).intValue)
        }
    }
    
    public func toMonetaire(_ withCurrency: Bool = false) -> String {
        let valeur = toFloat() as NSNumber
        if valeur == 0 {
            return ""
        } else {
            let format = NumberFormatter()
            format.numberStyle = NumberFormatter.Style.currency
            format.locale = NSLocale(localeIdentifier: "fr_FR") as Locale
            format.usesGroupingSeparator = true
            format.groupingSeparator = " "
            format.decimalSeparator = "."
            format.minimumFractionDigits = 2
            format.maximumFractionDigits = 2
            format.currencySymbol = "€"
            
            let res =  format.string(from: valeur)!
            return res
        }
    }
    
    func charAt(_ nIndex: Int) -> String {
        return self.substr(nIndex, nIndex)
    }
    
    func setChar(_ char: String, _ nIndex: Int) -> String {
        var szRes = ""
        if nIndex > 0 {
            szRes = self.substr(0, nIndex-1)
        }
        szRes += char
        if nIndex < self.count-1 {
            szRes += self.substr(nIndex+1, nil)
        }
        return szRes
    }
    
    public func substr(_ from: Int, _ to: Int!) -> String {
        var index = self.index(self.startIndex, offsetBy: from)
        var res = String(self[index...])
        if to != nil {
            let to1 = 1 + to - from
            if to1 > res.count {
                return res
            }
            index = res.index(self.startIndex, offsetBy: to1);
            res = String(res[..<index])
        }
        return res
    }
    
    public func substring (_ first: Int, _ len: Int) -> String {
        let ixFirst = self.index(self.startIndex, offsetBy: first-1)
        let ixLast = self.index(ixFirst, offsetBy:len-1)
        return String(self[ixFirst...ixLast])
    }
    
    public func substring(_ first: Int) -> String {
        return substring(first, self.count-first+1)
    }
    
    public func caractere(_ first: Int) -> String {
        return substring(first, 1)
    }
}
