//
//  Server+CoreDataProperties.swift
//  
//
//  Created by Patrice Rapaport on 13/12/2019.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Server {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Server> {
        return NSFetchRequest<Server>(entityName: "Server")
    }

    @NSManaged public var adresse: String?
    @NSManaged public var login: String?
    @NSManaged public var nom: String?
    @NSManaged public var pwd: String?
    @NSManaged public var serverBDD: String?

}
