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

/// Singleton for CoreData Stack.
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

    /// The container should only be used for testing purposes only, as it's only in-memory
    lazy var persistentContainerTest: NSPersistentContainer = {
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

/**
 Singleton to access CoreData-related operation.

 There's two singleton to access,
 - shared: Normal operation, save to disk
 - sharedTest: In-memory operation, for testing purposes only
 */
class Database {
    static let shared = Database(context: CoreDataStack.shared.persistentContainer.viewContext.persistentStoreCoordinator)
    static let sharedTest = Database(context: CoreDataStack.shared.persistentContainerTest.viewContext.persistentStoreCoordinator)

    private var mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    private var privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

    private init(context: NSPersistentStoreCoordinator?) {
        mainContext.persistentStoreCoordinator = context
        privateContext.persistentStoreCoordinator = context

        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        mainContext.automaticallyMergesChangesFromParent = true
        privateContext.automaticallyMergesChangesFromParent = true
    }

///The method "withCheckedThrowingContinuation" is used to bridge between Closures and Concurrency since "perform" haven't been backported yet.
// MARK: - Functions (Get)
    /**
     Get a list of all users from disk if exists.

     - Parameters:
        - id: A user ID. Only return users with an ID greater than this ID

     - Returns: A list of users.
     */
    func getUsersSince(id: Int64) async throws -> [Users] {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Users", in: self.mainContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let request = NSFetchRequest<Users>(entityName: "Users")
                    request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                    request.predicate = NSPredicate(format: "id > %d", id)

                    let users = try self.mainContext.fetch(request)

                    continuation.resume(returning: users)
                } catch {
                    continuation.resume(throwing: DatabaseError.unableToRead)
                }
            }
        }
    }

    /**
     Get a list of all users details from disk if exists.

     - Parameters:
        - id: A user ID. Only return users with an ID greater than this ID

     - Returns: A list of users detail.
     */
    func getDetailsSince(id: Int64) async throws -> [Details] {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Details", in: self.mainContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let request = NSFetchRequest<Details>(entityName: "Details")
                    request.predicate = NSPredicate(format: "id > %d", id)

                    let details = try self.mainContext.fetch(request)

                    continuation.resume(returning: details)
                } catch {
                    continuation.resume(throwing: DatabaseError.unableToRead)
                }
            }
        }
    }

    /**
     Get detail of a single user from disk if exists.

     - Parameters:
        - id: The user ID.

     - Returns: details regarding the users.
     */
    func getDetailsFor(id: Int64) async throws -> Details {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Details", in: self.mainContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let request = NSFetchRequest<Details>(entityName: "Details")
                    request.predicate = NSPredicate(format: "id == %d", id)
                    request.fetchLimit = 1

                    let fetched = try self.mainContext.fetch(request)

                    if let existing = fetched.first {
                        return continuation.resume(returning: existing)
                    }

                    throw UserError.emptyDetail(id: id)
                } catch let error {
                    return continuation.resume(throwing: error)
                }
            }
        }
    }

    /**
     Get seen status of a single user

     - Parameters:
        - id: The user ID

     - Returns: seens status of a single user.
     */
    func getSeenFor(id: Int64) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Users", in: self.mainContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let request = NSFetchRequest<Users>(entityName: "Users")
                    request.predicate = NSPredicate(format: "id == %d", id)
                    request.fetchLimit = 1

                    let fetched = try self.mainContext.fetch(request)

                    if let existing = fetched.first {
                        return continuation.resume(returning: existing.seen)
                    }

                    throw UserError.emptyDetail(id: id)
                } catch let error {
                    return continuation.resume(throwing: error)
                }
            }
        }
    }

// MARK: - Functions (Save)
    /**
     Save or updates a list of users into the disk.

     - Parameters:
        - data: raw JSON response

     - Returns: A list of users.
     */
    func saveUsers(data: Data) async throws -> [Users] {
        return try await withCheckedThrowingContinuation { continuation in
            privateContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Users", in: self.privateContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    var list: Array<Users> = []
                    let users = try JSONDecoder().decode([UsersCodable].self, from: data)

                    for user in users {
                        let request = NSFetchRequest<Users>(entityName: "Users")
                        request.predicate = NSPredicate(format: "id == %d", user.id)
                        request.fetchLimit = 1

                        let fetched = try self.privateContext.fetch(request)

                        if let existing = fetched.first {
                            existing.map(model: user)
                            list.append(existing)
                        } else {
                            let new = Users.init(context: self.privateContext)
                            new.map(model: user)
                            list.append(new)
                        }
                    }

                    try self.privateContext.save()

                    continuation.resume(returning: list)
                } catch let error {
                    print(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /**
     Save or updates the details of a single user into the disk.

     - Parameters:
        - data: raw JSON response

     - Returns: Details regarding the users.
     */
    func saveDetails(data: Data) async throws -> Details {
        return try await withCheckedThrowingContinuation { continuation in
            privateContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Details", in: self.privateContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let detail = try JSONDecoder().decode(DetailsCodable.self, from: data)

                    let request = NSFetchRequest<Details>(entityName: "Details")
                    request.predicate = NSPredicate(format: "id == %d", detail.id)
                    request.fetchLimit = 1

                    let result = try self.privateContext.fetch(request)

                    if let existing = result.first {
                        existing.map(model: detail)

                        try self.privateContext.save()

                        continuation.resume(returning: existing)
                    } else {
                        let new = Details.init(context: self.privateContext)
                        new.map(model: detail)

                        try self.privateContext.save()

                        continuation.resume(returning: new)
                    }
                } catch let error {
                    print(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /**
     Save notes regarding a single user into the disk.

     - Parameters:
        - id: The user ID
        - notes: text about the users

     - Returns: The status of save attempt to disk.
     */
    func saveNotes(id: Int64, notes: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            privateContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Users", in: self.privateContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let request = NSFetchRequest<Users>(entityName: "Users")
                    request.predicate = NSPredicate(format: "id == %d", id)
                    request.fetchLimit = 1

                    let result = try self.privateContext.fetch(request)

                    if let detail = result.first {
                        detail.setValue(notes, forKey: "notes")
                    }

                    try self.privateContext.save()

                    continuation.resume(returning: true)
                } catch let error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

// MARK: - Functions (Update)
    /**
     Update seen status of a single user into the disk.

     - Parameters:
        - id: The user ID

     - Returns: The status of save attempt to disk.
     */
    func updateSeen(id: Int64) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            privateContext.perform {
                guard NSEntityDescription.entity(forEntityName: "Users", in: self.privateContext) != nil else {
                    return continuation.resume(throwing: DatabaseError.invalidEntity)
                }

                do {
                    let request = NSFetchRequest<Users>(entityName: "Users")
                    request.predicate = NSPredicate(format: "id == %d", id)
                    request.fetchLimit = 1

                    let result = try self.privateContext.fetch(request)

                    if let detail = result.first {
                        detail.seen = true
                    }

                    try self.privateContext.save()

                    continuation.resume(returning: true)
                } catch let error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

// MARK: - Functions (Helpers)
    /**
     Check whether there's previously saved data in disk.

     - Returns: The status whether there's existing user data in the disk.
     */
    func isEmpty() async -> Bool {
        return await withCheckedContinuation { continuation in
            self.mainContext.perform {
                do {
                    let request = NSFetchRequest<Users>(entityName: "Users")
                    let count = try self.mainContext.count(for: request)

                    return continuation.resume(returning: count == 0)
                } catch {
                    return continuation.resume(returning: true)
                }
            }
        }
    }
}
