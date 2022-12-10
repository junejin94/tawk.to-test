//
//  CoreDataStore.swift
//  tawk.toTests
//
//  Created by Phua June Jin on 11/12/2022.
//

import Foundation
import CoreData

class CoreDataStore {
    static let shared = CoreDataStore()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "tawk_to")
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}
