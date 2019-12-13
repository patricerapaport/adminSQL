//
//  AppDelegate.swift
//  adminSQL
//
//  Created by Patrice Rapaport on 17/10/2019.
//  Copyright © 2019 Patrice Rapaport. All rights reserved.
//

import Cocoa

var myApp: NSApplication!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var dbSelected: String!
    var servers: [Server]!
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "adminSQL")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    static var persistentContainer: NSPersistentContainer {
        return (NSApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
test().showWindow(self)
return;
        myApp = aNotification.object as? NSApplication
        //let managedObjectContext = persistentContainer
        
        let request: NSFetchRequest<Server> = Server.fetchRequest()
        servers = try? AppDelegate.viewContext.fetch(request)
if false && servers != nil && servers.count > 0 {
        AppDelegate.viewContext.delete(servers[0])
        try? AppDelegate.viewContext.save()
}
        if (servers == nil || servers.count == 0){
            myApp.runModal(for: serversWindow().window!)
            //Swift.print("Création \(managedObjectContext)")
            //let server = Server(context: AppDelegate.viewContext)
            //server.nom = "local"
            //try? AppDelegate.viewContext.save()
            return
        }
        mainController().showWindow(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func gestionnaireBDD(_ sender: Any) {
        mainController().showWindow(self)
    }
    
    @IBAction func open(_ sender: Any) {
        let wc = explorer()
        wc.showWindow(self)
    }
}

