//
//  decodable.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 17/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func decoder (_ type: String.Type, forKey key: KeyedDecodingContainer<K>.Key, defaut : String = "") throws  -> String  {
        let szRes = try? self.decode(String.self, forKey: key)
        return szRes == nil ? defaut : szRes!
    }
    
    func decoder(_ type: [String].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [String] {
        let tabl = try? self.decode([String].self, forKey: key)
        return tabl == nil ? [] : tabl!
    }
    
}
