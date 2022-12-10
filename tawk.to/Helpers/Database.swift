//
//  Database.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import CoreData
import UIKit
import Combine

// Singleton CoreData Stack
class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "tawk_to")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

class Database {
    private let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    private let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

    static let shared = Database()

    @Published var usersList: [Users] = []

    private init() {
        let context = CoreDataStack.shared.persistentContainer.viewContext.persistentStoreCoordinator

        mainContext.persistentStoreCoordinator = context
        privateContext.persistentStoreCoordinator = context

        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func getLocalUsers(completion: @escaping (Result<[Users], Error>) -> Void) {
        mainContext.perform {
            guard NSEntityDescription.entity(forEntityName: "Users", in: self.privateContext) != nil else {
                completion(.failure(DatabaseError.invalidEntity))
                return
            }

            do {
                let sort = NSSortDescriptor(key: "id", ascending: true)
                let request = NSFetchRequest<Users>(entityName: "Users")
                request.sortDescriptors = [sort]

                let result = try self.privateContext.fetch(request)

                completion(.success(result))
            } catch {
                completion(.failure(DatabaseError.unableToRead))
            }
        }
    }

    func getLocalDetails(completion: @escaping (Result<[Details], Error>) -> Void) {
        mainContext.perform {
            guard NSEntityDescription.entity(forEntityName: "Details", in: self.privateContext) != nil else {
                completion(.failure(DatabaseError.invalidEntity))
                return
            }

            do {
                let request = NSFetchRequest<Details>(entityName: "Details")
                let result = try self.privateContext.fetch(request)

                completion(.success(result))
            } catch {
                completion(.failure(DatabaseError.unableToRead))
            }
        }
    }

    func saveUsers(_ data: Data, _ completion: @escaping (Result<[Users], Error>) -> Void) {
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.privateContext

        var users: [Users] = []

        do {
            users = try decoder.decode([Users].self, from: data)
        } catch let error {
            completion(.failure(error))
        }

        do {
            try self.privateContext.save()
            completion(.success(users))
        } catch {
            completion(.failure(DatabaseError.unableToWrite))
        }
    }

    func saveDetails(_ data: Data, _ completion: @escaping (Result<Details, Error>) -> Void) {
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.privateContext

        var details: Details

        do {
            details = try decoder.decode(Details.self, from: data)

            do {
                try self.privateContext.save()
                completion(.success(details))
            } catch {
                completion(.failure(DatabaseError.unableToWrite))
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    
    
    func getLastID(completion: @escaping (Result<Int, Error>) -> Void) {
        mainContext.perform {
            guard NSEntityDescription.entity(forEntityName: "Users", in: self.privateContext) != nil else {
                completion(.failure(DatabaseError.invalidEntity))
                return
            }

            do {
                let request = NSFetchRequest<Users>(entityName: "Users")
                let result = try self.privateContext.fetch(request)
                let max = result.map{ $0.id }.max()
                
                completion(.success(Int(max ?? 0)))
            } catch {
                completion(.failure(DatabaseError.unableToRead))
            }
        }
    }

    func isUsersEmpty() -> Bool {
        do {
            let request = NSFetchRequest<Users>(entityName: "Users")
            let count = try self.mainContext.count(for: request)

            return count == 0
        } catch {
            return true
        }
    }

    func saveNotes(id: Int64, notes: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        privateContext.perform {
            guard NSEntityDescription.entity(forEntityName: "Details", in: self.privateContext) != nil else {
                completion(.failure(DatabaseError.invalidEntity))
                return
            }

            do {
                let request = NSFetchRequest<Details>(entityName: "Details")
                request.predicate = NSPredicate(format: "id == %d", id)
                request.fetchLimit = 1

                let result = try self.privateContext.fetch(request)

                if let detail = result.first {
                    detail.setValue(notes, forKey: "notes")
                }

                do {
                    try self.privateContext.save()
                    completion(.success(true))
                } catch {
                    completion(.failure(DatabaseError.unableToWrite))
                }
            } catch {
                completion(.failure(DatabaseError.unableToRead))
            }
        }
    }
    
    func getDetails(id: String, completion: @escaping (Result<[Details], Error>) -> Void) {
        mainContext.perform {
            guard NSEntityDescription.entity(forEntityName: "Details", in: self.privateContext) != nil else {
                completion(.failure(DatabaseError.invalidEntity))
                return
            }

            do {
                let request = NSFetchRequest<Details>(entityName: "Details")
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1

                let result = try self.privateContext.fetch(request)

                completion(.success(result))
            } catch {
                completion(.failure(DatabaseError.unableToRead))
            }
        }
    }

    func detailsExistsForID(id: String) -> Bool {
        do {
            let request = NSFetchRequest<Details>(entityName: "Details")
            request.predicate = NSPredicate(format: "id == %@", id)
            let count = try self.mainContext.count(for: request)

            return count == 1
        } catch {
            return false
        }
    }
}
