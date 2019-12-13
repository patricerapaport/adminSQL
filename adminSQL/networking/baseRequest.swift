//
//  baseRequest.swift
//  ivritBigdata
//
//  Created by Patrice Rapaport on 17/06/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

typealias Parameters = [String: String]

enum Result<T, U: Error> {
    case success(T)
    case failure(U)
}

enum DataResponseError: Error {
    case network
    case decoding
    
    var reason: String {
        switch self {
        case .network:
            return "An error occurred while fetching data "
        case .decoding:
            return "An error occurred while decoding data"
        }
    }
}

class VerifResponse: Decodable {
    let result: String
    let msg: String?
    let reponse: String?
    
    
    enum CodingKeys: String, CodingKey {
        case result
        case msg
        case reponse
    }
}

class BaseRequest {
    
    var parameters: Parameters!
    
    func addParameters(_ params: Parameters) {
        for (key, value) in params {
            parameters[key] = value
        }
    }
    
    func removeParameter(_ key: String) {
        if parameters.keys.contains(key) {
            parameters.removeValue(forKey: key)
        }
    }
    
    func removeParameters(_ keys: [String]) {
        for key in keys {
            removeParameter(key)
        }
    }
    
    init(parameters: Parameters) {
        self.parameters = parameters
    }
}

