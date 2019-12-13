//
//  stackExchangeClient.swift
//  ivritBigdata
//
//  Created by Patrice Rapaport on 16/06/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

//import Foundation
import AppKit
import Alamofire

final class StackExchangeClient {
    var urlString = URL(string: "http://127.0.0.1/adminSQL/websvce/server.php")
    //var urlString = URL(string: "http://hebrew.rapaport.fr/websvce/server.php")
    private lazy var baseURL: URL = {
        return URL(string: "http://127.0.0.1/adminSQL/websvce/server.php")!
    }()
    
    init (_ adresse: String) {
        urlString = URL(string: "http://" + adresse)
    }
    
    init() {
        
    }
    
    func fetch<T>(request: BaseRequest, dataResponse: T.Type, completion: @escaping (Result<Decodable, DataResponseError>) -> Void) where T: Decodable {
        let params = request.parameters!
        Alamofire.request(urlString!, method: .post, parameters: params, encoding: JSONEncoding.default)
            .responseJSON {
                response in
                switch response.result {
                case .success (_):
                    let data = response.data
                    guard let decodedResponse = try? JSONDecoder().decode(dataResponse, from: data! ) else {
                        if let jsonResult = ((try? JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary) as NSDictionary??)    {
                            Swift.print("Pour \(String(describing: request.parameters)) \((jsonResult)!)")
                            Swift.print(String(data: data!, encoding: String.Encoding.utf8)!)
                        }
                        completion(Result.failure(DataResponseError.decoding))
                        return
                    }
                    completion(Result.success(decodedResponse))
                case .failure(_):
                    if let jsonResult = ((try? JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary) as NSDictionary??)    {
                        Swift.print(jsonResult!)
                    }
                    completion(Result.failure(DataResponseError.network))
                }
        }
    }
    
    func fetch(request: BaseRequest, completion: @escaping (Bool, NSDictionary?) -> Void) {
        let params = request.parameters!
        Alamofire.request(urlString!, method: .post, parameters: params, encoding: JSONEncoding.default)
            .responseJSON {
                response in
                switch response.result {
                case .success (let JSON):
                    let data = JSON as! NSDictionary
                    completion(true, data)
                case .failure(_):
                    if let jsonResult = ((try? JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary) as NSDictionary??)    {
                        Swift.print(jsonResult!)
                    }
                    completion(false, nil)
                }
        }
    }
    
    func send (parameters: Parameters, completion: @escaping (Bool) -> Void) {
        Alamofire.request(urlString!, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON {
                response in
                switch response.result {
                case .success (_):
                    let data = response.data
                    guard let decodedResponse = try? JSONDecoder().decode(VerifResponse.self, from: data! ) else {
                        if let jsonResult = ((try? JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary) as NSDictionary??)    {
                            Swift.print((jsonResult)!)
                        }
                        completion(false)
                        return
                    }
                    if decodedResponse.result == "KO" {
                        _ = messageBox(decodedResponse.msg!, withOK: true).runModal()
                        completion(false)
                    } else {
                        completion(true)
                    }
                case .failure(_):
                    completion(false)
                }
        }
    }
    
    func verif(controller: NSViewController, params: Parameters, completion: @escaping (Bool) -> Void) {
        Alamofire.request(urlString!, method: .post, parameters: params, encoding: JSONEncoding.default)
            .responseJSON {
                response in
                switch response.result {
                case .success (_):
                    let data = response.data
                    guard let decodedResponse = try? JSONDecoder().decode(VerifResponse.self, from: data! ) else {
                        completion(false)
                        return
                    }
                    if decodedResponse.result == "KO" {
                        _ = messageBox(decodedResponse.msg!, withOK: true).runModal()
                        completion(false)
                    } else {
                        completion(true)
                    }
                case .failure(_):
                    completion(false)
                }
        }
    }
    
}
