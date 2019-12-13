//
//  datas.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 14/11/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Foundation

protocol DatasModelDelegate: class {
    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?)
    func onFetchFailed(with reason: String)
}

class DatasModel {
    weak var delegate: DatasModelDelegate?
    
    var adresse: String!
    var moderators: [NSDictionary] = []
    var currentPage = 1
    var total = 0
    var isFetchInProgress = false
    
    let client: StackExchangeClient!
    let request: BaseRequest
    
    init(adresse: String, request: BaseRequest, delegate: DatasModelDelegate) {
        self.adresse = adresse
        self.request = request
        self.client = StackExchangeClient(self.adresse)
        self.delegate = delegate
    }
    
    var totalCount: Int {
        return total
    }
    
    var currentCount: Int {
        return moderators.count
    }
    
    func moderator(at index: Int) -> NSDictionary {
        return moderators[index]
    }
    
    func fetchModerators() {
        guard !isFetchInProgress else {
            return
        }
        
        isFetchInProgress = true
        
        request.parameters["page"] = String(currentPage)
        client.fetch(request: request, completion: {
            res, dict in
            if !res {
                DispatchQueue.main.async {
                    self.isFetchInProgress = false
                    self.delegate?.onFetchFailed(with: "erreur")
                }
            } else {
                DispatchQueue.main.async {

                    self.currentPage += 1
                    self.isFetchInProgress = false
            
                    self.total = dict!["total"] as! Int
                    self.moderators.append(contentsOf: dict!["items"] as! [NSDictionary])
                    
                    if dict!["page"] as! Int > 1 {
                        let indexPathsToReload = self.calculateIndexPathsToReload(from: dict!["items"] as! [NSDictionary])
                        self.delegate?.onFetchCompleted(with: indexPathsToReload)
                    } else {
                        self.delegate?.onFetchCompleted(with: .none)
                    }
                }
            }
        })
    }
    
    func calculateIndexPathsToReload(from newModerators: [NSDictionary]) -> [IndexPath] {
        let startIndex = moderators.count - newModerators.count
        let endIndex = startIndex + newModerators.count
        return (startIndex..<endIndex).map { IndexPath(item: $0, section: 0) }
    }
    
}
